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
    private let minimumDeskSize = NSSize(width: 1180, height: 720)
    private let idealDeskSize = NSSize(width: 1440, height: 860)

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            await SignalNotification.shared.prepareForLaunch()
        }
        Task { @MainActor in
            TimeManager.shared.startWindowMonitor()
            DailyRiskManager.shared.resetIfNewDay()
        }
        normalizeDeskWindowAfterLaunch()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        SchwabOAuthCallbackHandler.handle(url)
    }

    private func normalizeDeskWindowAfterLaunch() {
        [0.05, 0.25, 0.75].forEach { delay in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.normalizeDeskWindows()
            }
        }
    }

    private func normalizeDeskWindows() {
        NSApp.windows
            .filter(isDeskWindow)
            .forEach(normalizeDeskWindow)
    }

    private func isDeskWindow(_ window: NSWindow) -> Bool {
        guard !(window is NSPanel),
              window.parent == nil,
              !window.isSheet,
              window.canBecomeMain
        else {
            return false
        }

        return window.contentView != nil || window.contentViewController != nil
    }

    private func normalizeDeskWindow(_ window: NSWindow) {
        window.minSize = minimumDeskSize

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        guard let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame else {
            return
        }

        let targetSize = deskSize(for: visibleFrame)
        let frame = window.frame
        let needsRepair = frame.width < minimumDeskSize.width ||
            frame.height < minimumDeskSize.height ||
            frame.width < targetSize.width * 0.85 ||
            frame.height < targetSize.height * 0.85 ||
            !visibleFrame.intersects(frame)

        guard needsRepair else {
            return
        }

        let targetFrame = centeredFrame(size: targetSize, in: visibleFrame)
        window.setFrame(targetFrame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
    }

    private func deskSize(for visibleFrame: NSRect) -> NSSize {
        let horizontalMargin: CGFloat = 80
        let verticalMargin: CGFloat = 80
        let width = min(idealDeskSize.width, max(minimumDeskSize.width, visibleFrame.width - horizontalMargin))
        let height = min(idealDeskSize.height, max(minimumDeskSize.height, visibleFrame.height - verticalMargin))

        return NSSize(width: width, height: height)
    }

    private func centeredFrame(size: NSSize, in visibleFrame: NSRect) -> NSRect {
        NSRect(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
#endif

extension Notification.Name {
    static let schwabConnectionComplete = Notification.Name("schwabConnectionComplete")
    static let schwabCredentialsChanged = Notification.Name("schwabCredentialsChanged")
}
