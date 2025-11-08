import SwiftUI

class Settings: ObservableObject {
    static let shared = Settings()
    private let defaults = UserDefaults.standard
    
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    
    @Published var patternSensitivity: Double {
        didSet { defaults.set(patternSensitivity, forKey: "patternSensitivity") }
    }
    
    init() {
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        self.patternSensitivity = defaults.double(forKey: "patternSensitivity")
    }
} 