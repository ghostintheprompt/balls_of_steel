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
        // DEBUG-only: seed Keychain from bundled .env if present.
        // No-op in Release builds.
        EnvSeeder.seedFromBundleEnvIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .task {
                    // 3s delay before silent check on launch
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await updateChecker.checkForUpdates(silent: true)
                }
        }
        #if os(macOS)
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
