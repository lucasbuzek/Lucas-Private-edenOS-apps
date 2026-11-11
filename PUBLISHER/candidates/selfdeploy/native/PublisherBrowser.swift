// PUBLISHER macOS browser candidate. Must compile/test against the ORIGINAL Xcode project before acceptance.
import SwiftUI
import WebKit
import AppKit

final class PublisherBrowserModel: ObservableObject {
    @Published var address: String = "https://dash.cloudflare.com/"
    @Published var privateMode: Bool = false
    @Published var pageTitle: String = "PUBLISHER"
    @Published var identity: String = "Primary"
    // WebKit storage is deliberately not shared with automation or unrelated apps.
    var webView: WKWebView?
    var store: WKWebsiteDataStore {
        privateMode ? .nonPersistent() : .default()
    }
    func visit() {
        guard var c = URLComponents(string: address.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        if c.scheme == nil { c = URLComponents(string: "https://" + address) ?? c }
        guard c.scheme == "https", let url = c.url else { return }
        webView?.load(URLRequest(url: url))
    }
    func showPasswordsApp() {
        // This opens Apple's app; it does NOT extract passwords or bypass consent.
        let candidate = URL(fileURLWithPath: "/System/Applications/Passwords.app")
        if FileManager.default.fileExists(atPath: candidate.path) {
            NSWorkspace.shared.open(candidate)
        }
    }
}

struct PublisherBrowserView: NSViewRepresentable {
    @ObservedObject var model: PublisherBrowserModel
    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = model.store
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = context.coordinator
        model.webView = web
        model.visit()
        return web
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(model: model) }
    final class Coordinator: NSObject, WKNavigationDelegate {
        let model: PublisherBrowserModel
        init(model: PublisherBrowserModel) { self.model = model }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.model.pageTitle = webView.title ?? "PUBLISHER"
                self.model.address = webView.url?.absoluteString ?? self.model.address
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, ["https", "about"].contains(url.scheme ?? "") { decisionHandler(.allow) }
            else { decisionHandler(.cancel) }
        }
    }
}

@main struct PublisherBrowserApp: App {
    @StateObject private var model = PublisherBrowserModel()
    var body: some Scene {
        WindowGroup("PUBLISHER") {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("PUBLISHER").fontWeight(.semibold)
                    TextField("HTTPS address", text: $model.address, onCommit: { model.visit() })
                        .textFieldStyle(.roundedBorder)
                    Button("Go") { model.visit() }
                    Menu("Accounts") {
                        Button("Cloudflare") { model.address = "https://dash.cloudflare.com/"; model.visit() }
                        Button("Netlify") { model.address = "https://app.netlify.com/"; model.visit() }
                        Button("Apple Books") { model.address = "https://itunesconnect.apple.com/"; model.visit() }
                        Button("Amazon KDP") { model.address = "https://kdp.amazon.com/"; model.visit() }
                    }
                    Button("Passwords") { model.showPasswordsApp() }
                }.padding(12)
                HStack {
                    Text(model.pageTitle).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(model.privateMode ? "Private session" : "Regular session").font(.caption)
                    Button(model.privateMode ? "Switch to Regular" : "New Private Session") {
                        // Native WKWebView must be recreated to isolate data store.
                        model.privateMode.toggle()
                    }
                }.padding(.horizontal, 12).padding(.bottom, 6)
                // Separate render identity creates new WKWebView on privacy switch.
                PublisherBrowserView(model: model).id(model.privateMode)
            }
            .frame(minWidth: 800, minHeight: 560)
        }
    }
}
