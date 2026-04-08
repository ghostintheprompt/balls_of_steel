import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = BrandIconFactory.makeDockIcon()

        Task {
            await SignalNotification.shared.prepareForLaunch()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              url.host == "api.schwab.com" else { return }

        handleSchwabCallback(url: url)
    }

    private func handleSchwabCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            #if DEBUG
            print("Invalid callback URL")
            #endif
            return
        }

        Task {
            do {
                let token = try await SchwabService.shared.exchangeCodeForToken(code)
                UserDefaults.standard.setValue(token, forKey: "schwabApiKey")

                NotificationCenter.default.post(
                    name: .schwabConnectionComplete,
                    object: nil
                )
            } catch {
                #if DEBUG
                print("Auth error: \(error)")
                #endif
            }
        }
    }
}

extension Notification.Name {
    static let schwabConnectionComplete = Notification.Name("schwabConnectionComplete")
} 
