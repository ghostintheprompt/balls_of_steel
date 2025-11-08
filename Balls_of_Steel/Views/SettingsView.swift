import SwiftUI

struct SettingsView: View {
    @AppStorage("schwabApiKey") private var apiKey = ""
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @AppStorage("alertVolume") private var alertVolume: Double = 0.7 // Default 70%
    @StateObject private var connectionManager = SchwabService.shared
    
    var body: some View {
        Form {
            Section("Schwab API Configuration") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Button(connectionManager.isConnected ? "Disconnect" : "Connect") {
                    Task {
                        if connectionManager.isConnected {
                            // Disconnect logic
                        } else {
                            try? await connectionManager.streamQuotes([])
                        }
                    }
                }
                .disabled(apiKey.isEmpty)
                
                // Connection status indicator
                HStack {
                    Circle()
                        .fill(connectionManager.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(connectionManager.isConnected ? "Connected" : "Disconnected")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Monitoring") {
                Toggle("Background Monitoring", isOn: $isBackgroundMonitoringEnabled)
                Text("Monitors for signals even when app is in background")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Notifications") {
                Toggle("Background Monitoring", isOn: $isBackgroundMonitoringEnabled)
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Alert Volume")
                    }
                    HStack {
                        Slider(value: $alertVolume)
                        Button("Test") {
                            SignalNotification.shared.playTestSound()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Section("Trading Hours") {
                VStack(alignment: .leading) {
                    Text("Market Open: 9:30 AM ET")
                    Text("Market Close: 4:00 PM ET")
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400)
    }
} 