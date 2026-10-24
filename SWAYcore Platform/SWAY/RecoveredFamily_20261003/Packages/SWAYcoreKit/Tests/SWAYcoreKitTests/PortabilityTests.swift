import XCTest
@testable import SWAYcoreKit

final class SwayPackTests: XCTestCase {
    func sample() -> SwayPack {
        let ms = Array(MoveLibrary.all.prefix(3))
        return SwayPack(id: "p1", title: "Pack", author: "A", movements: ms,
                        combinations: [Combination(id: "c1", name: "C", steps: [ContentStep(movementID: ms[0].id, repetitions: 2), ContentStep(movementID: ms[1].id, mirrored: true)])],
                        musicReferences: [.init(title: "Song", artist: "Artist", catalogID: "x", bpm: 120)])
    }
    func testRoundTripIsIdentical() throws {
        let p = sample(); let d = try p.export(); let q = try SwayPack.import(d)
        XCTAssertEqual(p.movements, q.movements); XCTAssertEqual(p.combinations, q.combinations); XCTAssertEqual(p.title, q.title)
        // consumer runtime sees identical counts/poses/timing
        for (a, b) in zip(p.movements, q.movements) { for c in 1...8 { XCTAssertEqual(a.pose(atCount: c), b.pose(atCount: c)) } }
        XCTAssertEqual(try SwayPack.import(q.export()).checksum, q.checksum)
    }
    func testTamperingIsDetected() throws {
        var s = String(data: try sample().export(), encoding: .utf8)!
        s = s.replacingOccurrences(of: "\"title\" : \"Pack\"", with: "\"title\" : \"Hacked\"")
        XCTAssertThrowsError(try SwayPack.import(Data(s.utf8))) { XCTAssertEqual($0 as? SwayPack.PackError, .checksumMismatch) }
    }
    func testMalformedInputs() throws {
        XCTAssertThrowsError(try SwayPack.import(Data("not json".utf8))) { XCTAssertEqual($0 as? SwayPack.PackError, .notJSON) }
        XCTAssertThrowsError(try SwayPack.import(Data("[1,2]".utf8)))
        XCTAssertThrowsError(try SwayPack.import(Data("{}".utf8))) { XCTAssertEqual($0 as? SwayPack.PackError, .missingField("formatVersion")) }
        XCTAssertThrowsError(try SwayPack.import(Data("{\"formatVersion\":99}".utf8))) { XCTAssertEqual($0 as? SwayPack.PackError, .unsupportedVersion(99)) }
        XCTAssertThrowsError(try SwayPack.import(Data("{\"formatVersion\":0}".utf8)))
        XCTAssertThrowsError(try SwayPack.import(Data("{\"formatVersion\":2,\"id\":\"x\"}".utf8)))
        XCTAssertThrowsError(try SwayPack.import(Data(count: SwayPack.maxBytes + 1))) { XCTAssertEqual($0 as? SwayPack.PackError, .tooLarge) }
    }
    func testInvalidContentRejected() throws {
        var p = sample(); p.movements[1].id = p.movements[0].id
        XCTAssertThrowsError(try p.export()) { XCTAssertEqual($0 as? SwayPack.PackError, .duplicateID(p.movements[0].id)) }
        var q = sample(); q.combinations[0].steps.append(ContentStep(movementID: "ghost"))
        XCTAssertThrowsError(try q.export()) { XCTAssertEqual($0 as? SwayPack.PackError, .danglingReference("ghost")) }
        var r = sample(); r.movements[0].keyframes.removeAll()
        XCTAssertThrowsError(try r.export())
        var t = sample(); t.musicReferences[0].bpm = 5
        XCTAssertThrowsError(try t.export()) { XCTAssertEqual($0 as? SwayPack.PackError, .invalidTempo) }
    }
    func testV1Migration() throws {
        // Build a v2 JSON then rewrite it into legacy v1 shape.
        let d = try sample().export()
        var o = try JSONSerialization.jsonObject(with: d) as! [String: Any]
        var moves = o["movements"] as! [[String: Any]]
        for i in moves.indices {
            var kfs = moves[i]["keyframes"] as! [[String: Any]]
            for j in kfs.indices { kfs[j]["hold"] = nil }
            moves[i]["keyframes"] = kfs; moves[i]["level"] = nil; moves[i]["revision"] = nil
        }
        o["movements"] = nil; o["moves"] = moves; o["formatVersion"] = 1
        o["combinations"] = nil; o["musicReferences"] = nil; o["checksum"] = nil
        let v1 = try JSONSerialization.data(withJSONObject: o)
        let m = try SwayPack.import(v1)
        XCTAssertEqual(m.formatVersion, SwayPack.currentVersion)
        XCTAssertEqual(m.movements.map(\.id), sample().movements.map(\.id))
        let a = m.movements[0].pose(atCount: 3), b = sample().movements[0].pose(atCount: 3)
        for j in SWAYJoint.allCases { XCTAssertEqual(a.position(j)!.x, b.position(j)!.x, accuracy: 1e-9); XCTAssertEqual(a.position(j)!.y, b.position(j)!.y, accuracy: 1e-9) }
        XCTAssertTrue(m.combinations.isEmpty)
    }
}

final class RigAndPersistenceTests: XCTestCase {
    func good() -> CharacterManifest {
        CharacterManifest(contract: RigContract.contractName, characterID: "lucia", displayName: "Lucia", asset: "lucia.usdz", blendSource: "lucia.blend",
                          upAxis: "Y", metersPerUnit: 1, heightMeters: 1.7, joints: RigContract.requiredJoints, meshes: RigContract.requiredMeshes,
                          materials: ["Skin"], textures: ["lucia_skin.png"], clips: RigContract.proofClips, triangleCount: 30000, maxSkinInfluences: 4, visualQuality: "UNREVIEWED")
    }
    func testManifestValidation() {
        XCTAssertEqual(RigContract.validate(good()), [])
        var m = good(); m.joints.removeLast(); XCTAssertFalse(RigContract.validate(m).isEmpty)
        m = good(); m.joints.append(m.joints[0]); XCTAssertTrue(RigContract.validate(m).contains("duplicate joints"))
        m = good(); m.upAxis = "Z"; XCTAssertFalse(RigContract.validate(m).isEmpty)
        m = good(); m.heightMeters = 9; XCTAssertFalse(RigContract.validate(m).isEmpty)
        m = good(); m.clips.removeFirst(); XCTAssertFalse(RigContract.validate(m).isEmpty)
        m = good(); m.triangleCount = 10_000_000; XCTAssertFalse(RigContract.validate(m).isEmpty)
        m = good(); m.textures = []; XCTAssertFalse(RigContract.validate(m).isEmpty)
        m = good(); m.maxSkinInfluences = 8; XCTAssertFalse(RigContract.validate(m).isEmpty)
    }
    func testRequiredCharactersListed() {
        XCTAssertEqual(Set(RigContract.requiredCharacters), ["lucia", "nandi", "thabo", "zuri", "kyle", "yourdancer"])
        XCTAssertEqual(Set(CoachID.allCases.map(\.rawValue)), Set(RigContract.requiredCharacters).subtracting(["yourdancer"]))
    }
    func testRetargetCarriesRestDirectionOntoPosedDirection() {
        let posed = PoseBuilder.build(Stance(armL: Arm.high, armR: Arm.down, legL: Leg.lift, legR: Leg.stand))
        let rot = PoseRetargeter.worldRotations(for: posed)
        for (j, c) in [(SWAYJoint.shoulderL, SWAYJoint.elbowL), (.hipL, .kneeL), (.elbowL, .wristL)] {
            let restDir = Proportions.rest[c]! - Proportions.rest[j]!
            let want = (posed.position(c)! - posed.position(j)!).normalized
            let got = rot[j]!.rotate(restDir).normalized
            XCTAssertEqual(got.x, want.x, accuracy: 1e-6); XCTAssertEqual(got.y, want.y, accuracy: 1e-6); XCTAssertEqual(got.z, want.z, accuracy: 1e-6)
        }
        let neutral = PoseRetargeter.worldRotations(for: PoseBuilder.build(.neutral))
        XCTAssertEqual(neutral[.spine]!, .identity)
    }
    func testStoreRoundTripAndCorruptFallsBackToBackup() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("sway-\(UUID().uuidString)")
        let store = JSONFileStore<LearnerProgress>(url: dir.appendingPathComponent("p.json"))
        XCTAssertNil(try store.load())
        var p = LearnerProgress(); var s = ScoreAccumulator(); for _ in 0..<10 { s.record(.match(error: 1)) }
        p.recordAttempt(movementID: "m", score: s, day: "2026-10-01"); try store.save(p)
        p.recordAttempt(movementID: "m", score: s, day: "2026-10-02"); try store.save(p)
        XCTAssertEqual(try store.load(), p); XCTAssertEqual(p.streakDays, 2)
        try Data("garbage".utf8).write(to: store.url)
        let recovered = try XCTUnwrap(try store.load()); XCTAssertEqual(recovered.attempts["m"], 1)   // previous good save
        try Data("garbage".utf8).write(to: store.url.appendingPathExtension("bak"))
        XCTAssertThrowsError(try store.load())
    }
    func testNoAttemptWithoutEvidenceKeepsMastery() {
        var p = LearnerProgress(); p.recordAttempt(movementID: "m", score: ScoreAccumulator(), day: "2026-10-01")
        XCTAssertEqual(p.mastery["m"], .discovered)   // attempt recorded, no progression without evidence
    }
    func testPraiseRequiresEvidence() {
        XCTAssertNil(CueFactory.praise(accuracy: nil, coverage: 0, now: 1, level: .normal, coach: .lucia))
        XCTAssertNil(CueFactory.praise(accuracy: 0.9, coverage: 0.1, now: 1, level: .normal, coach: .lucia))
        XCTAssertNotNil(CueFactory.praise(accuracy: 0.9, coverage: 0.8, now: 1, level: .normal, coach: .lucia))
        XCTAssertNil(CueFactory.reposition(now: 1, level: .off).spoken)
    }
}
