import Cocoa
import WebKit

class NavDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("CrewOps: page loaded")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("CrewOps: navigation failed: %@", error.localizedDescription)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("CrewOps: provisional navigation failed: %@", error.localizedDescription)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        return .allow
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    let navDelegate = NavDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        // Allow insecure localhost for dev
        config.websiteDataStore = WKWebsiteDataStore.default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = navDelegate
        webView.customUserAgent = "CrewOps-Desktop/1.0"

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CrewOps"
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        let port = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "17080"
        let url = URL(string: "http://localhost:\(port)")!
        NSLog("CrewOps: loading %@", url.absoluteString)
        webView.load(URLRequest(url: url))
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
