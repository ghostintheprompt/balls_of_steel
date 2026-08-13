import SwiftUI
#if os(macOS)
import AppKit
#endif
import Foundation

@main
struct MainApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    @StateObject private var updateChecker = UpdateChecker.shared

    init() {
        // DEBUG-only: seed Keychain from Xcode scheme environment values.
        // No-op in Release builds.
        EnvSeeder.seedFromDebugEnvironmentIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MainView()
                .frame(minWidth: 1180, minHeight: 720)
                .onOpenURL { url in
                    SchwabOAuthCallbackHandler.handle(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    SchwabOAuthCallbackHandler.handle(userActivity)
                }
            #else
            MainView()
                .onOpenURL { url in
                    SchwabOAuthCallbackHandler.handle(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    SchwabOAuthCallbackHandler.handle(userActivity)
                }
                .task {
                    await SignalNotification.shared.prepareForLaunch()
                }
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 1440, height: 860)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    Task {
                        await updateChecker.checkForUpdates(silent: false)
                    }
                }
            }
        }
        #endif
    }
}
