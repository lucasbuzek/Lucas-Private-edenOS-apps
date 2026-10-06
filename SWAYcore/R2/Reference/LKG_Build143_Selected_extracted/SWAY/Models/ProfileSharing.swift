import Foundation
import UIKit

enum SwayAfterSessionAction: String, Codable, CaseIterable, Identifiable {
    case result = "Show Result"
    case quickShare = "Quick Share"
    case customize = "Customize Card"
    case saveOnly = "Save Only"
    case off = "Off"
    var id:String { rawValue }
}
enum SwayShareCardFormat: String, Codable, CaseIterable, Identifiable {
    case square = "Square", story = "Story", landscape = "Landscape"
    var id:String { rawValue }
}
struct SwayShareDefaults: Codable {
    var afterSession:SwayAfterSessionAction = .result
    var showNickname = true
    var showCharacter = true
    var showDuration = true
    var showScore = false
    var showAchievement = true
    var defaultMessage = ""
    var format:SwayShareCardFormat = .square
}
struct SwayUserProfile: Codable {
    var id:UUID = UUID()
    var nickname:String = ""
    var share = SwayShareDefaults()
}
struct SwaySessionResult: Codable, Identifiable {
    var id:UUID = UUID()
    var endedAt:Date = Date()
    var durationMinutes:Int
    var style:String
    var moveIDs:[String]
    var averageScore:Double
    var maxCombo:Int
    var achievements:[SwayAwardID]
}
struct SwayShareCardPayload: Codable {
    var nickname:String?
    var message:String?
    var title:String
    var subtitle:String
    var stats:[String]
}

/// Local renderer. The resulting PNG is an ordinary share artifact and contains
/// only fields selected for sharing; no HealthKit, camera frame, face geometry or pose stream.
enum SwayShareCardRenderer {
    @MainActor static func png(payload:SwayShareCardPayload, format:SwayShareCardFormat)->Data? {
        let size:CGSize = format == .story ? .init(width:1080,height:1920) :
                          format == .landscape ? .init(width:1600,height:900) : .init(width:1080,height:1080)
        let renderer=UIGraphicsImageRenderer(size:size)
        return renderer.pngData { ctx in
            UIColor(red:0.035,green:0.045,blue:0.075,alpha:1).setFill()
            ctx.fill(CGRect(origin:.zero,size:size))
            let margin=size.width*0.08
            func draw(_ text:String,_ y:CGFloat,_ font:UIFont,_ color:UIColor = .white) {
                text.draw(in:CGRect(x:margin,y:y,width:size.width-margin*2,height:font.lineHeight*2.4),
                          withAttributes:[.font:font,.foregroundColor:color])
            }
            draw("SWAY",margin,UIFont.systemFont(ofSize:size.width*0.075,weight:.black),.cyan)
            draw(payload.title,margin+size.width*0.13,UIFont.systemFont(ofSize:size.width*0.072,weight:.bold))
            draw(payload.subtitle,margin+size.width*0.24,UIFont.systemFont(ofSize:size.width*0.036,weight:.medium),.lightGray)
            var y=margin+size.width*0.34
            for stat in payload.stats { draw(stat,y,UIFont.systemFont(ofSize:size.width*0.045,weight:.semibold)); y += size.width*0.065 }
            if let message=payload.message,!message.isEmpty { draw("“\(message)”",y+size.width*0.04,UIFont.italicSystemFont(ofSize:size.width*0.038)) }
            if let name=payload.nickname,!name.isEmpty { draw(name,size.height-margin-size.width*0.08,UIFont.systemFont(ofSize:size.width*0.036,weight:.semibold),.lightGray) }
        }
    }
}
