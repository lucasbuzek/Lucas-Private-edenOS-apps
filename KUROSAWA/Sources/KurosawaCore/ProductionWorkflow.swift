import Foundation

/// A deterministic, editable production-blueprint template. This is deliberately
/// not a general shell/AI workflow executor. It uses KUROSAWA's existing model.
public struct WorkflowShot: Codable, Equatable, Sendable {
    public var title: String
    public init(title: String) { self.title = title }
}
public struct WorkflowScene: Codable, Equatable, Sendable {
    public var title: String
    public var shots: [WorkflowShot]
    public init(title: String, shots: [WorkflowShot]) { self.title = title; self.shots = shots }
}
public struct WorkflowSequence: Codable, Equatable, Sendable {
    public var title: String
    public var scenes: [WorkflowScene]
    public init(title: String, scenes: [WorkflowScene]) { self.title = title; self.scenes = scenes }
}
public struct WorkflowRecipe: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var version: Int
    public var title: String
    public var sequences: [WorkflowSequence]
    public init(id: UUID = UUID(), version: Int = 1, title: String, sequences: [WorkflowSequence]) {
        self.id = id; self.version = version; self.title = title; self.sequences = sequences
    }
}
public enum WorkflowError: Error, Equatable, Sendable {
    case invalidRecipe(String), limitExceeded(String)
}
public struct WorkflowPreview: Codable, Equatable, Sendable {
    public var workflowID: UUID
    public var version: Int
    public var addedSequences: Int
    public var addedScenes: Int
    public var addedShots: Int
    public var operations: [String]
}
public extension WorkflowRecipe {
    func preview() throws -> WorkflowPreview {
        func valid(_ s: String) -> Bool {
            let value = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return !value.isEmpty && value.utf8.count <= 240 && !value.contains("\0")
        }
        guard version == 1, valid(title), !sequences.isEmpty else {
            throw WorkflowError.invalidRecipe("Recipe needs version 1, title and at least one sequence")
        }
        guard sequences.count <= 20 else { throw WorkflowError.limitExceeded("Maximum 20 sequences per recipe") }
        var scenes = 0, shots = 0
        var operations = [String]()
        for sequence in sequences {
            guard valid(sequence.title), !sequence.scenes.isEmpty else {
                throw WorkflowError.invalidRecipe("Every sequence needs a title and at least one scene")
            }
            scenes += sequence.scenes.count
            operations.append("Sequence: \(sequence.title)")
            for scene in sequence.scenes {
                guard valid(scene.title), !scene.shots.isEmpty else {
                    throw WorkflowError.invalidRecipe("Every scene needs a title and at least one shot")
                }
                shots += scene.shots.count
                operations.append("Scene: \(scene.title)")
                for shot in scene.shots {
                    guard valid(shot.title) else { throw WorkflowError.invalidRecipe("Every shot requires a valid title") }
                    operations.append("Shot: \(shot.title)")
                }
            }
        }
        guard scenes <= 100, shots <= 500 else {
            throw WorkflowError.limitExceeded("Maximum 100 scenes and 500 shots per recipe")
        }
        return WorkflowPreview(workflowID: id, version: version,
                               addedSequences: sequences.count, addedScenes: scenes,
                               addedShots: shots, operations: operations)
    }
}
public extension Production {
    /// Pure in-memory staging: validate every operation *before* mutating the production.
    mutating func apply(_ recipe: WorkflowRecipe) throws -> WorkflowPreview {
        let preview = try recipe.preview()
        var draft = self
        for sequence in recipe.sequences {
            let sequenceID = try draft.addSequence(title: sequence.title)
            for scene in sequence.scenes {
                let sceneID = try draft.addScene(to: sequenceID, title: scene.title)
                for shot in scene.shots {
                    try draft.addShot(to: sceneID, title: shot.title)
                }
            }
        }
        self = draft
        return preview
    }
}
