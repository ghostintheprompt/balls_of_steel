import Foundation
import UserNotifications
import AVFoundation
import AppKit

enum NotificationError: Error {
    case soundFileNotFound
    case soundLoadError
    case permissionDenied
}

@MainActor
class SignalNotification: ObservableObject {
    static let shared = SignalNotification()
    @Published private(set) var isPermissionGranted = false
    @Published private(set) var lastError: NotificationError?
    
    private var soundPlayer: AVAudioPlayer?
    
    func requestPermissions() async {
        do {
            let center = UNUserNotificationCenter.current()
            isPermissionGranted = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            lastError = .permissionDenied
            #if DEBUG
            print("Notification permission error: \(error)")
            #endif
        }
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
    
    private func createNotificationContent(for signal: Signal) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Trading Signal: \(signal.symbol)"
        content.subtitle = signal.strategy.rawValue
        content.body = formatSignalDetails(signal)
        content.sound = .default
        return content
    }
    
    private func formatSignalDetails(_ signal: Signal) -> String {
        """
        Entry: $\(String(format: "%.2f", signal.entry))
        Target: $\(String(format: "%.2f", signal.target))
        Stop: $\(String(format: "%.2f", signal.stop))
        """
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
} 