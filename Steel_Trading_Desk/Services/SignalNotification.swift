import Foundation
import UserNotifications
import AVFoundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum NotificationError: Error {
    case soundFileNotFound
    case soundLoadError
    case permissionDenied
}

@MainActor
final class SignalNotification: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = SignalNotification()
    @Published private(set) var isPermissionGranted = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var permissionStatusText = "Not Enabled"
    @Published private(set) var lastError: NotificationError?
    
    private var soundPlayer: AVAudioPlayer?
    
    private static let categoryIdentifier = "STEEL_DESK"
    private static let openDeskActionIdentifier = "OPEN_DESK"

    private override init() {
        super.init()
    }

    var isPermissionDenied: Bool {
        authorizationStatus == .denied
    }

    var permissionActionTitle: String {
        if isPermissionGranted { return "Refresh" }
        if isPermissionDenied { return "Settings" }
        return "Enable"
    }

    func requestPermissions() async {
        do {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            registerCategories()
            await refreshAuthorizationStatus()
        } catch {
            lastError = .permissionDenied
            #if DEBUG
            print("Notification permission error: \(error)")
            #endif
        }
    }

    func handlePermissionAction() async {
        await refreshAuthorizationStatus()

        if isPermissionGranted {
            return
        }

        if isPermissionDenied {
            openSystemNotificationSettings()
            return
        }

        await requestPermissions()
    }

    func prepareForLaunch() async {
        UNUserNotificationCenter.current().delegate = self
        await refreshAuthorizationStatus()
        registerCategories()
    }

    private func registerCategories() {
        let openDesk = UNNotificationAction(
            identifier: Self.openDeskActionIdentifier,
            title: "Open Desk",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [openDesk],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        updateAuthorizationState(settings.authorizationStatus)
    }
    
    func signalDetected(_ signal: Signal) {
        guard isPermissionGranted else { return }
        
        // Play sound with error handling
        do {
            try playAlertSound()
        } catch NotificationError.soundFileNotFound {
            #if DEBUG
            print("Alert sound file not found")
            #endif
        } catch {
            #if DEBUG
            print("Sound playback error: \(error)")
            #endif
        }
        
        // Show notification
        let content = createNotificationContent(for: signal)
        scheduleNotification(content)
    }

    func exitDetected(_ exitSignal: ExitSignal) {
        guard isPermissionGranted else { return }

        do {
            try playAlertSound()
        } catch {
            #if DEBUG
            print("Exit sound playback error: \(error)")
            #endif
        }

        let content = UNMutableNotificationContent()
        content.title = "\(exitSignal.symbol) · CLOSE IT"
        content.subtitle = exitSignal.action.displayName.uppercased()
        content.body = "PRICE $\(String(format: "%.2f", exitSignal.exitPrice)) · \(exitSignal.exitReason.displayName.uppercased())"
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        scheduleNotification(content)
    }

    private func createNotificationContent(for signal: Signal) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(signal.symbol) · \(directiveTitle(for: signal))"
        content.subtitle = "\(signal.strategy.rawValue.uppercased()) · \(signal.direction.optionLabel.uppercased())"
        content.body = formatSignalBody(signal)
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        return content
    }

    func sendTestNotification() {
        guard isPermissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "STEEL DESK · TEST ALERT"
        content.subtitle = "ALERT PATH READY"
        content.body = "If you see this, phone alerts are live."
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        scheduleNotification(content, trigger: trigger)
    }

    private func directiveTitle(for signal: Signal) -> String {
        switch signal.kind {
        case .entry: return "GO CHECK THE TAPE"
        case .watch: return "WATCH"
        case .exit:  return "CLOSE IT"
        }
    }

    private func formatSignalBody(_ signal: Signal) -> String {
        let ratioText = signal.vxxVixRatio > 0 ? String(format: "R %.2f", signal.vxxVixRatio) : nil
        let vixText = signal.vix > 0 ? String(format: "VIX %.1f", signal.vix) : nil
        let entryText = String(format: "ENTRY $%.2f", signal.entry)
        let stopText = String(format: "STOP $%.2f", signal.stop)
        let targetText = String(format: "TGT $%.2f", signal.target)

        return [ratioText, vixText, entryText, stopText, targetText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
    
    private func playAlertSound() throws {
        guard let soundURL = Bundle.main.url(forResource: "signal_alert", withExtension: "wav") else {
            throw NotificationError.soundFileNotFound
        }
        
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundPlayer?.volume = Float(UserDefaults.standard.double(forKey: "alertVolume"))
            soundPlayer?.play()
        } catch {
            throw NotificationError.soundLoadError
        }
    }
    
    private func scheduleNotification(_ content: UNMutableNotificationContent, trigger: UNNotificationTrigger? = nil) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Notification scheduling error: \(error)")
                #endif
            }
        }
        
        // Update widget
        // Widgets removed for v3.0
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
    
    func playTestSound() {
        do {
            try playAlertSound()
        } catch {
            #if DEBUG
            print("Test sound error: \(error)")
            #endif
        }
    }

    func openSystemNotificationSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #elseif os(macOS)
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let settingsURLs = [
            URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleIdentifier)"),
            URL(string: "x-apple.systempreferences:com.apple.preference.notifications"),
            URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        ].compactMap { $0 }

        for url in settingsURLs where NSWorkspace.shared.open(url) {
            return
        }
        #endif
    }

    private func updateAuthorizationState(_ status: UNAuthorizationStatus) {
        authorizationStatus = status

        switch status {
        case .authorized, .provisional, .ephemeral:
            isPermissionGranted = true
            permissionStatusText = "Enabled"
        case .denied:
            isPermissionGranted = false
            permissionStatusText = "Denied"
        case .notDetermined:
            isPermissionGranted = false
            permissionStatusText = "Not Enabled"
        @unknown default:
            isPermissionGranted = false
            permissionStatusText = "Unknown"
        }
    }
} 
