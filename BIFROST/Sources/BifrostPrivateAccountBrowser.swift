import SwiftUI
import WebKit

/// Native session surface. One durable WebKit store per saved identity, never
/// the default store or another app's browser profile. No credential extraction.
@MainActor
final class BifrostAccountBrowserSession: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let identity: BifrostAccountIdentity
    let webView: WKWebView
    @Published private(set) var address = ""
    @Published private(set) var message = ""
    @Published private(set) var loading = false
    @Published private(set) var canGoBack = false

    init(identity: BifrostAccountIdentity) {
        self.identity = identity
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: identity.id)
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    func openProvider() {
        message = ""
        webView.load(URLRequest(url: identity.provider.homeURL))
    }
    func reload() {
        if let url = webView.url, identity.provider.allows(url) {
            webView.reload()
        } else { openProvider() }
    }
    func stop() { webView.stopLoading(); loading = false }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        // Restrict top-level navigations and new windows; provider-managed
        // subframes remain subject to WebKit's normal origin/TLS policies.
        if navigationAction.targetFrame?.isMainFrame == false {
            let scheme = navigationAction.request.url?.scheme?.lowercased()
            decisionHandler(scheme == "https" || scheme == "about" ? .allow : .cancel)
            return
        }
        guard let url = navigationAction.request.url, identity.provider.allows(url) else {
            message = "Navigation blocked: this destination is outside the supported provider sign-in route."
            decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Keep approved popup sign-in in the SAME identity-owned session.
        if let url = navigationAction.request.url, identity.provider.allows(url) {
            webView.load(navigationAction.request)
        } else {
            message = "Provider popup destination is unsupported. No external browser was opened."
        }
        return nil
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loading = true; message = ""; updateNavigation()
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loading = false; updateNavigation()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        failed(error)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        failed(error)
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loading = false
        message = "The provider page stopped. Reload to retry; your saved identity remains available."
    }
    private func failed(_ error: Error) {
        loading = false; updateNavigation()
        if (error as NSError).code != NSURLErrorCancelled {
            message = "The provider page could not load. Check the connection and try Reload."
        }
    }
    private func updateNavigation() {
        address = webView.url?.absoluteString ?? identity.provider.homeURL.absoluteString
        canGoBack = webView.canGoBack
    }
}

private struct BifrostAccountWebView: NSViewRepresentable {
    let session: BifrostAccountBrowserSession
    func makeNSView(context: Context) -> WKWebView { session.webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    static func dismantleNSView(_ nsView: WKWebView, coordinator: ()) {
        nsView.stopLoading()
        nsView.navigationDelegate = nil
        nsView.uiDelegate = nil
    }
}

struct BifrostPrivateAccountBrowser: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: BifrostAccountBrowserSession
    init(identity: BifrostAccountIdentity) {
        _session = StateObject(wrappedValue: BifrostAccountBrowserSession(identity: identity))
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundStyle(BifrostUI.bridge)
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.identity.label + " · " + session.identity.provider.title).font(.headline)
                    Text(session.identity.purpose.rawValue + " · Separate persistent WebKit session")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Back") { session.webView.goBack() }.disabled(!session.canGoBack)
                Button(session.loading ? "Stop" : "Reload") {
                    if session.loading { session.stop() } else { session.reload() }
                }
                Button("Close") { session.stop(); dismiss() }
            }.padding(12)
            Text(session.address.isEmpty ? session.identity.provider.homeURL.absoluteString : session.address)
                .font(.caption.monospaced()).lineLimit(1).truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.bottom, 8)
                .accessibilityLabel("Provider page address")
            if session.loading { ProgressView().progressViewStyle(.linear) }
            if !session.message.isEmpty {
                Text(session.message).font(.callout).foregroundStyle(BifrostUI.warning)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
            }
            Divider()
            BifrostAccountWebView(session: session)
            Divider()
            Text("Sign in directly with the provider. Website access does not verify an MCP or RDC connection. Apple Passwords/AutoFill support depends on the provider and macOS; BIFROST does not import or read your passwords.")
                .font(.caption).foregroundStyle(.secondary).padding(12)
        }
        .frame(minWidth: 820, minHeight: 620)
        .onAppear { session.openProvider() }
        .onDisappear { session.stop() }
    }
}
