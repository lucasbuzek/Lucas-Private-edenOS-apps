import Foundation

public enum SwayRecoveredFile<Value> {
    case missing
    case loaded(Value)
    case corrupt(backupURL: URL)
}

public enum SwayCorruptSaveRecovery {
    /// Decodes a save or preserves unreadable bytes beside it before returning defaults.
    public static func load<Value: Decodable>(_ type: Value.Type, from url: URL, decoder: JSONDecoder = JSONDecoder()) -> SwayRecoveredFile<Value> {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        do {
            return .loaded(try decoder.decode(type, from: Data(contentsOf: url)))
        } catch {
            let backup = availableBackupURL(for: url)
            do {
                try FileManager.default.copyItem(at: url, to: backup)
                try FileManager.default.removeItem(at: url)
            } catch {
                // If copying fails, leave the original untouched: user data must not be discarded.
            }
            return .corrupt(backupURL: FileManager.default.fileExists(atPath: backup.path) ? backup : url)
        }
    }

    private static func availableBackupURL(for url: URL) -> URL {
        let first = URL(fileURLWithPath: url.path + ".corrupt")
        guard FileManager.default.fileExists(atPath: first.path) else { return first }
        var index = 2
        while true {
            let candidate = URL(fileURLWithPath: url.path + ".corrupt.\(index)")
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            index += 1
        }
    }
}
