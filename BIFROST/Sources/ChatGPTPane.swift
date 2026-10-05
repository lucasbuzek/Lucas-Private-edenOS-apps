import SwiftUI
import BifrostChatGPTApple

/// The recovered BIFROST remains the application owner.
struct ChatGPTPane: View {
    @State private var client: ChatGPTLocalProvider?
    @State private var notice = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let client {
                ChatGPTCapabilityView(client: client)
            } else {
                Text("ChatGPT").font(.title)
                Text("Add lightweight chat and files to BIFROST using your eligible ChatGPT plan.")
                Button("Enable ChatGPT") { enable() }
                if !notice.isEmpty { Text(notice).foregroundStyle(.secondary) }
            }
        }
    }
    private func enable() {
        guard let resources = Bundle.main.resourceURL else {
            notice = "BIFROST's installed package is incomplete."; return
        }
        let executable = resources.appendingPathComponent("ChatGPTProvider/bifrost-chatgpt-provider")
        do { client = try ChatGPTLocalProvider(executable: executable) }
        catch {
            notice = "The ChatGPT component is missing or could not start. Install the complete BIFROST candidate package."
        }
    }
}
