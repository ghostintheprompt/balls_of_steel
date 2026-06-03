import SwiftUI
#if os(macOS)
import AppKit
#endif

enum SchwabOAuthCallbackHandler {
    static func handle(_ url: URL) {
        guard isRegisteredCallback(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            #if DEBUG
            print("Invalid Schwab callback URL")
            #endif
            return
        }

        Task {
            do {
                let token = try await SchwabService.shared.exchangeCodeForToken(code)
                AppConfig.apiKey = token

                NotificationCenter.default.post(
                    name: .schwabConnectionComplete,
                    object: nil
                )
            } catch {
                #if DEBUG
                print("Schwab auth error: \(error)")
                #endif
            }
        }
    }

    private static func isRegisteredCallback(_ url: URL) -> Bool {
        if url.scheme == "steeltradingdesk",
           url.host == "oauth",
           url.path == "/callback" {
            return true
        }

        if url.scheme == "https",
           url.host == "127.0.0.1",
           url.port == 8182,
           ["", "/", "/schwab/oauth/callback"].contains(url.path) {
            return true
        }

        return false
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = BrandIconFactory.makeDockIcon()

        Task {
            await SignalNotification.shared.prepareForLaunch()
        }
        Task { @MainActor in
            TimeManager.shared.startWindowMonitor()
            DailyRiskManager.shared.resetIfNewDay()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        SchwabOAuthCallbackHandler.handle(url)
    }
}
#endif

extension Notification.Name {
    static let schwabConnectionComplete = Notification.Name("schwabConnectionComplete")
} 
