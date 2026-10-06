import XCTest
@testable import SWAY

final class SWAYCharacterAppearanceTests:XCTestCase {
    func testRegistryContainsEveryCanonicalDancerOnSharedRig() {
        XCTAssertEqual(SWAYCharacterRegistry.all.map(\.id),["lucia","nandi","thabo","zuri","kyle","user"])
        XCTAssertTrue(SWAYCharacterRegistry.all.allSatisfy { $0.rigContract == "SWAYHumanoid-v1" })
        XCTAssertEqual(Set(SWAYCharacterRegistry.all.map(\.resourceFolder)).count,6)
    }

    func testEveryThreeDimensionalProfileFieldChangesResolvedVisibleAppearance() {
        let baseline=SWAYCharacterAppearanceResolver.resolve(SwayCharacterProfile())
        let mutations:[(String,(inout SwayCharacterProfile)->Void)] = [
            ("bodyStyle",{$0.bodyStyle = .female}),
            ("skinTone",{$0.skinTone=3}), ("hairStyle",{$0.hairStyle=1}),
            ("outfitStyle",{$0.outfitStyle=1}), ("appearancePreset",{$0.appearancePreset=1}),
            ("faceShape",{$0.faceShape=1}), ("eyeStyle",{$0.eyeStyle=1}),
            ("browStyle",{$0.browStyle=1}), ("noseStyle",{$0.noseStyle=1}),
            ("mouthStyle",{$0.mouthStyle=1}), ("hairColor",{$0.hairColor=1}),
            ("facialHairStyle",{$0.facialHairStyle=1}), ("accessoryStyle",{$0.accessoryStyle=1}),
            ("footwearStyle",{$0.footwearStyle=1}), ("bodyScale",{$0.bodyScale=1.1}),
            ("headScale",{$0.headScale=1.1}), ("limbScale",{$0.limbScale=1.1}),
            ("hairScale",{$0.hairScale=1.1})
        ]
        XCTAssertEqual(mutations.count,18,"Update this test whenever the 3D appearance fields change")
        for (name,mutate) in mutations {
            var profile=SwayCharacterProfile(); mutate(&profile)
            XCTAssertNotEqual(SWAYCharacterAppearanceResolver.resolve(profile),baseline,"\(name) was cosmetic UI state only")
        }
    }

    func testPortraitReferenceNeverBecomesAStaticCutoutMaterial() {
        var profile=SwayCharacterProfile(); let baseline=SWAYCharacterAppearanceResolver.resolve(profile)
        profile.portraitData=Data([1,2,3])
        XCTAssertEqual(SWAYCharacterAppearanceResolver.resolve(profile),baseline)
    }

    func testNegativeAndLargeIndexesResolveToAuthoredOptions() {
        var profile=SwayCharacterProfile()
        profile.hairStyle = -1; profile.accessoryStyle=10; profile.skinTone=99
        let result=SWAYCharacterAppearanceResolver.resolve(profile)
        XCTAssertTrue(result.visibleMeshes.contains("yd_hair_bun"))
        XCTAssertTrue(result.visibleMeshes.contains("yd_accessory_none"))
        XCTAssertEqual(result.materialTokens["skin"],"skin_3")
    }
}
