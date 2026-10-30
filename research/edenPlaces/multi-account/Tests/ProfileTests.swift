import Foundation
import XCTest
@testable import ProfileCore

final class ProfileTests: XCTestCase {
    let home=FileManager.default.homeDirectoryForCurrentUser.path
    func make(_ provider:PlacesProvider = .dropbox,_ remote:String = "db1",_ root:String = "A") throws -> PlacesSyncProfile {
        PlacesSyncProfile(provider:provider,remoteSource:"managed",remoteName:remote,label:"Account",localRoot:home+"/Documents/edenplaces-"+root,folderGrants:[try PlacesFolderPermission("Photos/2026",mode:.sync)])
    }
    func testMultipleProvidersAndAccounts() throws {
        let a=try make(.dropbox,"db1","A")
        let b=try make(.googleDrive,"drv2","B")
        let c=try make(.oneDrive,"one3","C")
        let d=try make(.cloudflareR2,"r2_4","D")
        let reg=try PlacesProfileRegistry(profiles:[a,b,c,d]);XCTAssertEqual(reg.profiles.count,4)
        XCTAssertEqual(Set(reg.profiles.map(\.provider)).count,4)
    }
    func testNoOverlappingRoots() throws {
        let a=try make(.dropbox,"db1","A")
        var b=try make(.googleDrive,"drive1","B"); b.localRoot=a.localRoot+"/inner"
        XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a,b]))
        b.localRoot=a.localRoot; XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a,b]))
    }
    func testDifferentAccountsCanUseSameFolderName() throws {
        let a=try make(.dropbox,"db1","A"),b=try make(.dropbox,"db2","B")
        XCTAssertNoThrow(try PlacesProfileRegistry(profiles:[a,b]))
    }
    func testTwoAutomaticWritersToSameRemoteRejected() throws {
        var a=try make(.dropbox,"same","A"),b=try make(.dropbox,"same","B")
        a.automatic=true;b.automatic=true
        XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a,b]))
    }
    func testNoAutoWithoutExplicitSync() throws {
        var a=try make();a.automatic=true;a.folderGrants=[try PlacesFolderPermission("Photos",mode:.download)]
        XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a]))
        a.automatic=false;XCTAssertNoThrow(try PlacesProfileRegistry(profiles:[a]))
    }
    func testNestedFolderGrantsRejected() throws {
        var a=try make();a.folderGrants=[try PlacesFolderPermission("Photos",mode:.sync),try PlacesFolderPermission("Photos/2026",mode:.sync)]
        XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a]))
    }
    func testTraversalAndInvalidRemoteRejected() throws {
        XCTAssertThrowsError(try PlacesFolderPermission("../bad",mode:.sync))
        var a=try make();a.remoteName="bad:path"
        XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a]))
    }
    func testLegacyUnsafeRootsRejected() throws {
        var a=try make()
        a.localRoot=home+"/Library/CloudStorage/Dropbox"
        XCTAssertThrowsError(try PlacesProfileRegistry(profiles:[a]))
    }
    func testDisabledProfileRevokesGrants() throws {
        var a=try make();a.automatic=true
        var r=try PlacesProfileRegistry(profiles:[a]);try r.disable(a.id)
        XCTAssertFalse(r.profiles[0].automatic)
        XCTAssertEqual(r.profiles[0].folderGrants[0].mode,.off)
    }
    func testDueScheduleIsPerProfile() throws {
        var a=try make(.dropbox,"a","A"),b=try make(.googleDrive,"b","B")
        a.automatic=true;b.automatic=true;b.intervalMinutes=60
        let r=try PlacesProfileRegistry(profiles:[a,b]),date=Date(timeIntervalSince1970:200000)
        let due=r.due(at:date,lastRun:[a.id:date.addingTimeInterval(-1801),b.id:date.addingTimeInterval(-1801)])
        XCTAssertEqual(due.map(\.id),[a.id])
    }
    func testPersistenceRoundTripAndMode() throws {
        let r=try PlacesProfileRegistry(profiles:[try make()])
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:dir)}
        let url=dir.appendingPathComponent("profiles.json")
        try PlacesProfilesPersistence.save(r,to:url)
        XCTAssertEqual(try PlacesProfilesPersistence.load(from:url),r)
        let attrs=try FileManager.default.attributesOfItem(atPath:url.path)
        let mode=(attrs[.posixPermissions] as? NSNumber)?.intValue
        XCTAssertEqual(mode,0o600)
    }
    func testTokenOrAccessSecretsNotInSerializedConfiguration() throws {
        let r=try PlacesProfileRegistry(profiles:[try make()])
        let text=String(decoding:try JSONEncoder().encode(r),as:UTF8.self)
        XCTAssertFalse(text.contains("access_token"))
        XCTAssertFalse(text.contains("refresh_token"))
        XCTAssertFalse(text.contains("client_secret"))
    }
}

extension ProfileTests {
    func testMutableInvalidGrantFailsValidation() throws {
        var profile=try make();profile.folderGrants[0].path=" Photos/2026 "
        XCTAssertThrowsError(try profile.validate())
    }
    func testCorruptedGrantDoesNotCrashDisable() throws {
        let id=UUID();var profile=try make();profile.id=id;profile.folderGrants[0].path="../escape"
        var registry=try PlacesProfileRegistry(profiles:[])
        registry.profiles=[profile]
        XCTAssertThrowsError(try registry.disable(id))
    }
    func testUnsafeLabelBidiCharactersRejected() throws {
        var profile=try make();profile.label="Trusted\u{202E}evil"
        XCTAssertThrowsError(try profile.validate())
    }
}