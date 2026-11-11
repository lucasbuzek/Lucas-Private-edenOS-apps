import Foundation

/// An explicit, non-destructive editorial cut. KUROSAWA's current production
/// model has no clip timings; callers MUST supply real frame positions here.
public struct EditorialCut: Codable, Equatable, Sendable {
    public let shotID: UUID
    public let sourceStartFrame: Int
    public let durationFrames: Int
    public init(shotID: UUID, sourceStartFrame: Int, durationFrames: Int) {
        self.shotID = shotID
        self.sourceStartFrame = sourceStartFrame
        self.durationFrames = durationFrames
    }
}
public struct EditorialAssembly: Codable, Equatable, Sendable {
    public let title: String
    public let frameRate: Int
    public let width: Int
    public let height: Int
    public let cuts: [EditorialCut]
    public init(title: String, frameRate: Int, width: Int, height: Int, cuts: [EditorialCut]) {
        self.title = title
        self.frameRate = frameRate
        self.width = width
        self.height = height
        self.cuts = cuts
    }
}
public enum EditorialExportError: Error, Equatable, Sendable {
    case invalidAssembly(String)
    case unknownShot
    case unselectedTake
    case missingMedia
    case duplicateShotID
}
public struct EditorialExportPreview: Codable, Equatable, Sendable {
    public let clipCount: Int
    public let distinctAssets: Int
    public let totalFrames: Int
    public let frameRate: Int
    public let warnings: [String]
}
public struct EditorialFCPXML: Sendable {
    public let xml: String
    public let preview: EditorialExportPreview
}

public enum FCPXMLInterchange {
    private static func escaped(_ input: String) -> String {
        var text = ""
        for c in input.unicodeScalars {
            switch c.value {
            case 38: text += "&amp;"
            case 60: text += "&lt;"
            case 62: text += "&gt;"
            case 34: text += "&quot;"
            case 39: text += "&apos;"
            default:
                if c.value >= 32 || c.value == 10 || c.value == 13 || c.value == 9 {
                    text.unicodeScalars.append(c)
                }
            }
        }
        return text
    }

    /// Generates a conservative FCPXML 1.10 interchange document. This does
    /// NOT claim native Final Cut project support or a host-validated round trip.
    /// Media resolution is injected by the caller; MCP enforces workspace scope.
    public static func export(
        production: Production,
        assembly: EditorialAssembly,
        resolveMedia: (String) throws -> URL
    ) throws -> EditorialFCPXML {
        let trimmed = assembly.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.utf8.count <= 240, !trimmed.contains("\0"),
              (1...120).contains(assembly.frameRate), (16...8192).contains(assembly.width),
              (16...8192).contains(assembly.height),
              !assembly.cuts.isEmpty, assembly.cuts.count <= 500 else {
            throw EditorialExportError.invalidAssembly("Title, frame rate, dimensions or cut count invalid")
        }
        let shots = production.sequences.flatMap(\.scenes).flatMap(\.shots)
        guard Set(shots.map(\.id)).count == shots.count else { throw EditorialExportError.duplicateShotID }
        let index = Dictionary(uniqueKeysWithValues: shots.map { ($0.id, $0) })
        var assetOrder = [String]()
        var assetURLs: [String: URL] = [:]
        var assetMaximumFrames: [String: Int] = [:]
        var lines: [String] = []
        var offset = 0
        for edit in assembly.cuts {
            guard edit.sourceStartFrame >= 0, edit.durationFrames > 0,
                  edit.sourceStartFrame <= 5_000_000,
                  edit.durationFrames <= 5_000_000,
                  offset <= 5_000_000 - edit.durationFrames else {
                throw EditorialExportError.invalidAssembly("Invalid or overflowing frame range")
            }
            guard let shot = index[edit.shotID] else { throw EditorialExportError.unknownShot }
            guard let selected = shot.selectedTakeID,
                  let take = shot.takes.first(where: { $0.id == selected }) else { throw EditorialExportError.unselectedTake }
            guard let media = take.mediaReference, !media.isEmpty else { throw EditorialExportError.missingMedia }
            let url = try resolveMedia(media)
            guard url.isFileURL else { throw EditorialExportError.missingMedia }
            let reference = url.standardizedFileURL.path
            if assetURLs[reference] == nil { assetURLs[reference] = url; assetOrder.append(reference) }
            assetMaximumFrames[reference] = max(assetMaximumFrames[reference] ?? 0, edit.sourceStartFrame + edit.durationFrames)
            let resourceID = "r\((assetOrder.firstIndex(of: reference) ?? 0) + 2)"
            let start = "\(edit.sourceStartFrame)/\(assembly.frameRate)s"
            let duration = "\(edit.durationFrames)/\(assembly.frameRate)s"
            let position = "\(offset)/\(assembly.frameRate)s"
            lines.append("      <asset-clip name=\"\(escaped(shot.title))\" ref=\"\(resourceID)\" offset=\"\(position)\" start=\"\(start)\" duration=\"\(duration)\"/>")
            offset += edit.durationFrames
        }
        var result = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<!DOCTYPE fcpxml>",
            "<fcpxml version=\"1.10\">",
            "  <resources>",
            "    <format id=\"r1\" frameDuration=\"1/\(assembly.frameRate)s\" width=\"\(assembly.width)\" height=\"\(assembly.height)\"/>"
        ]
        for (index, item) in assetOrder.enumerated() {
            guard let url = assetURLs[item] else { throw EditorialExportError.missingMedia }
            let resource = "r\(index + 2)"
            result.append("    <asset id=\"\(resource)\" start=\"0s\" duration=\"\(assetMaximumFrames[item] ?? 0)/\(assembly.frameRate)s\" hasVideo=\"1\" format=\"r1\">")
            result.append("      <media-rep kind=\"original-media\" src=\"\(escaped(url.absoluteString))\"/>")
            result.append("    </asset>")
        }
        result += ["  </resources>",
                   "  <project name=\"\(escaped(trimmed))\">",
                   "    <sequence format=\"r1\" duration=\"\(offset)/\(assembly.frameRate)s\" tcStart=\"0s\" tcFormat=\"NDF\">",
                   "      <spine>"]
        result += lines
        result += ["      </spine>", "    </sequence>", "  </project>", "</fcpxml>"]
        let preview = EditorialExportPreview(clipCount: assembly.cuts.count,
            distinctAssets: assetOrder.count, totalFrames: offset,
            frameRate: assembly.frameRate,
            warnings: ["FCPXML 1.10 candidate: Final Cut import and media format have not been validated.",
                       "No timeline data is inferred; duration/start frames are explicit user inputs.",
                       "Source media duration, audio layout, effects and color metadata are not exported."])
        return EditorialFCPXML(xml: result.joined(separator: "\n") + "\n", preview: preview)
    }
}
