import SwiftUI
import WebKit

// A minimal BIFROST-local dashboard representation, not a general browser.
// OAuth, arbitrary websites and browser automation are intentionally excluded.
struct BifrostLocalDashboardWebView: NSViewRepresentable {
    private static let dashboardURL = URL(string: "http://127.0.0.1:8798/")!

    func makeCoordinator() -> LocalOnlyDelegate { LocalOnlyDelegate() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url: Self.dashboardURL, cachePolicy: .reloadIgnoringLocalCacheData))
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {}

    final class LocalOnlyDelegate: NSObject, WKNavigationDelegate {
        static func permitted(_ url: URL) -> Bool {
            guard let values = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
            return values.scheme == "http" &&
                values.host == "127.0.0.1" &&
                values.port == 8798 &&
                values.user == nil && values.password == nil
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard action.targetFrame != nil,
                  let url = action.request.url, Self.permitted(url) else {
                return .cancel
            }
            return .allow
        }
    }
}
