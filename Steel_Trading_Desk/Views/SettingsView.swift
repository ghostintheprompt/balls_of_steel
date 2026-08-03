import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
    @State private var isEditingSchwabCredentials: Bool = false
    @State private var schwabCredentialMessage: String?

    var body: some View {
        #if os(macOS)
        desktopSystemsPanel
        #else
        mobileSystemsPanel
        #endif
    }

    #if os(macOS)
    private var desktopSystemsPanel: some View {
        ZStack {
            TradingBackdrop()

            VStack(spacing: 0) {
                desktopSystemsHeader

                Rectangle()
                    .fill(DesignSystem.hairline)
                    .frame(height: 1)

                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 14) {
                        systemDataCard
                        compactSchwabCredentialsCard
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    VStack(spacing: 14) {
                        compactAlertsCard
                        compactCloseCard
                        compactAuditCard
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(14)
            }
        }
        .frame(minWidth: 820, idealWidth: 860, minHeight: 620, idealHeight: 640)
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .sheet(isPresented: $isAuditSheetOpen) {
            StrategyAuditView()
        }
    }
    #endif

    private var mobileSystemsPanel: some View {
        ZStack {
            TradingBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    mobileSystemsHeader
                    systemDataCard
                    compactSchwabCredentialsCard
                    compactAlertsCard
                    compactCloseCard
                    compactAuditCard
                }
                .padding(DesignSystem.spacing)
            }
        }
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .sheet(isPresented: $isAuditSheetOpen) {
            StrategyAuditView()
        }
    }

    private var desktopSystemsHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SYSTEMS")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("Trade Controls")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 12)

            SystemsStatusPill(
                title: "DATA",
                value: AppConfig.Schwab.hasOAuthTokens ? "SCHWAB" : "MANUAL",
                accent: AppConfig.Schwab.hasOAuthTokens ? DesignSystem.long : DesignSystem.amber
            )

            SystemsStatusPill(
                title: "ALERTS",
                value: notifications.isPermissionGranted ? "ON" : "OFF",
                accent: notifications.isPermissionGranted ? DesignSystem.long : DesignSystem.short
            )

            #if os(macOS)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(DesignSystem.primaryText)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(DesignSystem.bg1)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .stroke(DesignSystem.hairline, lineWidth: 1)
            )
            .keyboardShortcut(.cancelAction)
            .help("Close systems")
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.bg)
    }

    private var mobileSystemsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SYSTEMS")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("Trade Controls")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                SystemsStatusPill(
                    title: "DATA",
                    value: AppConfig.Schwab.hasOAuthTokens ? "SCHWAB" : "MANUAL",
                    accent: AppConfig.Schwab.hasOAuthTokens ? DesignSystem.long : DesignSystem.amber
                )

                SystemsStatusPill(
                    title: "ALERTS",
                    value: notifications.isPermissionGranted ? "ON" : "OFF",
                    accent: notifications.isPermissionGranted ? DesignSystem.long : DesignSystem.short
                )

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.bg)
    }

    private var systemDataCard: some View {
        SystemsPanel(title: "DATA") {
            VStack(spacing: 9) {
                SystemsReadoutRow(label: "Mode", value: "Manual tape", accent: DesignSystem.amber)
                SystemsReadoutRow(label: "Schwab keys", value: AppConfig.Schwab.hasDeveloperCredentials ? "Stored" : "Missing", accent: AppConfig.Schwab.hasDeveloperCredentials ? DesignSystem.long : DesignSystem.short)
                SystemsReadoutRow(label: "Live feed", value: AppConfig.Schwab.hasOAuthTokens ? "Token stored" : "Off", accent: AppConfig.Schwab.hasOAuthTokens ? DesignSystem.long : DesignSystem.mutedText)
                SystemsReadoutRow(label: "Execution", value: "Thinkorswim manual", accent: DesignSystem.mutedText)
            }
        }
    }

    private var compactSchwabCredentialsCard: some View {
        SystemsPanel(title: "SCHWAB") {
            VStack(alignment: .leading, spacing: 10) {
                if AppConfig.Schwab.hasDeveloperCredentials && !isEditingSchwabCredentials {
                    SystemsReadoutRow(label: "Status", value: compactSchwabStatus, accent: schwabStatusAccent)
                    Text("Stored in Keychain on this phone.")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button {
                            schwabCredentialMessage = nil
                            isEditingSchwabCredentials = true
                        } label: {
                            Label("Replace", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            clearSchwabDeveloperCredentials()
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(DesignSystem.short)
                    }
                } else {
                    credentialInputRow(
                        label: "App key",
                        placeholder: "App key / client ID",
                        text: $schwabAppKeyInput,
                        field: .appKey
                    )

                    credentialInputRow(
                        label: "App secret",
                        placeholder: "App secret",
                        text: $schwabAppSecretInput,
                        field: .appSecret
                    )

                    SystemsReadoutRow(label: "Status", value: compactSchwabStatus, accent: schwabStatusAccent)

                    HStack(spacing: 10) {
                        Button {
                            pasteSchwabCredentialBlock()
                        } label: {
                            Label("Paste Block", systemImage: "doc.on.clipboard")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            saveSchwabDeveloperCredentials()
                        } label: {
                            Label("Save", systemImage: "key.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(schwabAppKeyInput.isEmpty && schwabAppSecretInput.isEmpty)
                    }

                    if AppConfig.Schwab.hasDeveloperCredentials {
                        Button {
                            schwabAppKeyInput = ""
                            schwabAppSecretInput = ""
                            schwabCredentialMessage = nil
                            isEditingSchwabCredentials = false
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            clearSchwabDeveloperCredentials()
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(DesignSystem.short)
                    }
                }

                if let schwabCredentialMessage {
                    Text(schwabCredentialMessage)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func credentialInputRow(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: SchwabCredentialField
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.0)
                .foregroundColor(DesignSystem.mutedText)

            HStack(spacing: 8) {
                SecureField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    #endif

                Button {
                    pasteSchwabCredentialField(field)
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .help("Paste \(label)")
            }
        }
    }

    private var compactAlertsCard: some View {
        SystemsPanel(title: "ALERTS") {
            VStack(alignment: .leading, spacing: 10) {
                SystemsReadoutRow(
                    label: "Permission",
                    value: notifications.permissionStatusText.uppercased(),
                    accent: notifications.isPermissionGranted ? DesignSystem.long : DesignSystem.short
                )

                HStack(spacing: 10) {
                    Button(notifications.isPermissionGranted ? "Refresh" : "Enable") {
                        Task {
                            if notifications.isPermissionGranted {
                                await notifications.refreshAuthorizationStatus()
                            } else {
                                await notifications.requestPermissions()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        SignalNotification.shared.sendTestNotification()
                    } label: {
                        Label("Test", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    Text("Volume")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(width: 58, alignment: .leading)
                    Slider(value: $alertVolume)
                    Text("\(Int(alertVolume * 100))%")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.primaryText)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
    }

    private var compactCloseCard: some View {
        SystemsPanel(title: "CLOSE") {
            VStack(spacing: 8) {
                compactTimeRow("General warn", binding: timeBinding(for: $generalWarningTime, defaultValue: AppConfig.CloseManagement.defaultGeneralWarning))
                compactTimeRow("General exit", binding: timeBinding(for: $generalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultGeneralHardExit))
                compactTimeRow("Inst. warn", binding: timeBinding(for: $institutionalWarningTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalWarning))
                compactTimeRow("Inst. exit", binding: timeBinding(for: $institutionalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalHardExit))

                Divider().background(DesignSystem.hairline)

                Toggle("Background monitoring", isOn: $isBackgroundMonitoringEnabled)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.primaryText)
            }
        }
    }

    private func compactTimeRow(_ label: String, binding: Binding<Date>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
                .frame(width: 100, alignment: .leading)

            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var compactAuditCard: some View {
        SystemsPanel(title: "AUDIT") {
            HStack(spacing: 10) {
                SystemsReadoutRow(label: "Strategy", value: "Ready", accent: DesignSystem.long)

                Button {
                    isAuditSheetOpen = true
                } label: {
                    Label("Run", systemImage: "checkmark.shield")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var compactSchwabStatus: String {
        if AppConfig.Schwab.hasOAuthTokens { return "OAuth stored" }
        if AppConfig.Schwab.hasDeveloperCredentials { return "Keys stored" }
        return "Not stored"
    }

    private var schwabStatusAccent: Color {
        if AppConfig.Schwab.hasOAuthTokens { return DesignSystem.long }
        if AppConfig.Schwab.hasDeveloperCredentials { return DesignSystem.amber }
        return DesignSystem.short
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

        AppConfig.Schwab.developerCredentialsStored = AppConfig.Schwab.appKeyStored && AppConfig.Schwab.appSecretStored

        schwabAppKeyInput = ""
        schwabAppSecretInput = ""
        isEditingSchwabCredentials = !AppConfig.Schwab.hasDeveloperCredentials
        schwabCredentialMessage = AppConfig.Schwab.hasDeveloperCredentials
            ? "Saved. You should not need to type this again on this phone."
            : "Saved the field provided. Add the missing credential to finish."
        NotificationCenter.default.post(name: .schwabCredentialsChanged, object: nil)
    }

    private func clearSchwabDeveloperCredentials() {
        AppConfig.Schwab.appKey = ""
        AppConfig.Schwab.appSecret = ""
        AppConfig.Schwab.accessToken = ""
        AppConfig.Schwab.refreshToken = ""
        AppConfig.Schwab.appKeyStored = false
        AppConfig.Schwab.appSecretStored = false
        AppConfig.Schwab.accessTokenStored = false
        AppConfig.Schwab.refreshTokenStored = false
        AppConfig.Schwab.developerCredentialsStored = false
        AppConfig.Schwab.oauthTokensStored = false
        schwabAppKeyInput = ""
        schwabAppSecretInput = ""
        isEditingSchwabCredentials = false
        schwabCredentialMessage = "Cleared Schwab credentials from this phone."
        NotificationCenter.default.post(name: .schwabCredentialsChanged, object: nil)
    }

    private func pasteSchwabCredentialField(_ field: SchwabCredentialField) {
        guard let pasted = clipboardText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasted.isEmpty else {
            schwabCredentialMessage = "Clipboard is empty."
            return
        }

        let parsed = parseSchwabCredentials(from: pasted)
        let value: String?
        switch field {
        case .appKey:
            value = parsed.appKey ?? normalizedCredentialValue(pasted)
            if let value { schwabAppKeyInput = value }
        case .appSecret:
            value = parsed.appSecret ?? normalizedCredentialValue(pasted)
            if let value { schwabAppSecretInput = value }
        }

        schwabCredentialMessage = value == nil ? "No credential text found on clipboard." : "Pasted \(field.displayName)."
    }

    private func pasteSchwabCredentialBlock() {
        guard let pasted = clipboardText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasted.isEmpty else {
            schwabCredentialMessage = "Clipboard is empty."
            return
        }

        let parsed = parseSchwabCredentials(from: pasted)
        if let appKey = parsed.appKey {
            schwabAppKeyInput = appKey
        }
        if let appSecret = parsed.appSecret {
            schwabAppSecretInput = appSecret
        }

        switch (parsed.appKey, parsed.appSecret) {
        case (.some, .some):
            schwabCredentialMessage = "Pasted app key and app secret."
        case (.some, .none):
            schwabCredentialMessage = "Pasted app key. App secret still needed."
        case (.none, .some):
            schwabCredentialMessage = "Pasted app secret. App key still needed."
        case (.none, .none):
            schwabCredentialMessage = "Paste block did not contain SCHWAB_APP_KEY or SCHWAB_APP_SECRET."
        }
    }

    private var clipboardText: String? {
        #if os(iOS)
        UIPasteboard.general.string
        #elseif os(macOS)
        NSPasteboard.general.string(forType: .string)
        #else
        nil
        #endif
    }

    private func parseSchwabCredentials(from text: String) -> (appKey: String?, appSecret: String?) {
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let appKey = value(in: json, matching: SchwabCredentialField.appKey.acceptedKeys)
            let appSecret = value(in: json, matching: SchwabCredentialField.appSecret.acceptedKeys)
            if appKey != nil || appSecret != nil {
                return (appKey, appSecret)
            }
        }

        var values: [String: String] = [:]
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let pieces = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            guard pieces.count == 2 else { continue }

            let key = normalizedCredentialKey(pieces[0])
            let value = normalizedCredentialValue(pieces[1])
            guard !key.isEmpty, !value.isEmpty else { continue }
            values[key] = value
        }

        return (
            appKey: value(in: values, matching: SchwabCredentialField.appKey.acceptedKeys),
            appSecret: value(in: values, matching: SchwabCredentialField.appSecret.acceptedKeys)
        )
    }

    private func value(in json: [String: Any], matching keys: Set<String>) -> String? {
        for (key, rawValue) in json {
            guard keys.contains(normalizedCredentialKey(key)) else { continue }
            if let value = rawValue as? String {
                return normalizedCredentialValue(value)
            }
        }
        return nil
    }

    private func value(in values: [String: String], matching keys: Set<String>) -> String? {
        for key in keys {
            if let value = values[key] {
                return value
            }
        }
        return nil
    }

    private func normalizedCredentialKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private func normalizedCredentialValue(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
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

private enum SchwabCredentialField {
    case appKey
    case appSecret

    var displayName: String {
        switch self {
        case .appKey: return "app key"
        case .appSecret: return "app secret"
        }
    }

    var acceptedKeys: Set<String> {
        switch self {
        case .appKey:
            return [
                "SCHWAB_APP_KEY",
                "SCHWAB_CLIENT_ID",
                "APP_KEY",
                "CLIENT_ID",
                "API_KEY"
            ]
        case .appSecret:
            return [
                "SCHWAB_APP_SECRET",
                "SCHWAB_CLIENT_SECRET",
                "APP_SECRET",
                "CLIENT_SECRET",
                "API_SECRET",
                "SECRET"
            ]
        }
    }
}

private struct SystemsPanel<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.amber)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DesignSystem.panel)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(DesignSystem.hairline, lineWidth: 1)
        )
    }
}

private struct SystemsReadoutRow: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let label: String
    let value: String
    let accent: Color

    private var labelWidth: CGFloat {
        horizontalSizeClass == .compact ? 94 : 108
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.0)
                .foregroundColor(DesignSystem.mutedText)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
                .frame(width: labelWidth, alignment: .leading)

            Text(value)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(accent)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 22, alignment: .topLeading)
    }
}

private struct SystemsStatusPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.0)
                .foregroundColor(DesignSystem.mutedText)

            Text(value)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.0)
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(accent.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(accent.opacity(0.35), lineWidth: 1)
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
