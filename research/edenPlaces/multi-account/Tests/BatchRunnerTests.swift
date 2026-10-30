import Foundation
import XCTest
@testable import ProfileCore

final class BatchRunnerTests:XCTestCase {
    func testTwoSeparateAutomaticProviderAccountsRunWithoutSharedHistory() throws {
        let root=FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("edenplaces-batch-test-"+UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let state=root.appendingPathComponent("state")
        let rfile=state.appendingPathComponent("accounts.json")
        let a=PlacesSyncProfile(provider:.dropbox,remoteSource:"managed",remoteName:"cloud1",label:"Personal",
                                localRoot:root.appendingPathComponent("localA").path,
                                folderGrants:[try PlacesFolderPermission("Data",mode:.sync)],automatic:true)
        let b=PlacesSyncProfile(provider:.googleDrive,remoteSource:"system",remoteName:"drive2",label:"Work",
                                localRoot:root.appendingPathComponent("localB").path,
                                folderGrants:[try PlacesFolderPermission("Data",mode:.sync)],automatic:true)
        try PlacesProfilesPersistence.save(PlacesProfileRegistry(profiles:[a,b]),to:rfile)
        let pa=FakeCloud(.dropbox),pb=FakeCloud(.googleDrive)
        pa.folders["Data"]=["a.txt":Data("first".utf8)]
        pb.folders["Data"]=["b.txt":Data("second".utf8)]
        let runner=PlacesProfileBatchRunner(registryURL:rfile,dataDirectory:state) { p in
            if p.id==a.id {return pa};return pb
        }
        let stamp=Date(timeIntervalSince1970:100000)
        let result=try runner.runDue(now:stamp)
        XCTAssertEqual(Set(result.completedProfileIDs),Set([a.id,b.id]))
        XCTAssertTrue(result.failedProfileIDs.isEmpty)
        XCTAssertEqual(result.reports[a.id]?.downloads,1)
        XCTAssertEqual(result.reports[b.id]?.downloads,1)
        XCTAssertEqual(try String(contentsOf:root.appendingPathComponent("localA/Data/a.txt"),encoding:.utf8),"first")
        XCTAssertEqual(try String(contentsOf:root.appendingPathComponent("localB/Data/b.txt"),encoding:.utf8),"second")
        let second=try runner.runDue(now:stamp.addingTimeInterval(30))
        XCTAssertTrue(second.completedProfileIDs.isEmpty)
    }
    func testRegistryDisablesAccountBeforeScheduledStart() throws {
        let root=FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("edenplaces-batch-test-"+UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let state=root.appendingPathComponent("state"),registryURL=state.appendingPathComponent("registry.json")
        let a=PlacesSyncProfile(provider:.dropbox,remoteSource:"managed",remoteName:"cloud1",label:"Personal",
                                localRoot:root.appendingPathComponent("localA").path,
                                folderGrants:[try PlacesFolderPermission("Data",mode:.sync)],automatic:false)
        try PlacesProfilesPersistence.save(PlacesProfileRegistry(profiles:[a]),to:registryURL)
        let cloud=FakeCloud(.dropbox);cloud.folders["Data"]=["x":Data("hello".utf8)]
        let runner=PlacesProfileBatchRunner(registryURL:registryURL,dataDirectory:state){_ in cloud}
        let result=try runner.runDue()
        XCTAssertTrue(result.completedProfileIDs.isEmpty)
        XCTAssertTrue(cloud.calls.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent("localA/Data/x").path))
    }
}