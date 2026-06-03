import SwiftUI

struct SettingsView: View {
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @AppStorage("alertVolume") private var alertVolume: Double = 0.7 // Default 70%
    @AppStorage(AppConfig.CloseManagement.generalWarningKey) private var generalWarningTime = AppConfig.CloseManagement.defaultGeneralWarning
    @AppStorage(AppConfig.CloseManagement.generalHardExitKey) private var generalHardExitTime = AppConfig.CloseManagement.defaultGeneralHardExit
    @AppStorage(AppConfig.CloseManagement.institutionalWarningKey) private var institutionalWarningTime = AppConfig.CloseManagement.defaultInstitutionalWarning
    @AppStorage(AppConfig.CloseManagement.institutionalHardExitKey) private var institutionalHardExitTime = AppConfig.CloseManagement.defaultInstitutionalHardExit
    @StateObject private var notifications = SignalNotification.shared
    @State private var isAuditSheetOpen: Bool = false
    @State private var schwabAppKeyInput: String = ""
    @State private var schwabAppSecretInput: String = ""
    @State private var schwabCredentialStatus: String = ""

    var body: some View {
        ZStack {
            TradingBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsHeader
                    accessCard
                    playtestCard
                    dataSourceCard
                    schwabDeveloperCredentialsCard
                    strategyAuditCard
                    brokerCard
                    monitoringCard
                    notificationsCard
                    closeManagementCard
                    hoursCard
                }
                .padding(DesignSystem.spacing)
            }
        }
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .onAppear {
            refreshSchwabCredentialStatus()
        }
        .sheet(isPresented: $isAuditSheetOpen) {
            StrategyAuditView()
        }
    }

    private var schwabDeveloperCredentialsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("SCHWAB DEVELOPER ACCESS")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.warningColor)

                Text("For traders with their own Schwab developer account. Enter two values: app key and app secret. Steel stores them in this device's Keychain, ships with no shared Schwab secret, and never places orders.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.text2)
                    .fixedSize(horizontal: false, vertical: true)

                SecureField("Schwab app key / client ID", text: $schwabAppKeyInput)
                    .textFieldStyle(.roundedBorder)

                SecureField("Schwab app secret", text: $schwabAppSecretInput)
                    .textFieldStyle(.roundedBorder)

                if !schwabCredentialStatus.isEmpty {
                    Text(schwabCredentialStatus)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }

                HStack(spacing: 10) {
                    Button("Save To Keychain") {
                        saveSchwabDeveloperCredentials()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(schwabAppKeyInput.isEmpty && schwabAppSecretInput.isEmpty)

                    Button("Clear") {
                        clearSchwabDeveloperCredentials()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func refreshSchwabCredentialStatus() {
        let hasKey = !AppConfig.Schwab.appKey.isEmpty
        let hasSecret = !AppConfig.Schwab.appSecret.isEmpty

        switch (hasKey, hasSecret) {
        case (true, true):
            schwabCredentialStatus = "Stored in Keychain: app key + app secret."
        case (true, false):
            schwabCredentialStatus = "Stored in Keychain: app key only."
        case (false, true):
            schwabCredentialStatus = "Stored in Keychain: app secret only."
        case (false, false):
            schwabCredentialStatus = "No Schwab developer credentials stored on this device."
        }
    }

    private func saveSchwabDeveloperCredentials() {
        let appKey = schwabAppKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let appSecret = schwabAppSecretInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if !appKey.isEmpty {
            AppConfig.Schwab.appKey = appKey
        }

        if !appSecret.isEmpty {
            AppConfig.Schwab.appSecret = appSecret
        }

        schwabAppKeyInput = ""
        schwabAppSecretInput = ""
        refreshSchwabCredentialStatus()
    }

    private func clearSchwabDeveloperCredentials() {
        AppConfig.Schwab.appKey = ""
        AppConfig.Schwab.appSecret = ""
        KeychainService.delete(key: AppConfig.Schwab.accessTokenKeychainKey)
        KeychainService.delete(key: AppConfig.Schwab.refreshTokenKeychainKey)
        schwabAppKeyInput = ""
        schwabAppSecretInput = ""
        refreshSchwabCredentialStatus()
    }

    private var strategyAuditCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("STRATEGY AUDIT")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.amber)

                Text("Verifies code thresholds, time windows, exits, pattern criteria, and sizing against the strategy doc. Run it after any code change that touches the system.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.text2)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    isAuditSheetOpen = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield")
                        Text("RUN AUDIT")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.6)
                    }
                    .foregroundColor(DesignSystem.bg)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DesignSystem.amber)
                    .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dataSourceCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("DATA SOURCE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.4)
                    .foregroundColor(DesignSystem.amber)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MANUAL ENTRY — FALLBACK")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(DesignSystem.text)
                    Text("The desk runs on what you enter right now. Same gates, same alerts, same discipline. This is the bridge — not the destination.")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().background(DesignSystem.hairline)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        DeskPulseDot(accent: DesignSystem.amber, size: 6)
                        Text("LIVE FEED — RESTORING")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1.4)
                            .foregroundColor(DesignSystem.amber)
                    }
                    Text("Real-time VXX + VIX through your own Schwab account. No third-party middlemen, no paywalled endpoints, no faked feeds. Coming back online when the integration lands.")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
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
                Text("BROKER")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1)
                    .foregroundColor(DesignSystem.mutedText)

                HStack(spacing: 8) {
                    Circle()
                        .fill(DesignSystem.amber)
                        .frame(width: 8, height: 8)
                    Text("SCHWAB — INTEGRATION PENDING")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(DesignSystem.amber)
                }

                Text("Trade execution stays on your platform — ThinkOrSwim, Schwab, whatever you already use. The desk fires the read; you fire the order. Live quote feed and one-click broker handoff land alongside the Schwab Trader API wire-up.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var accessCard: some View {
        InfoCard(glow: .clear) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACCESS")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(DesignSystem.mutedText)
                    Text("FREE. FULL DESK.")
                        .font(DesignSystem.Typography.titleFont)
                        .fontWeight(.black)
                        .foregroundColor(DesignSystem.primaryText)
                    Text("No paywall. No system pitch. One job: keep the VXX/VIX/VWAP decision honest.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

// MARK: - Strategy Audit Sheet
//
// One-button "is the code still doing what the strategy doc says?" check.
// Runs StrategyAuditor (which compares StrategySpec + a battery of runtime
// probes against the canonical doc values) and renders a categorised result
// list. Failures land at the top.

struct StrategyAuditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var results: [AuditResult] = []
    @State private var lastRunAt: Date?

    var body: some View {
        VStack(spacing: 0) {
            header
            if results.isEmpty {
                emptyState
            } else {
                summaryBanner
                resultsList
            }
        }
        .background(DesignSystem.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await runAudit() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("STRATEGY AUDIT")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("CODE vs docs/trading docs/")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.text)
            }
            Spacer()
            Button {
                Task { await runAudit() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.text)
                    .padding(8)
                    .background(DesignSystem.bg1)
                    .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.text2)
                    .padding(8)
                    .background(DesignSystem.bg1)
                    .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            ProgressView().tint(DesignSystem.amber)
            Text("RUNNING AUDIT")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summaryBanner: some View {
        let summary = AuditSummary(results: results)
        return HStack(spacing: 0) {
            summaryTile(value: "\(summary.passes)", label: "PASS", color: DesignSystem.long)
            divider
            summaryTile(value: "\(summary.failures)", label: "FAIL", color: summary.failures > 0 ? DesignSystem.short : DesignSystem.muted)
            divider
            summaryTile(value: "\(summary.warnings)", label: "WARN", color: summary.warnings > 0 ? DesignSystem.amber : DesignSystem.muted)
            divider
            summaryTile(value: "\(summary.total)", label: "TOTAL", color: DesignSystem.text2)
        }
        .background(DesignSystem.bg1)
        .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
        .padding(.horizontal, 12)
    }

    private func summaryTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(color)
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var divider: some View {
        Rectangle().fill(DesignSystem.hairline).frame(width: 1, height: 36)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let when = lastRunAt {
                    Text("LAST RUN · \(Self.timestampFormatter.string(from: when))")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.2)
                        .foregroundColor(DesignSystem.faint)
                        .padding(.horizontal, 16)
                }

                ForEach(AuditCategory.allCases, id: \.self) { category in
                    let inCategory = results.filter { $0.category == category }
                    if !inCategory.isEmpty {
                        section(title: category.rawValue, rows: inCategory)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func section(title: String, rows: [AuditResult]) -> some View {
        let failuresFirst = rows.sorted { a, b in
            statusRank(a.status) < statusRank(b.status)
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.8)
                .foregroundColor(DesignSystem.amber)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(failuresFirst) { row in
                    AuditRow(result: row)
                    Rectangle().fill(DesignSystem.hairline).frame(height: 1)
                }
            }
            .background(DesignSystem.bg1)
            .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
            .padding(.horizontal, 12)
        }
    }

    private func statusRank(_ s: AuditStatus) -> Int {
        switch s {
        case .fail:    return 0
        case .warning: return 1
        case .pass:    return 2
        }
    }

    @MainActor
    private func runAudit() async {
        results = StrategyAuditor.run()
        lastRunAt = Date()
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd · HH:mm:ss zzz"
        f.timeZone = TimeZone(identifier: "America/New_York")
        return f
    }()
}

private struct AuditRow: View {
    let result: AuditResult

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            statusBadge
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.text)
                HStack(spacing: 6) {
                    Text("DOC")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.0)
                        .foregroundColor(DesignSystem.faint)
                    Text(result.expected)
                        .font(DesignSystem.Typography.labelFont)
                        .foregroundColor(DesignSystem.text2)
                    Text("→")
                        .font(DesignSystem.Typography.labelFont)
                        .foregroundColor(DesignSystem.faint)
                    Text("CODE")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(1.0)
                        .foregroundColor(DesignSystem.faint)
                    Text(result.actual)
                        .font(DesignSystem.Typography.labelFont)
                        .foregroundColor(actualColor)
                }
                Text(result.docSource)
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.0)
                    .foregroundColor(DesignSystem.faint)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var statusBadge: some View {
        Image(systemName: iconName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(badgeColor)
            .frame(width: 22, height: 22)
            .background(DesignSystem.bg)
            .overlay(Rectangle().stroke(DesignSystem.hairline, lineWidth: 1))
    }

    private var iconName: String {
        switch result.status {
        case .pass:    return "checkmark"
        case .fail:    return "xmark"
        case .warning: return "exclamationmark"
        }
    }

    private var badgeColor: Color {
        switch result.status {
        case .pass:    return DesignSystem.long
        case .fail:    return DesignSystem.short
        case .warning: return DesignSystem.amber
        }
    }

    private var actualColor: Color {
        switch result.status {
        case .pass:    return DesignSystem.long
        case .fail:    return DesignSystem.short
        case .warning: return DesignSystem.amber
        }
    }
}
