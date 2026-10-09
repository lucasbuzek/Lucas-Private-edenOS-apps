import Foundation

public enum ProductionScope: String, Codable, CaseIterable, Sendable {
    case reel, advertisement, musicVideo, documentary, shortFilm, episode, featureFilm, animation, custom
}
public enum ProductionFormat: String, Codable, CaseIterable, Sendable {
    case liveAction, animation2D, animation3D, stopMotion, motionGraphics, aiGenerated, archival, hybrid
}
public enum PipelineStage: String, Codable, CaseIterable, Sendable {
    case brief, research, story, screenplay, treatment, visualBible, storyboard, shotList, previs, preproduction, production, ingest, assembly, roughCut, review, pictureLock, soundVFX, grade, qualityControl, master, versions, archive
}
public struct Take: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var label: String
    public var mediaReference: String?
    public init(id: UUID = UUID(), label: String, mediaReference: String? = nil) { self.id = id; self.label = label; self.mediaReference = mediaReference }
}
public struct Shot: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var takes: [Take]
    public var selectedTakeID: UUID?
    public init(id: UUID = UUID(), title: String, takes: [Take] = [], selectedTakeID: UUID? = nil) { self.id = id; self.title = title; self.takes = takes; self.selectedTakeID = selectedTakeID }
    public mutating func select(_ id: UUID) throws {
        guard takes.contains(where: { $0.id == id }) else { throw ProductionError.unknownTake }
        selectedTakeID = id
    }
}
public enum ProductionError: Error, Equatable { case unknownTake }
public struct Scene: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var shots: [Shot]
    public init(id: UUID = UUID(), title: String, shots: [Shot] = []) { self.id = id; self.title = title; self.shots = shots }
}
public struct Sequence: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var scenes: [Scene]
    public init(id: UUID = UUID(), title: String, scenes: [Scene] = []) { self.id = id; self.title = title; self.scenes = scenes }
}
public struct Deliverable: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var aspectRatio: String
    public init(id: UUID = UUID(), title: String, aspectRatio: String) { self.id = id; self.title = title; self.aspectRatio = aspectRatio }
}
public struct Production: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var scope: ProductionScope
    public var format: ProductionFormat
    public var primaryGenre: String
    public var stage: PipelineStage
    public var sequences: [Sequence]
    public var deliverables: [Deliverable]
    public init(id: UUID = UUID(), title: String, scope: ProductionScope, format: ProductionFormat, primaryGenre: String, stage: PipelineStage = .brief, sequences: [Sequence] = [], deliverables: [Deliverable] = []) {
        self.id = id; self.title = title; self.scope = scope; self.format = format; self.primaryGenre = primaryGenre; self.stage = stage; self.sequences = sequences; self.deliverables = deliverables
    }
}
public enum ProductionStore {
    public static func save(_ production: Production, to url: URL) throws {
        let data = try JSONEncoder().encode(production)
        try data.write(to: url, options: .atomic)
    }
    public static func load(from url: URL) throws -> Production { try JSONDecoder().decode(Production.self, from: Data(contentsOf: url)) }
}
