import Foundation
import UserNotifications  // For UNMutableNotificationContent

class NotificationService {
    func alert(signal: Signal) {
        let content = UNMutableNotificationContent()
        content.title = "\(signal.kind.displayName) \(signal.symbol) - \(signal.direction.optionLabel)"
        content.subtitle = signal.strategy.rawValue
        content.body = "Entry: $\(String(format: "%.2f", signal.entry)) | Target: $\(String(format: "%.2f", signal.target)) | Stop: $\(String(format: "%.2f", signal.stop))"
        content.sound = .default
        
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString,
                                content: content, 
                                trigger: nil)
        )
    }
} 
