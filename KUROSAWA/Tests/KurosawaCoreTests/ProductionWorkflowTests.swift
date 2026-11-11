import Foundation
import Testing
@testable import KurosawaCore

@Test func workflowPreviewAndApply() throws {
    let recipe = WorkflowRecipe(title: "Documentary standard", sequences: [
        WorkflowSequence(title: "Opening", scenes: [
            WorkflowScene(title: "Interview", shots: [WorkflowShot(title: "Wide"), WorkflowShot(title: "Close-up")])
        ])
    ])
    let preview = try recipe.preview()
    #expect(preview.addedSequences == 1)
    #expect(preview.addedScenes == 1)
    #expect(preview.addedShots == 2)
    var production = Production(title: "Pilot", scope: .documentary, format: .liveAction, primaryGenre: "Documentary")
    let result = try production.apply(recipe)
    #expect(result == preview)
    #expect(production.sequences.first?.scenes.first?.shots.count == 2)
}

@Test func workflowFailureDoesNotMutate() throws {
    var p = Production(title: "Pilot", scope: .reel, format: .liveAction, primaryGenre: "Experimental")
    let orig = p
    let malformed = WorkflowRecipe(title: "Broken", sequences: [
        WorkflowSequence(title: "Act 1", scenes: [WorkflowScene(title: "Scene", shots: [WorkflowShot(title: "   ")])])
    ])
    #expect(throws: WorkflowError.self) { try p.apply(malformed) }
    #expect(p == orig)
}
