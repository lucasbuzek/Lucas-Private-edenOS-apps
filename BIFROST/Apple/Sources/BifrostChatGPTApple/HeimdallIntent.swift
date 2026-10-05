#if canImport(AppIntents)
import AppIntents

/// HEIMDALL installs its existing authenticated BIFROST route here.
/// The closure must authenticate/authorize the originating request before dispatch.
@MainActor public enum HeimdallChatGPTRoute {
    public static var authorizedRequest: (@Sendable (String) async throws -> String)?
    public static func ask(_ prompt: String) async throws -> String {
        guard let route = authorizedRequest else {
            throw ChatGPTIntegrationError.authorizedRouteUnavailable
        }
        return try await route(prompt)
    }
}

/// Link into HEIMDALL's target and register its Shortcut/Action Button surface there.
public struct AskBifrostChatGPTIntent: AppIntent {
    public static var title: LocalizedStringResource = "Ask ChatGPT through BIFROST"
    public static var description = IntentDescription("Use HEIMDALL's authorized BIFROST ChatGPT capability.")
    @Parameter(title: "Question") public var question: String
    public init() {}
    @MainActor public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: try await HeimdallChatGPTRoute.ask(question))
    }
}
#endif
