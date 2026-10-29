import Foundation

/// Display metadata only. Never identifies a provider user or changes an Rclone remote.
public enum AccountNicknamePolicy {
    public enum Error: Swift.Error, Equatable { case invalidSource, invalidRemote, invalidNickname }

    public static func key(source: String, remote: String) throws -> String {
        guard source == "system" || source == "managed" else { throw Error.invalidSource }
        guard !remote.isEmpty,
              remote.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil
        else { throw Error.invalidRemote }
        return source + "|" + remote
    }

    /// Empty input removes a nickname; all labels are local user assertions, never proof of account identity.
    public static func normalized(_ raw: String) throws -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }
        guard value.count <= 48,
              !value.unicodeScalars.contains(where: { scalar in
                  let number = scalar.value
                  return number < 32 || (number >= 0x7F && number <= 0x9F) ||
                         number == 0x200E || number == 0x200F ||
                         (number >= 0x202A && number <= 0x202E) ||
                         (number >= 0x2066 && number <= 0x2069)
              })
        else { throw Error.invalidNickname }
        return value
    }
}
