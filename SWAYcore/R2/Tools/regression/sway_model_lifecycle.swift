import Foundation

@main struct ModelLifecycleRegression {
    static func main() throws {
        var profile=SwayCharacterProfile()
        profile.bodyStyle = .female; profile.skinTone=5; profile.hairStyle=4; profile.hairColor=3
        profile.faceShape=2; profile.outfitStyle=4; profile.footwearStyle=3; profile.accessoryStyle=2
        let encoder=JSONEncoder();encoder.outputFormatting = .sortedKeys
        let data=try encoder.encode(profile)
        let path=FileManager.default.temporaryDirectory.appendingPathComponent("sway-profile-regression-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at:path) }
        try data.write(to:path,options:.atomic)
        let reloaded=try JSONDecoder().decode(SwayCharacterProfile.self,from:Data(contentsOf:path))
        let reencoded=try encoder.encode(reloaded)
        precondition(reencoded==data,"profile choices must survive disk reload")
        let legacy=try JSONDecoder().decode(SwayCharacterProfile.self,from:Data("{}".utf8))
        precondition(legacy.bodyStyle == .neutral && legacy.skinTone==2 && legacy.footwearStyle==0)
        print("PASS YOUR DANCER model all-choice persistence and legacy migration (not UI/runtime)")
        let move=DanceMove(id:"user.march.regression",name:"My March",difficulty:1,impact:1,bpmMin:80,bpmMax:140,space:1,style:"Pop")
        var pack=SwayPackage(creator:"Regression",moves:[move],transitions:[])
        try pack.validate()
        let exported=try encoder.encode(pack)
        pack=try JSONDecoder().decode(SwayPackage.self,from:exported)
        try pack.validate();pack.moves[0].name="Edited March"
        let reshared=try JSONDecoder().decode(SwayPackage.self,from:encoder.encode(pack))
        try reshared.validate()
        precondition(reshared.moves[0].name=="Edited March" && reshared.moves[0].id==move.id)
        print("PASS .swaypack model export/import/edit/reshare (not library UI/share sheet)")
        pack.moves.append(pack.moves[0])
        do { try pack.validate(); fatalError("duplicate package accepted") } catch SwayPackageError.duplicateIdentifiers {}
        print("PASS .swaypack rejects duplicate movement identifiers")
    }
}
