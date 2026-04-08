import SwiftUI

struct SettingsView: View {
    @AppStorage("schwabApiKey") private var apiKey = ""
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @AppStorage("alertVolume") private var alertVolume: Double = 0.7 // Default 70%
    @AppStorage(AppConfig.CloseManagement.generalWarningKey) private var generalWarningTime = AppConfig.CloseManagement.defaultGeneralWarning
    @AppStorage(AppConfig.CloseManagement.generalHardExitKey) private var generalHardExitTime = AppConfig.CloseManagement.defaultGeneralHardExit
    @AppStorage(AppConfig.CloseManagement.institutionalWarningKey) private var institutionalWarningTime = AppConfig.CloseManagement.defaultInstitutionalWarning
    @AppStorage(AppConfig.CloseManagement.institutionalHardExitKey) private var institutionalHardExitTime = AppConfig.CloseManagement.defaultInstitutionalHardExit
    @StateObject private var connectionManager = SchwabService.shared
    @StateObject private var notifications = SignalNotification.shared
    
    var body: some View {
        Form {
            Section("Playtest Readiness") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trading Test")
                        Text(AppConfig.Testing.nextTradingTestDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(notifications.isPermissionGranted ? "Alerts Ready" : notifications.permissionStatusText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(notifications.isPermissionGranted ? .green : .orange)
                }

                Button(notifications.isPermissionGranted ? "Refresh Alert Status" : "Enable Alerts") {
                    Task {
                        if notifications.isPermissionGranted {
                            await notifications.refreshAuthorizationStatus()
                        } else {
                            await notifications.requestPermissions()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Text("This keeps the launch flow simple before a playtest: notification status, background monitoring, and close timing are all visible in one place.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Schwab API Configuration") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Button(connectionManager.isConnected ? "Disconnect" : "Connect") {
                    Task {
                        if connectionManager.isConnected {
                            // Disconnect logic
                        } else {
                            try? await connectionManager.streamQuotes(symbols: [])
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
                HStack {
                    Text("Notification Status")
                    Spacer()
                    Text(notifications.permissionStatusText)
                        .foregroundColor(notifications.isPermissionGranted ? .green : .secondary)
                }
                
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

            Section("Close Management") {
                DatePicker("General First Warning", selection: timeBinding(for: $generalWarningTime, defaultValue: AppConfig.CloseManagement.defaultGeneralWarning), displayedComponents: .hourAndMinute)
                DatePicker("General Hard Exit", selection: timeBinding(for: $generalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultGeneralHardExit), displayedComponents: .hourAndMinute)
                DatePicker("Institutional Warning", selection: timeBinding(for: $institutionalWarningTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalWarning), displayedComponents: .hourAndMinute)
                DatePicker("Institutional Hard Exit", selection: timeBinding(for: $institutionalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalHardExit), displayedComponents: .hourAndMinute)

                Text("SPY and most VXX setups use the general timing. VXX institutional flow keeps its own extended warning and hard-exit window.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Trading Hours") {
                VStack(alignment: .leading) {
                    Text("Market Open: 9:30 AM ET")
                    Text("Market Close: 4:00 PM ET")
                    Text("Extended monitoring can continue beyond the cash close based on your exit settings above.")
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400)
        .task {
            await notifications.refreshAuthorizationStatus()
        }
    }

    private func timeBinding(for timeString: Binding<String>, defaultValue: String) -> Binding<Date> {
        Binding(
            get: {
                AppConfig.CloseManagement.date(from: timeString.wrappedValue)
                ?? AppConfig.CloseManagement.date(from: defaultValue)
                ?? Date()
            },
            set: { newValue in
                timeString.wrappedValue = AppConfig.CloseManagement.storageTime(from: newValue)
            }
        )
    }
}
