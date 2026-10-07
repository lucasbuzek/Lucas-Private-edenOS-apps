import XCTest
@testable import SWAY

final class SWAY2DComponentLibraryTests: XCTestCase {
    private func manifest() throws -> SWAY2DComponentManifest {
        try SWAY2DComponentManifest.load()
    }

    func testEveryProfileAppearanceFieldChangesEveryPoseLayerResolution() throws {
        let manifest = try manifest()
        let mutations: [(String, (inout SwayCharacterProfile) -> Void)] = [
            ("bodyStyle", { $0.bodyStyle = .female }),
            ("skinTone", { $0.skinTone += 1 }),
            ("hairStyle", { $0.hairStyle += 1 }),
            ("outfitStyle", { $0.outfitStyle += 1 }),
            ("appearancePreset", { $0.appearancePreset += 1 }),
            ("faceShape", { $0.faceShape += 1 }),
            ("eyeStyle", { $0.eyeStyle += 1 }),
            ("browStyle", { $0.browStyle += 1 }),
            ("noseStyle", { $0.noseStyle += 1 }),
            ("mouthStyle", { $0.mouthStyle += 1 }),
            ("hairColor", { $0.hairColor += 1 }),
            ("facialHairStyle", { $0.facialHairStyle += 1 }),
            ("accessoryStyle", { $0.accessoryStyle += 1 }),
            ("footwearStyle", { $0.footwearStyle += 1 }),
            ("bodyScale", { $0.bodyScale += 0.1 }),
            ("headScale", { $0.headScale += 0.1 }),
            ("limbScale", { $0.limbScale += 0.1 }),
            ("hairScale", { $0.hairScale += 0.1 }),
        ]
        XCTAssertEqual(mutations.count, 18, "Update this list when the persisted appearance contract changes")
        for pose in 1...manifest.poseCount {
            let baseline = SWAY2DComponentResolver.resolve(
                profile: SwayCharacterProfile(), pose: pose, manifest: manifest)
            for (field, mutate) in mutations {
                var changed = SwayCharacterProfile()
                mutate(&changed)
                XCTAssertNotEqual(
                    SWAY2DComponentResolver.resolve(profile: changed, pose: pose, manifest: manifest),
                    baseline,
                    "\(field) did not change the resolved 2.5D stack/tints/scales at pose \(pose)"
                )
            }
        }
    }

    func testManifestHasExplicitStableDrawOrderAndSeparatedHair() throws {
        let manifest = try manifest()
        let orders = manifest.layers.map(\.drawOrder)
        XCTAssertEqual(orders, orders.sorted())
        XCTAssertEqual(Set(orders).count, orders.count)
        XCTAssertNotNil(manifest.layers.first { $0.id == "hairBack" })
        XCTAssertNotNil(manifest.layers.first { $0.id == "hairFront" })
    }

    func testInvalidIndexesAndPosesUseSafeDeterministicFallback() throws {
        let manifest = try manifest()
        var profile = SwayCharacterProfile()
        profile.hairStyle = -1
        profile.faceShape = .max
        profile.accessoryStyle = 10_000
        let first = SWAY2DComponentResolver.resolve(profile: profile, pose: -99, manifest: manifest)
        let second = SWAY2DComponentResolver.resolve(profile: profile, pose: -99, manifest: manifest)
        XCTAssertEqual(first, second)
        XCTAssertTrue((1...manifest.poseCount).contains(first.pose))
        XCTAssertEqual(first.orderedLayers.count, manifest.layers.count)
    }

    func testPortraitBytesNeverBecomeAFlattenedCutoutLayer() throws {
        let manifest = try manifest()
        var profile = SwayCharacterProfile()
        let baseline = SWAY2DComponentResolver.resolve(profile: profile, pose: 1, manifest: manifest)
        profile.portraitData = Data([1, 2, 3])
        XCTAssertEqual(SWAY2DComponentResolver.resolve(profile: profile, pose: 1, manifest: manifest), baseline)
    }
}
