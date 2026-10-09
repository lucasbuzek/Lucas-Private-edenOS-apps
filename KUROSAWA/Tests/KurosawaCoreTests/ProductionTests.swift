import Foundation
import Testing
@testable import KurosawaCore

@Test func selectionRequiresExistingTake() throws {
    let take = Take(label: "Take 1")
    var shot = Shot(title: "Opening", takes: [take])
    #expect(throws: ProductionError.unknownTake) { try shot.select(UUID()) }
    try shot.select(take.id)
    #expect(shot.selectedTakeID == take.id)
}
@Test func productionRoundTrip() throws {
    let production = Production(title: "Pilot", scope: .episode, format: .liveAction, primaryGenre: "Drama", sequences: [Sequence(title: "Act 1", scenes: [Scene(title: "Opening", shots: [Shot(title: "Wide")])])], deliverables: [Deliverable(title: "Master", aspectRatio: "16:9")])
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try ProductionStore.save(production, to: url)
    #expect(try ProductionStore.load(from: url) == production)
}
