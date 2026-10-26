import Foundation

/// Additive semantic mutations shared by future native KUROSAWA UI and MCP.
/// All operations are in-memory and do not publish, render or perform network work.
public enum ProductionEditError: Error, Equatable, Sendable {
    case emptyTitle, unknownSequence, unknownScene, unknownShot
}

public extension Production {
    @discardableResult
    mutating func addSequence(title: String) throws -> UUID {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ProductionEditError.emptyTitle }
        let sequence = Sequence(title: title)
        sequences.append(sequence)
        return sequence.id
    }
    @discardableResult
    mutating func addScene(to sequenceID: UUID, title: String) throws -> UUID {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ProductionEditError.emptyTitle }
        guard let index = sequences.firstIndex(where: { $0.id == sequenceID }) else { throw ProductionEditError.unknownSequence }
        let scene = Scene(title: title)
        sequences[index].scenes.append(scene)
        return scene.id
    }
    @discardableResult
    mutating func addShot(to sceneID: UUID, title: String) throws -> UUID {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ProductionEditError.emptyTitle }
        for s in sequences.indices {
            if let c = sequences[s].scenes.firstIndex(where: { $0.id == sceneID }) {
                let shot = Shot(title: title)
                sequences[s].scenes[c].shots.append(shot)
                return shot.id
            }
        }
        throw ProductionEditError.unknownScene
    }
    @discardableResult
    mutating func addTake(to shotID: UUID, label: String, mediaReference: String? = nil) throws -> UUID {
        guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ProductionEditError.emptyTitle }
        let take = Take(label: label, mediaReference: mediaReference)
        try withShot(shotID) { $0.takes.append(take) }
        return take.id
    }
    mutating func selectTake(_ takeID: UUID, for shotID: UUID) throws {
        try withShot(shotID) { try $0.select(takeID) }
    }
    private mutating func withShot(_ shotID: UUID, body: (inout Shot) throws -> Void) throws {
        for s in sequences.indices {
            for c in sequences[s].scenes.indices {
                for sh in sequences[s].scenes[c].shots.indices where sequences[s].scenes[c].shots[sh].id == shotID {
                    try body(&sequences[s].scenes[c].shots[sh])
                    return
                }
            }
        }
        throw ProductionEditError.unknownShot
    }
}
