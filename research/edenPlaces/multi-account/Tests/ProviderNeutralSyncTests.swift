import Foundation
import XCTest
@testable import ProfileCore

final class FakeCloud: PlacesSafeProvider {
    var providerType: PlacesProvider
    var folders: [String:[String:Data]] = [:]
    var calls: [String] = []
    var directories: [String:[String]] = [:]
    var failUploads=false
    var mutateOnDownload=false
    init(_ provider: PlacesProvider){self.providerType=provider}
    func snapshot(folder: String) throws -> [PlacesRemoteBlob] {
        calls.append("list:\(folder)")
        return try (folders[folder] ?? [:]).map { name,data in
            let u=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at:u) }
            try data.write(to:u)
            return PlacesRemoteBlob(name:name,sha256:try PlacesFileDigest.sha256(u),bytes:Int64(data.count))
        }
    }
    func subfolders(folder:String) throws -> [String] { calls.append("dirs:\(folder)");return directories[folder] ?? [] }
    func download(folder: String,name: String, into stagingFile: URL) throws {
        calls.append("download:\(name)")
        guard let d=folders[folder]?[name] else {throw PlacesTransferFailure.changedDuringTransfer}
        try d.write(to:stagingFile)
        if mutateOnDownload {folders[folder]?[name]=Data("changed during download".utf8)}
    }
    func createOnly(folder: String,name: String,from local: URL) throws {
        calls.append("upload:\(name)")
        if failUploads || folders[folder]?[name] != nil { throw PlacesTransferFailure.conflictingExistingFile }
        folders[folder,default:[:]][name] = try Data(contentsOf:local)
    }
}

final class ProviderNeutralSyncTests: XCTestCase {
    func setup(_ provider:PlacesProvider = .dropbox,
               mode:PlacesFolderPermission.Mode = .sync) throws -> (PlacesSyncProfile, URL,FakeCloud) {
        let root=FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("edenplaces-isolated-test-"+UUID().uuidString,isDirectory:true)
        let p=PlacesSyncProfile(provider:provider,remoteSource:"managed",remoteName:"test_1",label:"Sandbox",
                                localRoot:root.path,folderGrants:[try PlacesFolderPermission("Photos",mode:mode)])
        return (p,root,FakeCloud(provider))
    }
    func coordinator(_ remote:FakeCloud, authorized:@escaping (PlacesSyncProfile,PlacesFolderPermission)throws->Bool = {_,_ in true},
                     current:@escaping (PlacesSyncProfile,PlacesFolderPermission)throws->Bool = {_,_ in true}) -> PlacesSafeSyncCoordinator {
        PlacesSafeSyncCoordinator(provider:remote,authorized:authorized,stillCurrent:current,save:{ _ in })
    }
    func local(_ root: URL, _ name:String, _ content:String) throws {
        let directory=root.appendingPathComponent("Photos")
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try Data(content.utf8).write(to:directory.appendingPathComponent(name))
    }
    func testDownloadsRemoteOnlyWithoutOverwrite() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["cloud.txt":Data("remote".utf8)]
        var ledger=PlacesTransferLedger()
        let report=try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(report.downloads,1)
        XCTAssertEqual(try String(contentsOf:root.appendingPathComponent("Photos/cloud.txt"),encoding:.utf8),"remote")
        XCTAssertTrue(remote.calls.contains("download:cloud.txt"))
    }
    func testUploadsLocalOnlyAndVerifiesRemote() throws {
        let (p,root,remote)=try setup(.googleDrive);defer {try? FileManager.default.removeItem(at:root)}
        try local(root,"local.txt","local")
        var ledger=PlacesTransferLedger()
        let result=try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(result.uploads,1)
        XCTAssertEqual(remote.folders["Photos"]?["local.txt"],Data("local".utf8))
    }
    func testOneDriveAndBoxMultipleAccountIndependent() throws {
        for provider in [PlacesProvider.oneDrive,.box,.webDAV,.s3,.cloudflareR2] {
            let (p,root,remote)=try setup(provider);defer {try? FileManager.default.removeItem(at:root)}
            try local(root,"new.txt","hello")
            var ledger=PlacesTransferLedger()
            XCTAssertEqual(try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false).uploads,1)
            XCTAssertEqual(remote.folders["Photos"]?["new.txt"],Data("hello".utf8))
        }
    }
    func testConflictsPreserveBothVersions() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        try local(root,"same.txt","local")
        remote.folders["Photos"]=["same.txt":Data("remote".utf8)]
        var ledger=PlacesTransferLedger()
        let res=try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(res.conflicts,1);XCTAssertEqual(res.uploads,0);XCTAssertEqual(res.downloads,0)
        XCTAssertEqual(try String(contentsOf:root.appendingPathComponent("Photos/same.txt"),encoding:.utf8),"local")
        XCTAssertEqual(remote.folders["Photos"]?["same.txt"],Data("remote".utf8))
    }
    func testTrackedDeletionNotResurrected() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["gone.txt":Data("old".utf8)]
        var ledger=PlacesTransferLedger()
        let coord=coordinator(remote)
        XCTAssertEqual(try coord.execute(profile:p,ledger:&ledger,dryRun:false).downloads,1)
        try FileManager.default.removeItem(at:root.appendingPathComponent("Photos/gone.txt"))
        let next=try coord.execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(next.conflicts,1);XCTAssertEqual(next.downloads,0)
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent("Photos/gone.txt").path))
    }
    func testPreviewDoesNotCreateFoldersOrTransfer() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["x.txt":Data("x".utf8)]
        var ledger=PlacesTransferLedger()
        let res=try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:true)
        XCTAssertEqual(res.downloads,1);XCTAssertFalse(FileManager.default.fileExists(atPath:root.path))
        XCTAssertFalse(remote.calls.contains(where:{$0.hasPrefix("download:")||$0.hasPrefix("upload:")}))
        XCTAssertTrue(ledger.previouslySeen.isEmpty)
    }
    func testRevokedBeforeTransferFailsClosed() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["x.txt":Data("x".utf8)]
        var n=0;var ledger=PlacesTransferLedger()
        let coordinator=coordinator(remote,current:{_,_ in n+=1;return n<3})
        XCTAssertThrowsError(try coordinator.execute(profile:p,ledger:&ledger,dryRun:false))
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent("Photos/x.txt").path))
    }
    func testChangedRemoteDuringDownloadBlocked() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["x.txt":Data("original".utf8)];remote.mutateOnDownload=true
        var ledger=PlacesTransferLedger()
        XCTAssertThrowsError(try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false))
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent("Photos/x.txt").path))
    }
    func testCloudCreateOnlyFailureNeverOverwrites() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        try local(root,"x.txt","local");remote.failUploads=true
        var ledger=PlacesTransferLedger()
        XCTAssertThrowsError(try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false))
        XCTAssertNil(remote.folders["Photos"]?["x.txt"])
    }
    func testUnsupportedProviderTypeRejectedBeforeFileIO() throws {
        let (p,root,remote)=try setup(.googleDrive);defer {try? FileManager.default.removeItem(at:root)}
        remote.providerType = .dropbox
        var ledger=PlacesTransferLedger()
        XCTAssertThrowsError(try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false))
        XCTAssertTrue(remote.calls.isEmpty)
    }
    func testDuplicateCaseFileNamesRejected() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["Photo.JPG":Data("a".utf8),"photo.jpg":Data("b".utf8)]
        var ledger=PlacesTransferLedger()
        XCTAssertThrowsError(try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false))
    }
    func testUnsafeRemoteNameFailsClosed() throws {
        let (p,root,remote)=try setup();defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["../escape":Data("x".utf8)]
        var ledger=PlacesTransferLedger()
        XCTAssertThrowsError(try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false))
    }
    func testFolderOffIsNotScanned() throws {
        let (p,root,remote)=try setup(.box,mode:.off);defer {try? FileManager.default.removeItem(at:root)}
        remote.folders["Photos"]=["x.txt":Data("x".utf8)]
        var ledger=PlacesTransferLedger()
        let res=try coordinator(remote).execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(res.downloads,0);XCTAssertTrue(remote.calls.isEmpty)
    }
}

extension ProviderNeutralSyncTests {
    func testExplicitRecursiveGrantIncludesOnlyApprovedDescendants() throws {
        var (p,root,cloud)=try setup(.googleDrive)
        defer {try? FileManager.default.removeItem(at:root)}
        p.folderGrants=[try PlacesFolderPermission("Photos",mode:.sync,recursive:true)]
        cloud.directories["Photos"]=["2026"]
        cloud.directories["Photos/2026"]=["January"]
        cloud.folders["Photos/2026/January"]=["sample.txt":Data("in folder".utf8)]
        var ledger=PlacesTransferLedger()
        let result=try coordinator(cloud).execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(result.downloads,1)
        XCTAssertEqual(try String(contentsOf:root.appendingPathComponent("Photos/2026/January/sample.txt"),encoding:.utf8),"in folder")
        XCTAssertFalse(cloud.calls.contains("list:Other"))
    }
    func testNonRecursiveGrantDoesNotScanSubfolders() throws {
        let (p,root,cloud)=try setup()
        defer {try? FileManager.default.removeItem(at:root)}
        cloud.directories["Photos"]=["2026"]
        cloud.folders["Photos/2026"]=["secret.txt":Data("secret".utf8)]
        var ledger=PlacesTransferLedger()
        let res=try coordinator(cloud).execute(profile:p,ledger:&ledger,dryRun:false)
        XCTAssertEqual(res.downloads,0)
        XCTAssertFalse(cloud.calls.contains("dirs:Photos"))
        XCTAssertFalse(cloud.calls.contains("list:Photos/2026"))
    }
    func testRecursiveTraversalRejectsInvalidProviderDirectoryName() throws {
        var (p,root,cloud)=try setup()
        defer {try? FileManager.default.removeItem(at:root)}
        p.folderGrants=[try PlacesFolderPermission("Photos",mode:.sync,recursive:true)]
        cloud.directories["Photos"]=["../other"]
        var ledger=PlacesTransferLedger()
        XCTAssertThrowsError(try coordinator(cloud).execute(profile:p,ledger:&ledger,dryRun:false))
    }
    func testRecursionDefaultsOffForOldRegistryEncoding() throws {
        let oldJSON=#"{"path":"Photos","mode":"sync"}"#
        let g=try JSONDecoder().decode(PlacesFolderPermission.self,from:Data(oldJSON.utf8))
        XCTAssertFalse(g.recursive)
    }
}