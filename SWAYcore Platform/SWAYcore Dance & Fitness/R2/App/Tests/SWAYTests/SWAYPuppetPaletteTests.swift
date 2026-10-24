import Foundation
import XCTest
@testable import SWAY

final class SWAYPuppetPaletteTests: XCTestCase {
    func testDeliveredAvatarCatalogOnlyOffersRealAppearanceChoices() {
        XCTAssertEqual(SWAYAvatarCatalog.options(.skin).count, 3)
        XCTAssertEqual(SWAYAvatarCatalog.options(.top).count, 3)
        XCTAssertTrue(SWAYAvatarCatalog.options(.skin).allSatisfy(\.available))
        XCTAssertTrue(SWAYAvatarCatalog.options(.top).allSatisfy(\.available))
        let unsupported: [SWAYAvatarCategory] = [.body, .face, .hair, .hairColor,
                                                  .bottom, .shoes, .accessory]
        for category in unsupported {
            XCTAssertTrue(SWAYAvatarCatalog.options(category).isEmpty,
                          "Never advertise unbuilt Create-a-Dancer options: \(category)")
        }
    }

    func testOfflineBundleContainsTheCustomizationManifestAndVariants() {
        XCTAssertTrue(SWAYPuppetPaletteResolver.hasDeliveredVariants)
        var profile = SwayCharacterProfile()
        profile.skinTone = 0
        profile.outfitStyle = 1
        let head = SWAYPuppetPaletteResolver.file("yourDancer_front_head.png", profile: profile)
        let chest = SWAYPuppetPaletteResolver.file("yourDancer_front_chest.png", profile: profile)
        let arm = SWAYPuppetPaletteResolver.file("yourDancer_front_rightUpperArm.png", profile: profile)
        XCTAssertNotEqual(head, "yourDancer_front_head.png")
        XCTAssertNotEqual(chest, "yourDancer_front_chest.png")
        XCTAssertNotEqual(arm, "yourDancer_front_rightUpperArm.png")
        for filename in [head, chest, arm] {
            let stem = (filename as NSString).deletingPathExtension
            XCTAssertNotNil(Bundle.main.url(forResource: stem, withExtension: "png"), filename)
        }
    }

    func testDefaultIdentityAndCoachesRemainUntouched() {
        let baseline = SwayCharacterProfile()
        XCTAssertEqual(SWAYPuppetPaletteResolver.file("yourDancer_front_head.png", profile: baseline),
                       "yourDancer_front_head.png")
        var modified = baseline
        modified.skinTone = 0
        modified.outfitStyle = 2
        XCTAssertEqual(SWAYPuppetPaletteResolver.file("lucia_front_head.png", profile: modified),
                       "lucia_front_head.png")
        XCTAssertEqual(SWAYPuppetPaletteResolver.file("kyle_front_head.png", profile: modified),
                       "kyle_front_head.png")
        XCTAssertEqual(SWAYPuppetPaletteResolver.file("yourDancer_front_head.png", profile: nil),
                       "yourDancer_front_head.png")
    }
}
