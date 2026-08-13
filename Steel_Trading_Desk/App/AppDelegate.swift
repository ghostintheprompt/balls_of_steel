import SwiftUI
#if os(macOS)
import AppKit
#endif

enum SchwabOAuthCallbackHandler {
    @discardableResult
    static func handle(_ url: URL) -> Bool {
        guard isRegisteredCallback(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            #if DEBUG
            print("Invalid Schwab callback URL")
            #endif
            return false
        }

        Task {
            do {
                let token = try await SchwabService.shared.exchangeCodeForToken(code)
                AppConfig.apiKey = token
                await MainActor.run {
                    MarketDataRegistry.shared.use(.schwab)
                    LiveTapeService.shared.isEnabled = true
                }
                await LiveTapeService.shared.tickNow()

                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .schwabConnectionComplete,
                        object: nil
                    )
                }
            } catch {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .schwabConnectionFailed,
                        object: nil,
                        userInfo: ["message": error.localizedDescription]
                    )
                }
                #if DEBUG
                print("Schwab auth error: \(error)")
                #endif
            }
        }
        return true
    }

    @discardableResult
    static func handle(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        return handle(url)
    }

    private static func isRegisteredCallback(_ url: URL) -> Bool {
        if url.scheme == "steeltradingdesk",
           url.host == "oauth",
           url.path == "/callback" {
            return true
        }

        if matchesStoredCallback(url) {
            return true
        }

        if url.scheme == "https",
           url.host == "127.0.0.1",
           [nil, 8182, 8443].contains(url.port),
           ["", "/", "/schwab/oauth/callback"].contains(url.path) {
            return true
        }

        return false
    }

    private static func matchesStoredCallback(_ url: URL) -> Bool {
        guard let registered = URL(string: AppConfig.Schwab.oauthCallbackURL) else {
            return false
        }
        guard url.scheme == registered.scheme,
              url.host == registered.host else {
            return false
        }
        if registered.port != nil, url.port != registered.port {
            return false
        }

        let registeredPath = registered.path.isEmpty ? "/" : registered.path
        let callbackPath = url.path.isEmpty ? "/" : url.path
        return registeredPath == callbackPath
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    private let minimumDeskSize = NSSize(width: 1180, height: 720)
    private let idealDeskSize = NSSize(width: 1440, height: 860)
    private var didApplyInitialDeskFrame = false

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

    func applicationDidBecomeActive(_ notification: Notification) {
        if !didApplyInitialDeskFrame {
            normalizeDeskWindowAfterLaunch()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        SchwabOAuthCallbackHandler.handle(url)
    }

    func application(
        _ application: NSApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void
    ) -> Bool {
        SchwabOAuthCallbackHandler.handle(userActivity)
    }

    private func normalizeDeskWindowAfterLaunch() {
        [0.05, 0.25, 0.75].forEach { delay in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.normalizeDeskWindows()
            }
        }
    }

    private func normalizeDeskWindows() {
        let deskWindows = NSApp.windows.filter(isDeskWindow)
        guard !deskWindows.isEmpty else { return }

        deskWindows.forEach(normalizeDeskWindow)
        didApplyInitialDeskFrame = true
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
        let isLaunchUndersized = !didApplyInitialDeskFrame &&
            (frame.width < targetSize.width - 24 || frame.height < targetSize.height - 24)
        let needsRepair = frame.width < minimumDeskSize.width ||
            frame.height < minimumDeskSize.height ||
            isLaunchUndersized ||
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
        let availableWidth = max(320, visibleFrame.width)
        let availableHeight = max(360, visibleFrame.height)
        let width = min(availableWidth, min(idealDeskSize.width, max(minimumDeskSize.width, availableWidth - horizontalMargin)))
        let height = min(availableHeight, min(idealDeskSize.height, max(minimumDeskSize.height, availableHeight - verticalMargin)))

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
    static let schwabConnectionFailed = Notification.Name("schwabConnectionFailed")
    static let schwabCredentialsChanged = Notification.Name("schwabCredentialsChanged")
}
