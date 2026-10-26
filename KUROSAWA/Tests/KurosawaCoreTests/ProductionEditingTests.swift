import Foundation
import Testing
@testable import KurosawaCore

@Test func semanticProductionMutations() throws {
    var production = Production(title: "Feature", scope: .featureFilm, format: .hybrid, primaryGenre: "Drama")
    let sequence = try production.addSequence(title: "Act 1")
    let scene = try production.addScene(to: sequence, title: "Opening")
    let shot = try production.addShot(to: scene, title: "Close-up")
    let take = try production.addTake(to: shot, label: "Camera A")
    try production.selectTake(take, for: shot)
    #expect(production.sequences[0].scenes[0].shots[0].selectedTakeID == take)
}
@Test func semanticMutationsFailWithoutDataLoss() throws {
    var production = Production(title: "Film", scope: .shortFilm, format: .liveAction, primaryGenre: "Mystery")
    #expect(throws: ProductionEditError.unknownSequence) { try production.addScene(to: UUID(), title: "Missing") }
    #expect(throws: ProductionEditError.emptyTitle) { try production.addSequence(title: " ") }
    #expect(throws: ProductionEditError.unknownShot) { try production.addTake(to: UUID(), label: "Take") }
    #expect(production.sequences.isEmpty)
}
