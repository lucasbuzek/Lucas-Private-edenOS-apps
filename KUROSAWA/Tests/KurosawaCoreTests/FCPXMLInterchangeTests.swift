import Foundation
import FoundationXML
import Testing
@testable import KurosawaCore

private func demo() throws -> (Production, EditorialAssembly) {
    var p = Production(title: "Film", scope: .shortFilm, format: .liveAction, primaryGenre: "Drama")
    let seq = try p.addSequence(title: "Act")
    let scene = try p.addScene(to: seq, title: "Scene")
    let shot = try p.addShot(to: scene, title: "Cut <&\" >")
    let take = try p.addTake(to: shot, label: "A", mediaReference: "my clip.mp4")
    try p.selectTake(take, for: shot)
    return (p, EditorialAssembly(title: "Interview <&>", frameRate: 25, width: 1920,
                height: 1080, cuts: [EditorialCut(shotID: shot, sourceStartFrame: 20, durationFrames: 50)]))
}
@Test func fcpxmlValidWellFormedAndEscaped() throws {
    let (p, a) = try demo()
    let result = try FCPXMLInterchange.export(production: p, assembly: a) { reference in
        #expect(reference == "my clip.mp4")
        return URL(fileURLWithPath: "/Volumes/Media/my clip.mp4")
    }
    let parser = XMLParser(data: Data(result.xml.utf8))
    #expect(parser.parse())
    #expect(result.xml.contains("Interview &lt;&amp;&gt;"))
    #expect(result.xml.contains("Cut &lt;&amp;&quot; &gt;"))
    #expect(result.xml.contains("20/25s"))
    #expect(result.xml.contains("50/25s"))
    #expect(result.xml.contains("file:///Volumes/Media/my%20clip.mp4"))
    #expect(result.preview.totalFrames == 50)
}
@Test func fcpxmlRejectsInvalidTimingAndMissingSelection() throws {
    let (p, a) = try demo()
    let bad = EditorialAssembly(title: "Invalid", frameRate: 25, width: 1920, height: 1080,
             cuts: [EditorialCut(shotID: a.cuts[0].shotID, sourceStartFrame: -1, durationFrames: 9)])
    #expect(throws: EditorialExportError.self) {
        try FCPXMLInterchange.export(production: p, assembly: bad) { _ in URL(fileURLWithPath: "/tmp/file.mov") }
    }
    let noShot = EditorialAssembly(title: "Invalid", frameRate: 25, width: 1920, height: 1080,
             cuts: [EditorialCut(shotID: UUID(), sourceStartFrame: 0, durationFrames: 9)])
    #expect(throws: EditorialExportError.unknownShot) {
        try FCPXMLInterchange.export(production: p, assembly: noShot) { _ in URL(fileURLWithPath: "/tmp/file.mov") }
    }
}
