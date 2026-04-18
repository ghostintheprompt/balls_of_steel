import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Arcade Energy Service
// Selective haptic feedback at key moments
// Conservative approach - not annoying, just professional with energy
// Toggleable in settings

@MainActor
class ArcadeEnergyService: ObservableObject {
    static let shared = ArcadeEnergyService()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "arcadeEnergyEnabled")
        }
    }

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "arcadeEnergyEnabled")
        // Default to enabled on first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            isEnabled = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }

    // MARK: - Key Moments

    /// Institutional Flow Window Alert (3:45-4:10 PM)
    /// The supreme window - deserves maximum energy
    func institutionalFlowAlert() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        // Double tap for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.notificationOccurred(.success)
        }
        #endif
        #if DEBUG
        print("INSTITUTIONAL FLOW ALERT")
        #endif
    }

    /// Strong signal validated (Arrow + Volume 200%+ + Time Window + Confluence)
    /// Full conviction trade - celebrate the setup
    func strongSignalValidated() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
        #if DEBUG
        print("STRONG SIGNAL")
        #endif
    }

    /// Volume hits institutional threshold (300%+)
    /// Follow the money - this is important
    func institutionalVolumeDetected() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
        #if DEBUG
        print("INSTITUTIONAL VOLUME")
        #endif
    }

    /// Manual data entry saved
    /// Light confirmation - data is locked in
    func dataSaved() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        #if DEBUG
        print("DATA SAVED")
        #endif
    }

    /// Unlock successful
    /// Welcome to the full system
    func unlockSuccessful() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        #if DEBUG
        print("UNLOCKED")
        #endif
    }

    /// Purchase started
    /// Acknowledgment that action was received
    func purchaseStarted() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    /// Button tap (subtle)
    /// General interaction feedback
    func buttonTap() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
        #endif
    }

    /// Window opening alert
    /// Time window is active - pay attention
    func windowOpening(window: String) {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
        #if DEBUG
        print("WINDOW OPENING: \(window)")
        #endif
    }

    /// Error occurred
    /// Something went wrong
    func error() {
        guard isEnabled else { return }
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    // MARK: - Settings

    func toggle() {
        isEnabled.toggle()
    }

    func disable() {
        isEnabled = false
    }

    func enable() {
        isEnabled = true
    }
}

// MARK: - View Extensions for Easy Integration
extension View {
    /// Add haptic feedback to button tap
    func withHapticFeedback() -> some View {
        self.onTapGesture {
            ArcadeEnergyService.shared.buttonTap()
        }
    }
}

// MARK: - Arcade Energy Settings View
struct ArcadeEnergySettingsView: View {
    @StateObject private var arcadeService = ArcadeEnergyService.shared

    var body: some View {
        Form {
            Section {
                Toggle("Haptic Feedback", isOn: $arcadeService.isEnabled)
            } header: {
                Text("Arcade Energy")
            } footer: {
                Text("Haptic feedback at key moments: institutional flow alerts, strong signals, volume surges. Professional with energy.")
            }

            if arcadeService.isEnabled {
                Section("Test Haptics") {
                    Button("Test Strong Signal") {
                        arcadeService.strongSignalValidated()
                    }
                    Button("Test Institutional Flow") {
                        arcadeService.institutionalFlowAlert()
                    }
                    Button("Test Volume Surge") {
                        arcadeService.institutionalVolumeDetected()
                    }
                }
            }
        }
        .navigationTitle("Arcade Energy")
    }
}

// MARK: - Preview
#Preview {
    ArcadeEnergySettingsView()
}
