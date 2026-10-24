import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Optional local explanation only. BIFROST's capability registry, permissions,
/// safety checks and execution remain deterministic and usable without AI.
@MainActor final class BifrostLocalIntelligence: ObservableObject {
    @Published private(set) var availabilityMessage = "Checking on-device model…"
    @Published private(set) var available = false
    @Published private(set) var isRunning = false
    @Published private(set) var explanation = ""
    private var generation = 0
    private var currentTask: Task<Void, Never>?

    init() { refreshAvailability() }

    func refreshAvailability() {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                available = true
                availabilityMessage = "Available on this Mac · no cloud account needed"
            case .unavailable(let reason):
                available = false
                availabilityMessage = "Unavailable on this Mac: \(reason)"
            @unknown default:
                available = false
                availabilityMessage = "Availability not recognized by this app"
            }
        } else {
            available = false
            availabilityMessage = "Requires an Apple Intelligence-compatible macOS version"
        }
        #else
        available = false
        availabilityMessage = "On-device Foundation Models framework unavailable"
        #endif
    }

    func explain(capabilities: [BifrostCapability], services: Int, shortcutStatus: String) {
        refreshAvailability()
        guard available, !isRunning else { return }
        generation += 1
        let requestID = generation
        isRunning = true
        explanation = "Processing locally…"
        // Only non-sensitive observable state enters the model. No project
        // files, credentials, usernames, device addresses or shell instructions.
        let names = capabilities.prefix(12).map {
            "\($0.name): \($0.available ? "available" : "unavailable")"
        }.joined(separator: "; ")
        let prompt = """
        Explain BIFROST's observed local capabilities in clear, concise language.
        Capabilities: \(names).
        Nearby Bonjour services observed: \(services).
        Shortcuts status: \(shortcutStatus.prefix(150)).
        Give up to three local, read-only next checks. If a capability is not
        observed, say so. Do not claim a service is trusted, paired, running or
        working just because a capability exists. Do not suggest remote/cloud
        providers, guess device identities, or generate commands to execute.
        """
        currentTask = Task {
            #if canImport(FoundationModels)
            if #available(macOS 26.0, *) {
                do {
                    let session = LanguageModelSession(
                        instructions: "You explain observed macOS capability facts. Be concise, conservative and accurate. Never claim execution."
                    )
                    let result = try await session.respond(to: prompt)
                    guard !Task.isCancelled, requestID == generation else { return }
                    explanation = result.content
                } catch {
                    guard requestID == generation else { return }
                    explanation = "Local explanation failed: \(error.localizedDescription)"
                }
            }
            #endif
            if requestID == generation { isRunning = false }
        }
    }

    func cancel() {
        generation += 1
        currentTask?.cancel()
        currentTask = nil
        isRunning = false
        explanation = "Local explanation cancelled. No action was taken."
    }
}
