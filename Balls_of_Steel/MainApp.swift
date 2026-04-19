import SwiftUI
import AppKit
import Foundation

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .task {
                    // 3s delay before silent check on launch
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await updateChecker.checkForUpdates(silent: true)
                }
        }
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
    }
}
