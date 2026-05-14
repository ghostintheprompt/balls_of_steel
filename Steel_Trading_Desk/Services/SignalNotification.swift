import Foundation
import UserNotifications
import AVFoundation

enum NotificationError: Error {
    case soundFileNotFound
    case soundLoadError
    case permissionDenied
}

@MainActor
class SignalNotification: ObservableObject {
    static let shared = SignalNotification()
    @Published private(set) var isPermissionGranted = false
    @Published private(set) var permissionStatusText = "Not Enabled"
    @Published private(set) var lastError: NotificationError?
    
    private var soundPlayer: AVAudioPlayer?
    
    private static let categoryIdentifier = "STEEL_DESK"
    private static let openDeskActionIdentifier = "OPEN_DESK"

    func requestPermissions() async {
        do {
            let center = UNUserNotificationCenter.current()
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

    func prepareForLaunch() async {
        await refreshAuthorizationStatus()
        registerCategories()

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            await requestPermissions()
        }
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
    
    private func scheduleNotification(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
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
    
    func playTestSound() {
        do {
            try playAlertSound()
        } catch {
            #if DEBUG
            print("Test sound error: \(error)")
            #endif
        }
    }

    private func updateAuthorizationState(_ status: UNAuthorizationStatus) {
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
