import Foundation
import UserNotifications  // For UNMutableNotificationContent

class NotificationService {
    func alert(signal: Signal) {
        let content = UNMutableNotificationContent()
        content.title = "\(signal.strategy.rawValue): \(signal.symbol)"
        content.body = "Entry: $\(String(format: "%.2f", signal.entry)) | Target: $\(String(format: "%.2f", signal.target))"
        content.sound = .default
        
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString,
                                content: content, 
                                trigger: nil)
        )
    }
} 