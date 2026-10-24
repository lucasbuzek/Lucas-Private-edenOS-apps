import AppIntents
import AppKit
import CryptoKit
import Foundation

// BIFROST Shortcuts expose local, non-destructive actions only.
// These actions never start optional network services, providers or
// the independent local Headless service by App Intent or Siri invocation.
enum BifrostIntentRoute {
    static let key = "bifrost.intent.requestedSection"
    static let allowed: Set<String> = [
        "Overview", "Headless", "Devices", "Connections", "Capabilities",
        "Install & Setup", "Index & Identity", "App Management", "Settings"
    ]

    static func request(_ section: String) {
        guard allowed.contains(section) else { return }
        UserDefaults.standard.set(section, forKey: key)
    }

    static func consume() -> String? {
        guard let section = UserDefaults.standard.string(forKey: key),
              allowed.contains(section) else { return nil }
        UserDefaults.standard.removeObject(forKey: key)
        return section
    }
}

struct OpenBifrostIntent: AppIntent {
    static let title: LocalizedStringResource = "Open BIFROST"
    static let description = IntentDescription("Open the BIFROST local device and capability dashboard.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Overview")
        return .result()
    }
}

struct ShowBifrostDevicesIntent: AppIntent {
    static let title: LocalizedStringResource = "Show BIFROST Devices"
    static let description = IntentDescription("Open local Bonjour device discovery. Devices are not automatically trusted or paired.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Devices")
        return .result()
    }
}

struct ShowBifrostConnectionsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show BIFROST Connections"
    static let description = IntentDescription("Open local connection status without starting services or remote providers.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Connections")
        return .result()
    }
}

struct ShowBifrostCapabilitiesIntent: AppIntent {
    static let title: LocalizedStringResource = "Show BIFROST Capabilities"
    static let description = IntentDescription("Inspect native and installed capabilities on this Mac.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Capabilities")
        return .result()
    }
}

struct OpenBifrostHeadlessControlsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open BIFROST Headless Controls"
    static let description = IntentDescription("Open native Headless controls without starting the local service.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Headless")
        return .result()
    }
}

struct ShowBifrostSetupIntent: AppIntent {
    static let title: LocalizedStringResource = "Show BIFROST Setup"
    static let description = IntentDescription("Review local installation sources and staging status without installing anything.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Install & Setup")
        return .result()
    }
}

struct ShowBifrostIndexIntent: AppIntent {
    static let title: LocalizedStringResource = "Show BIFROST Index"
    static let description = IntentDescription("Inspect the local BIFROST identity and file index.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        BifrostIntentRoute.request("Index & Identity")
        return .result()
    }
}

/// The local Headless health probe never registers, starts or changes services.
/// A response on port 8798 is trusted only when it matches the installed
/// BIFROST runtime location AND on-disk server source digest.
struct CheckBifrostHeadlessIntent: AppIntent {
    static let title: LocalizedStringResource = "Check BIFROST Headless"
    static let description = IntentDescription("Report whether the independent local BIFROST Headless service is responding, without starting it.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let runtime = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST/runtime")
            .resolvingSymlinksInPath()
        let expectedID = String(
            SHA256.hash(data: Data(runtime.path.utf8))
                .map { String(format: "%02x", $0) }.joined().prefix(16)
        )
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8798/api/health")!)
        request.timeoutInterval = 2
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let identity = payload["identity"] as? [String: Any],
              identity["productId"] as? String == "eden.bifrost.headless",
              identity["schema"] as? String == "bifrost.headless.identity.v1",
              identity["runtimeId"] as? String == expectedID,
              let runningDigest = identity["sourceSha256"] as? String,
              let localSource = try? Data(contentsOf: runtime.appendingPathComponent("server.py")),
              SHA256.hash(data: localSource)
                .map({ String(format: "%02x", $0) }).joined() == runningDigest else {
            return .result(dialog: "BIFROST Headless is stopped, unreachable, or its identity cannot be verified. No service was started.")
        }
        return .result(dialog: "The independent BIFROST Headless service is running locally. No action was taken.")
    }
}

/// Existing BIFROST owner-private automation surface -> local ELYSIUM Desk.
/// This opens a static design preview on the owner's Mac only. It does not
/// grant any ELYSIUM session, launch Headless, connect providers, or send data.
struct OpenElysiumOwnerDeskIntent: AppIntent {
    static let title: LocalizedStringResource = "Open ELYSIUM Owner Desk"
    static let description = IntentDescription("Open the local ELYSIUM Desk preview on this Mac without starting services.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("edenOS/Temporary/ELYSIUM_PWA_OWNER_PILOT/index.html")
        let manager = FileManager.default
        guard let attributes = try? manager.attributesOfItem(atPath: file.path),
              (attributes[.type] as? FileAttributeType) == .typeRegular else {
            return .result(dialog: "The owner-only ELYSIUM Desk preview is not installed on this Mac. No action was taken.")
        }
        guard NSWorkspace.shared.open(file) else {
            return .result(dialog: "Unable to open the local ELYSIUM Desk preview. No services were started.")
        }
        return .result(dialog: "Opened the ELYSIUM owner Desk preview. This is not an authenticated or hosted release.")
    }
}

/// A bounded system-app launch capability for user-directed Shortcuts/Siri.
/// It never reads Messages, Music libraries or TV accounts, sends messages,
/// starts playback, accesses credentials, or changes operating-system access.
enum BifrostOwnerAppleApplication: String, AppEnum {
    case messages, music, tv

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Apple Application"
    static let caseDisplayRepresentations: [BifrostOwnerAppleApplication: DisplayRepresentation] = [
        .messages: "Messages", .music: "Music", .tv: "TV"
    ]

    var bundleIdentifier: String {
        switch self {
        case .messages: return "com.apple.iChat"
        case .music: return "com.apple.Music"
        case .tv: return "com.apple.TV"
        }
    }

    var displayName: String {
        switch self {
        case .messages: return "Messages"
        case .music: return "Music"
        case .tv: return "TV"
        }
    }
}

struct OpenApprovedAppleApplicationIntent: AppIntent {
    static let title: LocalizedStringResource = "Open an Installed Apple App"
    static let description = IntentDescription(
        "Choose Messages, Music, or TV and open its installed Mac app. Nothing is sent or played automatically."
    )
    static let openAppWhenRun = false

    @Parameter(title: "Application")
    var application: BifrostOwnerAppleApplication

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: application.bundleIdentifier
        ) else {
            return .result(dialog: "The selected Apple app is unavailable. Nothing was launched.")
        }
        guard NSWorkspace.shared.open(appURL) else {
            return .result(dialog: "The selected Apple app could not be opened. No message or media action occurred.")
        }
        return .result(dialog: "Opened the selected Apple app. Any message, playback, or account action requires your choice.")
    }
}

struct BifrostAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenBifrostIntent(),
            phrases: ["Open \(.applicationName)", "Show \(.applicationName) dashboard"],
            shortTitle: "Open BIFROST",
            systemImageName: "square.grid.2x2.fill"
        )
        AppShortcut(
            intent: OpenElysiumOwnerDeskIntent(),
            phrases: ["Open my ELYSIUM desk with \(.applicationName)"],
            shortTitle: "ELYSIUM Desk",
            systemImageName: "house"
        )
        AppShortcut(
            intent: OpenApprovedAppleApplicationIntent(),
            phrases: ["Open an Apple app with \(.applicationName)"],
            shortTitle: "Open Apple App",
            systemImageName: "apps.iphone"
        )
        AppShortcut(
            intent: ShowBifrostDevicesIntent(),
            phrases: ["Show devices in \(.applicationName)", "Find devices with \(.applicationName)"],
            shortTitle: "Nearby Devices",
            systemImageName: "macbook.and.iphone"
        )
        AppShortcut(
            intent: ShowBifrostConnectionsIntent(),
            phrases: ["Show connections in \(.applicationName)"],
            shortTitle: "Local Connections",
            systemImageName: "link"
        )
        AppShortcut(
            intent: ShowBifrostCapabilitiesIntent(),
            phrases: ["Show capabilities in \(.applicationName)"],
            shortTitle: "Capabilities",
            systemImageName: "square.stack.3d.up.fill"
        )
        AppShortcut(
            intent: ShowBifrostSetupIntent(),
            phrases: ["Show setup in \(.applicationName)"],
            shortTitle: "Local Setup",
            systemImageName: "shippingbox"
        )
        AppShortcut(
            intent: ShowBifrostIndexIntent(),
            phrases: ["Show index in \(.applicationName)"],
            shortTitle: "Local Index",
            systemImageName: "doc.text.magnifyingglass"
        )
        AppShortcut(
            intent: OpenBifrostHeadlessControlsIntent(),
            phrases: ["Open Headless controls in \(.applicationName)"],
            shortTitle: "Headless Controls",
            systemImageName: "server.rack"
        )
        AppShortcut(
            intent: CheckBifrostHeadlessIntent(),
            phrases: ["Check Headless in \(.applicationName)"],
            shortTitle: "Headless Status",
            systemImageName: "server.rack"
        )
    }
}
