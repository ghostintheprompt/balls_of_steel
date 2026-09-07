import SwiftUI
import OSLog
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if DEBUG
private let schwabOAuthLogger = Logger(subsystem: "app.mdrn.steel", category: "SchwabOAuth")
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
    @StateObject private var oauthSession = SchwabOAuthSessionCoordinator.shared
    @ObservedObject private var liveTape = LiveTapeService.shared
    @State private var isAuditSheetOpen: Bool = false
    @State private var schwabAppKeyInput: String = ""
    @State private var schwabAppSecretInput: String = ""
    @State private var schwabCallbackInput: String = ""
    @State private var schwabCallbackURLInput: String = AppConfig.Schwab.oauthCallbackURL
    @State private var isEditingSchwabCredentials: Bool = false
    @State private var schwabCredentialMessage: String?
    @State private var isConnectingSchwab: Bool = false
    @State private var isTestingSchwabFeed: Bool = false
    @State private var isConfirmingSchwabCredentialClear: Bool = false
    @State private var isShowingSchwabManualEntry: Bool = false

    var body: some View {
        Group {
            #if os(macOS)
            desktopSystemsPanel
            #else
            mobileSystemsPanel
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: .schwabConnectionComplete)) { _ in
            AppConfig.Schwab.lastOAuthError = ""
            schwabCredentialMessage = "Schwab OAuth connected. Live tape is ready."
            isEditingSchwabCredentials = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .schwabConnectionFailed)) { notification in
            let message = notification.userInfo?["message"] as? String ?? "Schwab OAuth failed."
            AppConfig.Schwab.lastOAuthError = message
            schwabCredentialMessage = message
        }
        .onAppear {
            if schwabCredentialMessage == nil, !AppConfig.Schwab.lastOAuthError.isEmpty {
                schwabCredentialMessage = AppConfig.Schwab.lastOAuthError
            }
        }
        .confirmationDialog(
            "Clear Schwab credentials?",
            isPresented: $isConfirmingSchwabCredentialClear,
            titleVisibility: .visible
        ) {
            Button("Clear Schwab credentials", role: .destructive) {
                clearSchwabDeveloperCredentials()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the app key, app secret, OAuth tokens, and live tape state from this device.")
        }
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

                ScrollView {
                    desktopSystemsContent
                        .padding(18)
                }
            }
        }
        .frame(minWidth: 1120, idealWidth: 1240, minHeight: 720, idealHeight: 800)
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .sheet(isPresented: $isAuditSheetOpen) {
            StrategyAuditView()
        }
    }
    #endif

    #if os(macOS)
    private var desktopSystemsContent: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                desktopDataColumn
                desktopControlsColumn
            }

            VStack(spacing: 16) {
                compactSchwabCredentialsCard
                compactAlertsCard
                compactCloseCard
                compactAuditCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var desktopDataColumn: some View {
        VStack(spacing: 16) {
            compactSchwabCredentialsCard
        }
        .frame(minWidth: 520, maxWidth: .infinity, alignment: .top)
    }

    private var desktopControlsColumn: some View {
        VStack(spacing: 16) {
            compactAlertsCard
            compactCloseCard
            compactAuditCard
        }
        .frame(minWidth: 500, maxWidth: .infinity, alignment: .top)
    }
    #endif

    private var mobileSystemsPanel: some View {
        ZStack {
            TradingBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    mobileSystemsHeader
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
                    .font(DesignSystem.Typography.settingsLabelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("Quote Feed")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 12)

            SystemsStatusPill(
                title: "DATA",
                value: dataStatusValue,
                accent: dataStatusAccent
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
                    .font(DesignSystem.Typography.settingsLabelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text("Quote Feed")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                SystemsStatusPill(
                    title: "DATA",
                    value: dataStatusValue,
                    accent: dataStatusAccent
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

    private var compactSchwabCredentialsCard: some View {
        SystemsPanel(title: "SCHWAB") {
            VStack(alignment: .leading, spacing: 10) {
                if AppConfig.Schwab.hasDeveloperCredentials && !isEditingSchwabCredentials {
                    SystemsReadoutRow(label: "Status", value: compactSchwabStatus, accent: schwabStatusAccent)
                    Text(schwabCredentialStatusCopy)
                        .font(DesignSystem.Typography.settingsValueFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    schwabOAuthControls

                    AdaptiveControlRow {
                        Button {
                            schwabCredentialMessage = nil
                            isEditingSchwabCredentials = true
                        } label: {
                            Label("Replace", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            isConfirmingSchwabCredentialClear = true
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

                    AdaptiveControlRow {
                        Button {
                            pasteSchwabCredentialBlock()
                        } label: {
                            Label("Paste Block", systemImage: "doc.on.clipboard")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(DesignSystem.amber)

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
                        .tint(DesignSystem.amber)
                    } else {
                        Button {
                            isConfirmingSchwabCredentialClear = true
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
                        .font(DesignSystem.Typography.settingsValueFont)
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
                .font(DesignSystem.Typography.settingsLabelFont)
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
                .tint(DesignSystem.amber)
                .help("Paste \(label)")
            }
        }
    }

    private var schwabOAuthControls: some View {
        VStack(alignment: .leading, spacing: 9) {
            if AppConfig.Schwab.hasOAuthTokens {
                SystemsReadoutRow(label: "Token", value: schwabTokenExpiryText, accent: DesignSystem.long)

                AdaptiveControlRow {
                    Button {
                        Task { await toggleSchwabLiveTape() }
                    } label: {
                        Label(liveTape.isEnabled ? "Live Off" : "Live On", systemImage: liveTape.isEnabled ? "pause.fill" : "dot.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTestingSchwabFeed)

                    Button {
                        Task { await testSchwabFeed() }
                    } label: {
                        Label(isTestingSchwabFeed ? "Checking" : "Tick", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(DesignSystem.amber)
                    .disabled(isTestingSchwabFeed)
                }
            } else {
                #if os(macOS)
                VStack(alignment: .leading, spacing: 5) {
                    Text("CALLBACK URL")
                        .font(DesignSystem.Typography.settingsLabelFont)
                        .tracking(1.0)
                        .foregroundColor(DesignSystem.mutedText)

                    Text(AppConfig.Schwab.oauthCallbackURL)
                        .font(DesignSystem.Typography.settingsValueFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
                #else
                VStack(alignment: .leading, spacing: 5) {
                    Text("CALLBACK URL")
                        .font(DesignSystem.Typography.settingsLabelFont)
                        .tracking(1.0)
                        .foregroundColor(DesignSystem.mutedText)

                    TextField(AppConfig.Schwab.appLinkCallbackURL, text: $schwabCallbackURLInput)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .onChange(of: schwabCallbackURLInput) { _, newValue in
                            AppConfig.Schwab.oauthCallbackURL = newValue
                            if AppConfig.Schwab.callbackURLCandidates(from: newValue).count > 1 {
                                schwabCredentialMessage = "Using \(AppConfig.Schwab.oauthCallbackURL) on this device from the portal callback list."
                            }
                        }
                }

                AdaptiveControlRow {
                    Button {
                        setSchwabCallbackPreset(AppConfig.Schwab.appLinkCallbackURL)
                    } label: {
                        Label("App Link", systemImage: "link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(DesignSystem.amber)
                }
                #endif

                Text(schwabPortalCallbackCopy)
                    .font(DesignSystem.Typography.settingsValueFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    if oauthSession.isRunning {
                        oauthSession.cancel()
                        schwabCredentialMessage = "Schwab sign-in canceled."
                    } else {
                        openSchwabAuthorization()
                    }
                } label: {
                    Label(oauthSession.isRunning ? "Cancel Sign In" : "Schwab Sign In", systemImage: oauthSession.isRunning ? "xmark" : "lock.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isConnectingSchwab)

                // Sign-in normally completes on its own (Mac: local loopback
                // listener; iOS: system auth session). This fallback is only
                // for when that automatic capture fails, so it stays closed
                // by default instead of presenting 6 more controls up front.
                DisclosureGroup("Didn't connect automatically?", isExpanded: $isShowingSchwabManualEntry) {
                    VStack(alignment: .leading, spacing: 9) {
                        schwabOAuthDiagnostics

                        Button {
                            copySchwabAuthorizationURL()
                        } label: {
                            Label("Copy OAuth URL", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(DesignSystem.amber)
                        .disabled(isConnectingSchwab)

                        TextField("Paste callback URL or code", text: $schwabCallbackInput)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            #endif

                        AdaptiveControlRow {
                            Button {
                                pasteSchwabCallback()
                            } label: {
                                Label("Paste", systemImage: "doc.on.clipboard")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignSystem.amber)

                            Button {
                                Task { await connectSchwabFromCallback() }
                            } label: {
                                Label(isConnectingSchwab ? "Connecting" : "Connect", systemImage: "link")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isConnectingSchwab || schwabCallbackInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.top, 8)
                }
                .font(DesignSystem.Typography.settingsValueFont)
                .tint(DesignSystem.mutedText)
            }
        }
    }

    private var schwabOAuthDiagnostics: some View {
        VStack(spacing: 4) {
            SystemsReadoutRow(label: "App key", value: schwabAppKeyDiagnosticValue, accent: schwabAppKeyDiagnosticAccent)
            SystemsReadoutRow(label: "Redirect", value: schwabCallbackDiagnosticValue, accent: schwabCallbackDiagnosticAccent)
            SystemsReadoutRow(label: "Auth URL", value: schwabAuthURLDiagnosticValue, accent: schwabAuthURLDiagnosticAccent)
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

                AdaptiveControlRow {
                    Button(notifications.permissionActionTitle) {
                        Task {
                            if notifications.isPermissionGranted {
                                await notifications.refreshAuthorizationStatus()
                            } else {
                                await notifications.handlePermissionAction()
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
                    .tint(DesignSystem.amber)
                    .disabled(!notifications.isPermissionGranted)
                }

                if !notifications.isPermissionGranted {
                    Text(alertPermissionCopy)
                        .font(DesignSystem.Typography.settingsValueFont)
                        .foregroundColor(notifications.isPermissionDenied ? DesignSystem.short : DesignSystem.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Text("Volume")
                        .font(DesignSystem.Typography.settingsValueFont)
                        .foregroundColor(DesignSystem.mutedText)
                        .frame(width: 58, alignment: .leading)
                    Slider(value: $alertVolume)
                    Text("\(Int(alertVolume * 100))%")
                        .font(DesignSystem.Typography.settingsValueFont)
                        .foregroundColor(DesignSystem.primaryText)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
    }

    private var alertPermissionCopy: String {
        if notifications.isPermissionDenied {
            return "Notifications are denied in system settings."
        }
        return "Notifications are off."
    }

    private var compactCloseCard: some View {
        SystemsPanel(title: "CLOSE") {
            VStack(spacing: 8) {
                compactTimeRow("General warn", binding: timeBinding(for: $generalWarningTime, defaultValue: AppConfig.CloseManagement.defaultGeneralWarning))
                compactTimeRow("Session close", binding: timeBinding(for: $generalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultGeneralHardExit))
                compactTimeRow("Inst. warn", binding: timeBinding(for: $institutionalWarningTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalWarning))
                compactTimeRow("Inst. close", binding: timeBinding(for: $institutionalHardExitTime, defaultValue: AppConfig.CloseManagement.defaultInstitutionalHardExit))

                Divider().background(DesignSystem.hairline)

                Toggle("Exit timer", isOn: $isBackgroundMonitoringEnabled)
                    .font(DesignSystem.Typography.settingsValueFont)
                    .foregroundColor(DesignSystem.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SystemsReadoutRow(label: "Scope", value: "APP OPEN", accent: DesignSystem.amber)
            }
        }
    }

    private func compactTimeRow(_ label: String, binding: Binding<Date>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(DesignSystem.Typography.settingsValueFont)
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
        if liveTape.isLive { return "Live" }
        if AppConfig.Schwab.hasOAuthTokens { return "OAuth stored" }
        if AppConfig.Schwab.hasDeveloperCredentials { return "Keys stored" }
        return "Not stored"
    }

    private var dataStatusValue: String {
        if liveTape.isLive { return "LIVE" }
        if AppConfig.Schwab.hasOAuthTokens { return "SCHWAB" }
        if AppConfig.Schwab.hasDeveloperCredentials { return "KEYS" }
        return "MANUAL"
    }

    private var dataStatusAccent: Color {
        if liveTape.isLive { return DesignSystem.long }
        if AppConfig.Schwab.hasOAuthTokens { return DesignSystem.long }
        if AppConfig.Schwab.hasDeveloperCredentials { return DesignSystem.amber }
        return DesignSystem.amber
    }

    private var schwabCredentialStatusCopy: String {
        if liveTape.isLive {
            return "Schwab is feeding the live tape on this device."
        }
        if AppConfig.Schwab.hasOAuthTokens {
            return "OAuth token is stored in Keychain on this device. Turn Live On when you want Schwab to feed the tape."
        }
        return "Keys are stored in Keychain. Live feed still needs the Schwab OAuth connection."
    }

    private var schwabStatusAccent: Color {
        if liveTape.isLive { return DesignSystem.long }
        if AppConfig.Schwab.hasOAuthTokens { return DesignSystem.long }
        if AppConfig.Schwab.hasDeveloperCredentials { return DesignSystem.amber }
        return DesignSystem.short
    }

    private var schwabTokenExpiryText: String {
        guard let expiresAt = AppConfig.Schwab.accessTokenExpiresAt else {
            return "Stored"
        }
        let minutes = Int(expiresAt.timeIntervalSinceNow / 60)
        if minutes <= 0 { return "Refresh due" }
        return "\(minutes)m"
    }

    private var schwabPortalCallbackCopy: String {
        #if os(macOS)
        return "Register exactly https://127.0.0.1:8182 in the Schwab Developer Portal. Steel always signs in through this Mac's local listener — it never redirects through a website."
        #else
        return "Register exactly https://mdrn.app/apps/steeltradingdesk/schwab/oauth/callback in the Schwab Developer Portal."
        #endif
    }

    private var schwabAppKeyDiagnosticValue: String {
        let appKey = AppConfig.Schwab.appKeyWithoutPrompt
        if !appKey.isEmpty {
            let suffix = AppConfig.Schwab.appKeyNeedsNormalizationWithoutPrompt ? " / normalize" : ""
            return "\(maskedCredential(appKey)) / \(appKey.count) chars\(suffix)"
        }
        if AppConfig.Schwab.appKeyStored || AppConfig.Schwab.developerCredentialsStored {
            return KeychainService.isInteractionSuppressedForSession ? "Stored / denied" : "Stored / unlock on OAuth"
        }
        return "Missing"
    }

    private var schwabAppKeyDiagnosticAccent: Color {
        if !AppConfig.Schwab.appKeyWithoutPrompt.isEmpty {
            return AppConfig.Schwab.appKeyNeedsNormalizationWithoutPrompt ? DesignSystem.amber : DesignSystem.long
        }
        if AppConfig.Schwab.appKeyStored || AppConfig.Schwab.developerCredentialsStored {
            return DesignSystem.amber
        }
        return DesignSystem.short
    }

    private var schwabCallbackDiagnosticValue: String {
        let callback = AppConfig.Schwab.oauthCallbackURL
        guard let url = URL(string: callback), url.scheme == "https", url.host != nil else {
            return "HTTPS URL needed"
        }
        let suffix = AppConfig.Schwab.callbackURLCandidates(from: schwabCallbackURLInput).count > 1
            ? " / picked"
            : ""
        if callback == AppConfig.Schwab.appLinkCallbackURL {
            return "\(callback) / app-link\(suffix)"
        }
        if AppConfig.Schwab.isLoopbackCallbackURL(callback) {
            return "\(callback) / local Mac\(suffix)"
        }
        return "\(callback) / custom\(suffix)"
    }

    private var schwabCallbackDiagnosticAccent: Color {
        let callback = AppConfig.Schwab.oauthCallbackURL
        guard let url = URL(string: callback), url.scheme == "https", url.host != nil else {
            return DesignSystem.short
        }
        #if os(macOS)
        return callback == AppConfig.Schwab.portedLoopbackCallbackURL ? DesignSystem.long : DesignSystem.amber
        #else
        return callback == AppConfig.Schwab.appLinkCallbackURL ? DesignSystem.long : DesignSystem.amber
        #endif
    }

    private var schwabAuthURLDiagnosticValue: String {
        let appKey = AppConfig.Schwab.appKeyWithoutPrompt
        if !appKey.isEmpty {
            return appKeyHasBadClientID(appKey) ? "Bad client_id" : "Clean client_id"
        }
        if AppConfig.Schwab.appKeyStored || AppConfig.Schwab.developerCredentialsStored {
            return KeychainService.isInteractionSuppressedForSession ? "Keychain denied" : "Unlock on OAuth"
        }
        return "Not ready"
    }

    private var schwabAuthURLDiagnosticAccent: Color {
        let appKey = AppConfig.Schwab.appKeyWithoutPrompt
        if !appKey.isEmpty {
            return appKeyHasBadClientID(appKey) ? DesignSystem.short : DesignSystem.long
        }
        if AppConfig.Schwab.appKeyStored || AppConfig.Schwab.developerCredentialsStored {
            return DesignSystem.amber
        }
        return DesignSystem.short
    }

    private func saveSchwabDeveloperCredentials() {
        let rawAppKey = schwabAppKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawAppSecret = schwabAppSecretInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let appKey = AppConfig.Schwab.sanitizedAppKey(rawAppKey)
        let appSecret = AppConfig.Schwab.sanitizedCredential(rawAppSecret)
        var cleanedPaste = false

        if !appKey.isEmpty {
            AppConfig.Schwab.appKey = appKey
            cleanedPaste = appKey != rawAppKey
        }

        if !appSecret.isEmpty {
            AppConfig.Schwab.appSecret = appSecret
            cleanedPaste = cleanedPaste || appSecret != rawAppSecret
        }

        AppConfig.Schwab.developerCredentialsStored = AppConfig.Schwab.appKeyStored && AppConfig.Schwab.appSecretStored

        schwabAppKeyInput = ""
        schwabAppSecretInput = ""
        isEditingSchwabCredentials = !AppConfig.Schwab.hasDeveloperCredentials
        if AppConfig.Schwab.hasDeveloperCredentials {
            schwabCredentialMessage = cleanedPaste
                ? "Saved and cleaned paste artifacts from the Schwab credentials."
                : "Saved. You should not need to type this again on this phone."
        } else {
            schwabCredentialMessage = "Saved the field provided. Add the missing credential to finish."
        }
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
        AppConfig.Schwab.accessTokenExpiresAt = nil
        AppConfig.Schwab.lastOAuthError = ""
        liveTape.isEnabled = false
        schwabAppKeyInput = ""
        schwabAppSecretInput = ""
        schwabCallbackInput = ""
        schwabCallbackURLInput = AppConfig.Schwab.defaultCallbackURL
        AppConfig.Schwab.oauthCallbackURL = schwabCallbackURLInput
        isEditingSchwabCredentials = false
        schwabCredentialMessage = "Cleared Schwab credentials from this phone."
        NotificationCenter.default.post(name: .schwabCredentialsChanged, object: nil)
    }

    private func setSchwabCallbackPreset(_ callback: String) {
        schwabCallbackURLInput = callback
        AppConfig.Schwab.oauthCallbackURL = callback
        schwabCredentialMessage = "Callback set to \(callback). It must be listed in the Schwab Developer Portal."
    }

    private func openSchwabAuthorization() {
        guard AppConfig.Schwab.hasDeveloperCredentials else {
            schwabCredentialMessage = "Save your Schwab app key and app secret first."
            return
        }

        do {
            AppConfig.Schwab.lastOAuthError = ""
            let normalizedCredentials = AppConfig.Schwab.normalizeStoredDeveloperCredentials()
            let callbackURL = AppConfig.Schwab.oauthCallbackURL
            let url = try SchwabService.shared.authorizationURL(redirectURI: callbackURL)
            if authURLHasBadClientID(url) {
                schwabCredentialMessage = "App Key still has a bad client_id. Replace it with the exact Schwab App Key."
                debugSchwabAuthorization(url, action: "blocked_bad_client")
                return
            }
            debugSchwabAuthorization(url, action: "system_auth")
            let result = oauthSession.start(
                authURL: url,
                callbackURL: callbackURL,
                statusUpdate: { message in
                    schwabCredentialMessage = message
                }
            ) { callbackResult in
                Task { @MainActor in
                    switch callbackResult {
                    case .success(let returnedURL):
                        schwabCallbackInput = returnedURL.absoluteString
                        await connectSchwabFromCallback(redirectURI: callbackURL)
                    case .failure(let error):
                        schwabCredentialMessage = error.localizedDescription
                    }
                }
            }

            switch result {
            case .startingLoopback(let message):
                schwabCredentialMessage = normalizedCredentials
                    ? "Cleaned credentials. \(message)"
                    : message
            case .systemSession:
                schwabCredentialMessage = normalizedCredentials
                    ? "Cleaned credentials, then opened Schwab in the system sign-in session."
                    : "Opened Schwab in the system sign-in session."
            case .externalBrowser(let message):
                schwabCredentialMessage = normalizedCredentials
                    ? "Cleaned credentials. \(message)"
                    : message
            }
        } catch {
            schwabCredentialMessage = schwabOAuthFailureMessage(error, stage: .authorize)
        }
    }

    private func copySchwabAuthorizationURL() {
        do {
            let normalizedCredentials = AppConfig.Schwab.normalizeStoredDeveloperCredentials()
            let url = try SchwabService.shared.authorizationURL()
            debugSchwabAuthorization(url, action: "copy")
            setClipboardText(url.absoluteString)
            schwabCredentialMessage = authURLHasBadClientID(url)
                ? "Copied OAuth URL, but client_id still has a pipe. Replace the App Key."
                : normalizedCredentials
                    ? "Cleaned pasted credentials and copied OAuth URL using \(AppConfig.Schwab.oauthCallbackURL)."
                    : "Copied clean OAuth URL using \(AppConfig.Schwab.oauthCallbackURL). That redirect must be registered in the Schwab portal."
        } catch {
            schwabCredentialMessage = error.localizedDescription
        }
    }

    private func pasteSchwabCallback() {
        guard let pasted = clipboardText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasted.isEmpty else {
            schwabCredentialMessage = "Clipboard is empty."
            return
        }
        schwabCallbackInput = pasted
        schwabCredentialMessage = SchwabService.shared.authorizationCode(from: pasted) == nil
            ? "Pasted callback text, but no code was found yet."
            : "Pasted Schwab callback code."
    }

    @MainActor
    private func connectSchwabFromCallback(redirectURI: String? = nil) async {
        guard !isConnectingSchwab else { return }
        let input = schwabCallbackInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let code = SchwabService.shared.authorizationCode(from: input) else {
            schwabCredentialMessage = "Paste the full Schwab callback URL or just the code value."
            return
        }

        isConnectingSchwab = true
        defer { isConnectingSchwab = false }

        do {
            let callbackRedirectURI = redirectURI
                ?? schwabRedirectURI(fromCallbackText: input)
                ?? AppConfig.Schwab.oauthCallbackURL
            _ = try await SchwabService.shared.exchangeCodeForToken(code, redirectURI: callbackRedirectURI)
            MarketDataRegistry.shared.use(.schwab)
            liveTape.isEnabled = true
            await liveTape.tickNow()
            schwabCallbackInput = ""
            if let error = liveTape.lastError {
                schwabCredentialMessage = "OAuth connected. First live tick needs attention: \(error)"
            } else {
                schwabCredentialMessage = "Schwab OAuth connected. Live tape is on."
            }
            NotificationCenter.default.post(name: .schwabCredentialsChanged, object: nil)
            NotificationCenter.default.post(name: .schwabConnectionComplete, object: nil)
        } catch {
            let message = SchwabService.tokenExchangeFailureMessage(error)
            AppConfig.Schwab.lastOAuthError = message
            schwabCredentialMessage = message
        }
    }

    private func schwabRedirectURI(fromCallbackText text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }

        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        if !url.path.isEmpty, url.path != "/" {
            components.percentEncodedPath = url.path
        }
        return components.url.map { AppConfig.Schwab.sanitizedCallbackURL($0.absoluteString) }
    }

    @MainActor
    private func toggleSchwabLiveTape() async {
        guard AppConfig.Schwab.hasOAuthTokens else {
            schwabCredentialMessage = "Connect Schwab OAuth first."
            return
        }

        if liveTape.isEnabled {
            liveTape.isEnabled = false
            schwabCredentialMessage = "Schwab live tape is off."
            return
        }

        await testSchwabFeed()
    }

    @MainActor
    private func testSchwabFeed() async {
        guard !isTestingSchwabFeed else { return }
        guard AppConfig.Schwab.hasOAuthTokens else {
            schwabCredentialMessage = "Connect Schwab OAuth first."
            return
        }

        isTestingSchwabFeed = true
        defer { isTestingSchwabFeed = false }

        MarketDataRegistry.shared.use(.schwab)
        liveTape.isEnabled = true
        await liveTape.tickNow()

        if let error = liveTape.lastError {
            schwabCredentialMessage = "Schwab live tick failed: \(error)"
        } else if let snapshot = liveTape.lastSnapshot {
            schwabCredentialMessage = String(format: "Schwab live tick loaded VXX %.2f / VIX %.2f.", snapshot.vxxPrice, snapshot.vixPrice)
        } else {
            schwabCredentialMessage = "Schwab live tape is on."
        }
        NotificationCenter.default.post(name: .schwabCredentialsChanged, object: nil)
    }

    private func authURLHasBadClientID(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let clientID = components.queryItems?.first(where: { $0.name == "client_id" })?.value else {
            return true
        }
        return appKeyHasBadClientID(clientID)
    }

    private func appKeyHasBadClientID(_ clientID: String) -> Bool {
        clientID.contains("|") ||
            clientID.range(of: "%7C", options: .caseInsensitive) != nil ||
            AppConfig.Schwab.credentialHasNonASCII(clientID)
    }

    private func debugSchwabAuthorization(_ url: URL, action: String) {
        #if DEBUG
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let clientID = components?.queryItems?.first(where: { $0.name == "client_id" })?.value ?? ""
        let callback = components?.queryItems?.first(where: { $0.name == "redirect_uri" })?.value ?? ""
        let cleanClient = !authURLHasBadClientID(url)
        let asciiClient = !AppConfig.Schwab.credentialHasNonASCII(clientID)
        let summary = "action=\(action) client=\(maskedCredential(clientID)) clientLen=\(clientID.count) callback=\(callback) host=\(url.host ?? "missing") asciiClient=\(asciiClient) cleanClient=\(cleanClient)"
        schwabOAuthLogger.notice("\(summary, privacy: .public)")
        print("SCHWAB_OAUTH_DEBUG \(summary)")
        #endif
    }

    private func maskedCredential(_ value: String) -> String {
        let cleaned = AppConfig.Schwab.sanitizedCredential(value)
        guard cleaned.count > 10 else { return cleaned.isEmpty ? "Missing" : "Stored" }
        return "\(cleaned.prefix(6))...\(cleaned.suffix(4))"
    }

    private enum SchwabOAuthStage {
        case authorize
        case token
    }

    private func schwabOAuthFailureMessage(_ error: Error, stage: SchwabOAuthStage) -> String {
        if KeychainService.isInteractionSuppressedForSession {
            return "Keychain access was denied earlier in this app session. Relaunch Steel, then choose Allow once when opening Schwab OAuth."
        }
        if case let SchwabService.SchwabError.httpStatus(_, body) = error,
           body.localizedCaseInsensitiveContains("invalid_client") ||
           body.localizedCaseInsensitiveContains("unauthorized") {
            switch stage {
            case .authorize:
                return "Schwab rejected the App Key or redirect. Confirm the app is Ready in the Developer Portal and \(AppConfig.Schwab.oauthCallbackURL) is registered."
            case .token:
                return "Schwab rejected the token request. Replace the App Secret, confirm \(AppConfig.Schwab.oauthCallbackURL) is registered, then use a fresh OAuth code."
            }
        }
        return error.localizedDescription
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
            value = AppConfig.Schwab.sanitizedAppKey(parsed.appKey ?? normalizedCredentialValue(pasted))
            if let value { schwabAppKeyInput = value }
        case .appSecret:
            value = AppConfig.Schwab.sanitizedCredential(parsed.appSecret ?? normalizedCredentialValue(pasted))
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
            schwabAppKeyInput = AppConfig.Schwab.sanitizedAppKey(appKey)
        }
        if let appSecret = parsed.appSecret {
            schwabAppSecretInput = AppConfig.Schwab.sanitizedCredential(appSecret)
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

    private func setClipboardText(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
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
                .font(DesignSystem.Typography.settingsLabelFont)
                .tracking(1.6)
                .foregroundColor(DesignSystem.amber)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DesignSystem.panel)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(DesignSystem.hairline, lineWidth: 1)
        )
    }
}

private struct AdaptiveControlRow<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content

    init(spacing: CGFloat = 10, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: spacing) {
                content()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct SystemsReadoutRow: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let label: String
    let value: String
    let accent: Color

    private var labelWidth: CGFloat {
        horizontalSizeClass == .compact ? 92 : 118
    }

    var body: some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 4) {
                labelText
                valueText
            }
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .topLeading)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                labelText
                    .frame(width: labelWidth, alignment: .leading)

                valueText
            }
            .frame(minHeight: 22, alignment: .topLeading)
        }
    }

    private var labelText: some View {
        Text(label.uppercased())
            .font(DesignSystem.Typography.settingsLabelFont)
            .tracking(1.0)
            .foregroundColor(DesignSystem.mutedText)
            .lineLimit(2)
            .minimumScaleFactor(0.74)
    }

    private var valueText: some View {
        Text(value)
            .font(DesignSystem.Typography.settingsValueFont)
            .foregroundColor(accent)
            .lineLimit(4)
            .minimumScaleFactor(0.80)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}

private struct SystemsStatusPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.settingsLabelFont)
                .tracking(1.0)
                .foregroundColor(DesignSystem.mutedText)

            Text(value)
                .font(DesignSystem.Typography.settingsLabelFont)
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
