//
//  MainApp.swift
//  Balls_of_Steel
//
//  Created by GREEN PLANET on 11/18/24.
//

import SwiftUI
import AppKit
import Foundation

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
    }
}
