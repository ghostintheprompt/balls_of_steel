import SwiftUI
#if os(macOS)
import AppKit
#endif
#if DEBUG
import OSLog
#endif

enum SchwabOAuthCallbackHandler {
    @discardableResult
    static func handle(_ url: URL) -> Bool {
        #if DEBUG
        if SchwabOAuthDebugHooks.handle(url) {
            return true
        }
        #endif

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
            AppConfig.Schwab.lastOAuthError = ""
            do {
                let redirectURI = registeredRedirectURI(from: url) ?? AppConfig.Schwab.oauthCallbackURL
                let token = try await SchwabService.shared.exchangeCodeForToken(code, redirectURI: redirectURI)
                AppConfig.apiKey = token
                AppConfig.Schwab.lastOAuthError = ""
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
                let message = SchwabService.tokenExchangeFailureMessage(error)
                AppConfig.Schwab.lastOAuthError = message
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .schwabConnectionFailed,
                        object: nil,
                        userInfo: ["message": message]
                    )
                }
                #if DEBUG
                print("Schwab auth error: \(message)")
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

        if url.scheme == "https",
           url.host == "mdrn.app",
           url.path == "/apps/steeltradingdesk/schwab/oauth/callback" {
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

    private static func registeredRedirectURI(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }

        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        if !url.path.isEmpty, url.path != "/" {
            components.path = url.path
        }
        return components.url.map { AppConfig.Schwab.sanitizedCallbackURL($0.absoluteString) }
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


#if DEBUG
private enum SchwabOAuthDebugHooks {
    private static let logger = Logger(subsystem: "app.mdrn.steel", category: "schwab-oauth")

    static func handle(_ url: URL) -> Bool {
        guard url.scheme == "steeltradingdesk",
              url.host == "debug" else {
            return false
        }

        switch url.path {
        case "/settings":
            NotificationCenter.default.post(name: .debugOpenSettings, object: nil)
            return true
        case "/schwab-oauth-start":
            Task { @MainActor in
                await startOAuth()
            }
            return true
        default:
            return false
        }
    }

    @MainActor
    private static func startOAuth() async {
        do {
            let callbackURL = AppConfig.Schwab.oauthCallbackURL
            debug("action=debug_route_start callback=\(callbackURL)")
            let authURL = try SchwabService.shared.authorizationURL(redirectURI: callbackURL)
            let authComponents = URLComponents(url: authURL, resolvingAgainstBaseURL: false)
            let redirectURI = authComponents?.queryItems?.first(where: { $0.name == "redirect_uri" })?.value ?? "missing"
            debug("action=debug_route_auth callback=\(redirectURI) clientLen=\(AppConfig.Schwab.appKeyWithoutPrompt.count)")
            _ = SchwabOAuthSessionCoordinator.shared.start(authURL: authURL, callbackURL: callbackURL) { result in
                Task { @MainActor in
                    await finishOAuth(result: result, redirectURI: callbackURL)
                }
            }
        } catch {
            NotificationCenter.default.post(
                name: .schwabConnectionFailed,
                object: nil,
                userInfo: ["message": error.localizedDescription]
            )
            debug("action=debug_route_failed error=\(error.localizedDescription)")
        }
    }

    @MainActor
    private static func finishOAuth(result: Result<URL, Error>, redirectURI: String) async {
        switch result {
        case .success(let callbackURL):
            guard let code = SchwabService.shared.authorizationCode(from: callbackURL.absoluteString) else {
                NotificationCenter.default.post(
                    name: .schwabConnectionFailed,
                    object: nil,
                    userInfo: ["message": "Schwab callback arrived without an authorization code."]
                )
                return
            }

            do {
                let token = try await SchwabService.shared.exchangeCodeForToken(code, redirectURI: redirectURI)
                AppConfig.apiKey = token
                MarketDataRegistry.shared.use(.schwab)
                LiveTapeService.shared.isEnabled = true
                await LiveTapeService.shared.tickNow()
                NotificationCenter.default.post(name: .schwabConnectionComplete, object: nil)
            } catch {
                NotificationCenter.default.post(
                    name: .schwabConnectionFailed,
                    object: nil,
                    userInfo: ["message": error.localizedDescription]
                )
            }
        case .failure(let error):
            NotificationCenter.default.post(
                name: .schwabConnectionFailed,
                object: nil,
                userInfo: ["message": error.localizedDescription]
            )
        }
    }

    private static func debug(_ summary: String) {
        logger.notice("\(summary, privacy: .public)")
        print("SCHWAB_OAUTH_DEBUG \(summary)")
    }
}
#endif

#if os(macOS)
enum MacWindowStateRepair {
    private static let minimumDeskSize = CGSize(width: 1180, height: 720)

    static func repairPersistedStateIfNeeded(defaults: UserDefaults = .standard) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "app.mdrn.steel"
        var domain = defaults.persistentDomain(forName: bundleIdentifier) ?? [:]
        let repairedKeys = domain.compactMap { key, value -> String? in
            guard isDeskWindowStateKey(key) else {
                return nil
            }

            if key.hasPrefix("NSSplitView Subview Frames ") {
                return key
            }
            if key.hasPrefix("NSWindow Frame "), isBrokenWindowFrame(value) {
                return key
            }
            return nil
        }

        for key in repairedKeys {
            domain.removeValue(forKey: key)
        }

        guard !repairedKeys.isEmpty else { return }
        defaults.setPersistentDomain(domain, forName: bundleIdentifier)
        defaults.synchronize()

        #if DEBUG
        let summary = repairedKeys.map { $0.replacingOccurrences(of: "\n", with: " ") }.joined(separator: " | ")
        print("MAC_WINDOW_REPAIR removed \(repairedKeys.count) stale frame key(s): \(summary)")
        #endif
    }

    private static func isDeskWindowStateKey(_ key: String) -> Bool {
        let isFrameState = key.hasPrefix("NSWindow Frame ") ||
            key.hasPrefix("NSSplitView Subview Frames ")
        let isSteelWindow = key.contains("Steel_Trading_Desk") ||
            key.contains("SidebarNavigationView") ||
            key.contains("AppWindow")
        return isFrameState && isSteelWindow
    }

    private static func isBrokenWindowFrame(_ value: Any) -> Bool {
        guard let string = value as? String,
              let rect = rect(from: string) else {
            return false
        }
        return rect.width < minimumDeskSize.width ||
            rect.height < minimumDeskSize.height ||
            rect.minX < 0 ||
            rect.minY < 0
    }

    private static func rect(from value: String) -> CGRect? {
        let tokens = value.split { character in
            !(character.isNumber || character == "." || character == "-")
        }
        let numbers = tokens.compactMap { Double($0) }
        guard numbers.count >= 4 else { return nil }
        return CGRect(
            x: numbers[0],
            y: numbers[1],
            width: numbers[2],
            height: numbers[3]
        )
    }
}

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

    func applicationWillTerminate(_ notification: Notification) {
        MacWindowStateRepair.repairPersistedStateIfNeeded()
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
        [0.05, 0.25, 0.75, 1.5, 2.5].forEach { delay in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                MacWindowStateRepair.repairPersistedStateIfNeeded()
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
    #if DEBUG
    static let debugOpenSettings = Notification.Name("debugOpenSettings")
    #endif
}
