import SwiftUI

struct SettingsView: View {
    @State private var apiKey = AppConfig.apiKey
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @AppStorage("alertVolume") private var alertVolume: Double = 0.7 // Default 70%
    @AppStorage(AppConfig.CloseManagement.generalWarningKey) private var generalWarningTime = AppConfig.CloseManagement.defaultGeneralWarning
    @AppStorage(AppConfig.CloseManagement.generalHardExitKey) private var generalHardExitTime = AppConfig.CloseManagement.defaultGeneralHardExit
    @AppStorage(AppConfig.CloseManagement.institutionalWarningKey) private var institutionalWarningTime = AppConfig.CloseManagement.defaultInstitutionalWarning
    @AppStorage(AppConfig.CloseManagement.institutionalHardExitKey) private var institutionalHardExitTime = AppConfig.CloseManagement.defaultInstitutionalHardExit
    @StateObject private var connectionManager = SchwabService.shared
    @StateObject private var notifications = SignalNotification.shared
    
    var body: some View {
        ZStack {
            TradingBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsHeader
                    playtestCard
                    brokerCard
                    monitoringCard
                    notificationsCard
                    closeManagementCard
                    hoursCard
                }
                .padding(20)
            }
        }
        .task {
            await notifications.refreshAuthorizationStatus()
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETTINGS")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)
            Text("Keep the launch clean.")
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(DesignSystem.primaryText)
            Text("This is the quiet side of the desk: alert readiness, monitoring, close timing, and the broker placeholder.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.10))
    }

    private var playtestCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PLAYTEST READINESS")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1)
                            .foregroundColor(DesignSystem.mutedText)
                        Text(AppConfig.Testing.nextTradingTestDate)
                            .font(DesignSystem.Typography.headlineFont)
                            .foregroundColor(DesignSystem.primaryText)
                    }
                    Spacer()
                    DeskCountBadge(
                        value: notifications.isPermissionGranted ? "ALERTS READY" : notifications.permissionStatusText.uppercased(),
                        accent: notifications.isPermissionGranted ? DesignSystem.bullishColor : DesignSystem.warningColor
                    )
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
            }
        }
    }

    private var brokerCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("BROKER PLACEHOLDER")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)

                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: apiKey) { AppConfig.apiKey = $0 }

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

                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionManager.isConnected ? DesignSystem.bullishColor : DesignSystem.bearishColor)
                        .frame(width: 8, height: 8)
                    Text(connectionManager.isConnected ? "Connected" : "Disconnected")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }

                Text("Still manual-first. The field stays here so the workflow is ready when the live broker path comes back.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
        }
    }

    private var monitoringCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("MONITORING")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)

                Toggle("Background Monitoring", isOn: $isBackgroundMonitoringEnabled)

                Text("Leave this on if you want the desk to keep watching while you are doing other things.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
        }
    }

    private var notificationsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ALERTS")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1)
                        .foregroundColor(DesignSystem.mutedText)
                    Spacer()
                    Text(notifications.permissionStatusText)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(notifications.isPermissionGranted ? DesignSystem.bullishColor : DesignSystem.warningColor)
                }

                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(DesignSystem.primaryColor)
                    Text("Alert Volume")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.primaryText)
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
    }

    private var closeManagementCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("CLOSE MANAGEMENT")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)

                DatePicker("General First Warning", selection: timeBinding(for: $generalWarningTime, defaultValue: AppConfig.CloseManagement.defaultGeneralWarning), displayedComponents: .hourAndMinute)
                DatePicker("General Hard Exit", selection: timeBinding(for: $generalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultGeneralHardExit), displayedComponents: .hourAndMinute)
                DatePicker("Institutional Warning", selection: timeBinding(for: $institutionalWarningTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalWarning), displayedComponents: .hourAndMinute)
                DatePicker("Institutional Hard Exit", selection: timeBinding(for: $institutionalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalHardExit), displayedComponents: .hourAndMinute)

                Text("SPY and most VXX setups use the general timing. VXX institutional flow keeps its own extended warning and hard-exit window.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
        }
    }

    private var hoursCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("HOURS")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)
                VStack(alignment: .leading) {
                    Text("Market Open: 9:30 AM ET")
                    Text("Market Close: 4:00 PM ET")
                    Text("Extended monitoring can continue beyond the cash close based on your exit settings above.")
                }
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
            }
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
