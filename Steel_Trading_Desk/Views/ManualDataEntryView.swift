import SwiftUI

// MARK: - Manual Data Entry View
// Educational tool - Enter market data manually from your trading platform

struct ManualDataEntryView: View {
    @StateObject private var viewModel = ManualDataEntryViewModel()
    @State private var showingSaved = false

    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(spacing: 24) {
                        educationalHeader
                        tapeOrderCard
                        dataEntryForm
                        quickFillSection
                        actionButtons

                        if let lastEntry = viewModel.lastEntry {
                            lastEntryCard(lastEntry)
                        }
                    }
                    .padding(DesignSystem.spacing)
                }
            }
            .navigationTitle("Manual Feed")
            .alert("Data Saved", isPresented: $showingSaved) {
                Button("OK") { }
            } message: {
                Text("The desk has the read. Check SPY or VXX for the signal state.")
            }
        }
    }

    private var educationalHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(DesignSystem.primaryColor)
                Text("MANUAL FEED")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Text("Enter the read. Check the rules.")
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(DesignSystem.primaryText)

            Text("Pull the numbers from ThinkOrSwim or Schwab. VXX/VIX, volume, VWAP, arrow, window. You execute on the trading platform. Steel only keeps the decision honest.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Text("YOU EXECUTE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.bullishColor.opacity(0.14))
                    .clipShape(Capsule())
                    .foregroundColor(DesignSystem.bullishColor)
                Text("NO AUTO-TRADE")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.bearishColor.opacity(0.14))
                    .clipShape(Capsule())
                    .foregroundColor(DesignSystem.bearishColor)
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.12))
    }

    private var tapeOrderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ORDER OF ATTACK")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)

            TapeOrderRow(
                index: 1,
                title: "Volume + window",
                detail: viewModel.volumeWindowGateDetail,
                state: viewModel.volumeWindowGateState
            )

            TapeOrderRow(
                index: 2,
                title: "Ratio",
                detail: viewModel.ratioGateDetail,
                state: viewModel.ratioGateState
            )

            TapeOrderRow(
                index: 3,
                title: "VWAP / key level",
                detail: viewModel.levelGateDetail,
                state: viewModel.levelGateState
            )

            TapeOrderRow(
                index: 4,
                title: "Pattern now",
                detail: viewModel.patternGateDetail,
                state: viewModel.patternGateState
            )
        }
        .deskPanel(glow: .clear)
    }

    private var dataEntryForm: some View {
        VStack(spacing: 16) {
            Text("DESK INPUT")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Label("Instrument", systemImage: "chart.line.uptrend.xyaxis")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Picker("Instrument", selection: $viewModel.instrument) {
                    Text("VXX").tag(TradingInstrument.vxx)
                    Text("SPY").tag(TradingInstrument.spy)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("\(viewModel.instrument.displayName) Price", systemImage: "dollarsign.circle.fill")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                TextField(viewModel.instrument == .vxx ? "e.g., 42.15" : "e.g., 520.40", text: $viewModel.price)
                    .textFieldStyle(.roundedBorder)
                if let error = viewModel.priceError {
                    Text(error)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.bearishColor)
                }
            }

            if viewModel.instrument == .vxx {
                VStack(alignment: .leading, spacing: 8) {
                    Label("VIX Level", systemImage: "chart.line.uptrend.xyaxis")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.primaryText)
                    TextField("e.g., 18.50", text: $viewModel.vixLevel)
                        .textFieldStyle(.roundedBorder)
                    if let error = viewModel.vixLevelError {
                        Text(error)
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.bearishColor)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Volume (% of Average)", systemImage: "waveform")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                HStack {
                    TextField("e.g., 340", text: $viewModel.volumePercent)
                        .textFieldStyle(.roundedBorder)
                    Text("%")
                        .foregroundColor(DesignSystem.mutedText)
                }
                if let error = viewModel.volumePercentError {
                    Text(error)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.bearishColor)
                }
                if let volumePct = Double(viewModel.volumePercent), volumePct > 0 {
                    volumeIndicator(volumePct)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Trading Window", systemImage: "clock.fill")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Picker("Window", selection: $viewModel.timeWindow) {
                    Text("Open (9:35-10:05)").tag(TimeWindowInput.open)
                    Text("Pre-Market").tag(TimeWindowInput.preMarket)
                    Text("Morning (9:50-10:15)").tag(TimeWindowInput.morning)
                    Text("Lunch (12:20-12:40)").tag(TimeWindowInput.lunch)
                    Text("Afternoon Flex (1:30-3:45)").tag(TimeWindowInput.afternoonFlex)
                    Text("Power Hour (3:10-3:25)").tag(TimeWindowInput.powerHour)
                    Text("Close (3:30-3:55)").tag(TimeWindowInput.close)
                    Text("Institutional (3:45-4:10)").tag(TimeWindowInput.institutional)
                    Text("After Hours").tag(TimeWindowInput.afterHours)
                }
                .pickerStyle(.menu)
            }

            Divider()

            if viewModel.instrument == .vxx {
                if let ratio = viewModel.calculatedRatio {
                    ratioIndicator(ratio)
                } else if !viewModel.price.isEmpty && !viewModel.vixLevel.isEmpty {
                    Text("Invalid VXX or VIX values")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.warningColor)
                }
                Divider()
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Price vs VWAP", systemImage: "arrow.up.arrow.down")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Picker("VWAP Position", selection: $viewModel.vwapPosition) {
                    Text("Above VWAP").tag(VWAPPosition.above)
                    Text("Below VWAP").tag(VWAPPosition.below)
                    Text("At VWAP").tag(VWAPPosition.at)
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $viewModel.keyLevelConfirmed) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Key level confirmed")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.primaryText)
                    Text("VWAP, 50 SMA, round number, prior high, or support break.")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Arrow Signal", systemImage: "arrow.up.arrow.down.circle.fill")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Picker("Arrow Signal", selection: $viewModel.arrowSignal) {
                    Text("No Arrow").tag(ArrowSignalInput.none)
                    Text("Bullish (Up)").tag(ArrowSignalInput.bullish)
                    Text("Bearish (Down)").tag(ArrowSignalInput.bearish)
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $viewModel.patternConfirmed) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rejection pattern visible")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.primaryText)
                    Text("Shooting star, doji, engulfing, or clear rejection candle.")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("News Risk", systemImage: "newspaper.fill")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Picker("News Risk", selection: $viewModel.newsRisk) {
                    Text("None").tag(NewsRiskInput.none)
                    Text("Moderate").tag(NewsRiskInput.moderate)
                    Text("High").tag(NewsRiskInput.high)
                }
                .pickerStyle(.segmented)
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.10))
    }

    private func volumeIndicator(_ volumePct: Double) -> some View {
        HStack(spacing: 8) {
            if volumePct >= 400 {
                Label("MAJOR INSTITUTION", systemImage: "star.fill")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.primaryColor)
                    .cornerRadius(2)
            } else if volumePct >= 300 {
                Label("INSTITUTIONAL FLOW", systemImage: "star.fill")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.dangerColor)
                    .cornerRadius(2)
            } else if volumePct >= 200 {
                Label("ENTRY-GRADE", systemImage: "checkmark.circle.fill")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.bullishColor)
            } else {
                Label("NOT ENOUGH", systemImage: "xmark.circle.fill")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.warningColor)
            }
        }
    }

    private func ratioIndicator(_ ratioData: VXXVIXRatio) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("VXX/VIX Ratio", systemImage: "chart.bar.fill")
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)

                Spacer()

                Text(String(format: "%.2f", ratioData.ratio))
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(ratioColor(for: ratioData.tier))
            }

            HStack(spacing: 12) {
                Image(systemName: ratioIcon(for: ratioData.tier))
                    .font(.title3)
                    .foregroundColor(ratioColor(for: ratioData.tier))

                VStack(alignment: .leading, spacing: 2) {
                    Text(ratioData.tier.displayName)
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(ratioColor(for: ratioData.tier))

                    Text("Range: \(ratioData.tier.thresholdRange)")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }

                Spacer()

                if ratioData.recommendedPositionSize > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Position")
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.mutedText)
                        Text("$\(Int(ratioData.recommendedPositionSize))")
                            .font(DesignSystem.Typography.headlineFont)
                            .foregroundColor(ratioColor(for: ratioData.tier))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(ratioColor(for: ratioData.tier).opacity(0.1))
            )

            ratioThresholdGuide(currentRatio: ratioData.ratio)

            HStack {
                Image(systemName: ratioData.shouldTrade ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(ratioData.shouldTrade ? DesignSystem.bullishColor : DesignSystem.bearishColor)

                Text(ratioData.shouldTrade ? "TRADE ELIGIBLE (Ratio >=1.45)" : "SKIP TRADE (Ratio <1.45)")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(ratioData.shouldTrade ? DesignSystem.bullishColor : DesignSystem.bearishColor)
            }
        }
        .deskPanel(glow: ratioColor(for: ratioData.tier).opacity(0.12), padding: 14)
    }

    // MARK: - Ratio Threshold Visual Guide
    private func ratioThresholdGuide(currentRatio: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Thresholds:")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)

            HStack(spacing: 0) {
                // <1.35 noFade
                Rectangle()
                    .fill(DesignSystem.short.opacity(0.45))
                    .frame(height: 8)
                    .overlay(zoneTick("1.35"))

                // 1.35-1.45 weakFade
                Rectangle()
                    .fill(DesignSystem.short.opacity(0.20))
                    .frame(height: 8)
                    .overlay(zoneTick("1.45"))

                // 1.45-1.55 normalFade
                Rectangle()
                    .fill(DesignSystem.amber.opacity(0.30))
                    .frame(height: 8)
                    .overlay(zoneTick("1.55"))

                // 1.55-1.60 strongFade
                Rectangle()
                    .fill(DesignSystem.long.opacity(0.30))
                    .frame(height: 8)
                    .overlay(zoneTick("1.60"))

                // >1.60 premiumFade
                Rectangle()
                    .fill(DesignSystem.long.opacity(0.55))
                    .frame(height: 8)
            }
            .cornerRadius(2)
            .overlay(
                GeometryReader { geometry in
                    let position = ratioToPosition(ratio: currentRatio, width: geometry.size.width)
                    Rectangle()
                        .fill(DesignSystem.amber)
                        .frame(width: 2, height: 14)
                        .position(x: position, y: 4)
                }
            )
        }
    }

    private func zoneTick(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(DesignSystem.text2)
            .offset(x: -15, y: -10)
    }

    // Convert ratio value to position on the guide
    private func ratioToPosition(ratio: Double, width: CGFloat) -> CGFloat {
        let minRatio = 1.25
        let maxRatio = 1.70
        let clampedRatio = min(max(ratio, minRatio), maxRatio)
        let normalizedPosition = (clampedRatio - minRatio) / (maxRatio - minRatio)
        return CGFloat(normalizedPosition) * width
    }

    // Helper functions for ratio display
    private func ratioColor(for tier: VXXVIXRatio.RatioTier) -> Color {
        switch tier {
        case .premiumFade: return DesignSystem.long
        case .strongFade: return DesignSystem.long
        case .normalFade: return DesignSystem.amber
        case .weakFade: return DesignSystem.amber
        case .noFade: return DesignSystem.short
        }
    }

    private func ratioIcon(for tier: VXXVIXRatio.RatioTier) -> String {
        switch tier {
        case .premiumFade: return "star.fill"
        case .strongFade: return "star.leadinghalf.filled"
        case .normalFade: return "star"
        case .weakFade: return "exclamationmark.triangle.fill"
        case .noFade: return "xmark.octagon.fill"
        }
    }

    private var quickFillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESET + RELOAD")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)

            HStack(spacing: 12) {
                Button(action: { viewModel.quickFillLastEntry() }) {
                    Label("Last Entry", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.lastEntry == nil)
            }

            Button(action: { viewModel.clearForm() }) {
                Label("Clear All Fields", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(DesignSystem.dangerColor)
        }
        .deskPanel(glow: DesignSystem.warningColor.opacity(0.08))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                if viewModel.saveEntry() {
                    showingSaved = true
                }
            }) {
                Label("Post To Desk", systemImage: "checkmark.circle.fill")
                    .font(DesignSystem.Typography.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValidEntry ? DesignSystem.amber : DesignSystem.faint)
                    .foregroundColor(viewModel.isValidEntry ? .black : DesignSystem.muted)
                    .cornerRadius(2)
            }
            .disabled(!viewModel.isValidEntry)

            if !viewModel.isValidEntry {
                Text("Fill the required fields with real numbers before you post it.")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.warningColor)
            }
        }
    }

    private func lastEntryCard(_ entry: MarketDataEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST READ")
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.instrument.displayName): $\(entry.price, specifier: "%.2f")")
                        .foregroundColor(DesignSystem.primaryText)
                    if entry.instrument == .vxx {
                        Text("VIX: \(entry.vixLevel, specifier: "%.2f")")
                            .foregroundColor(DesignSystem.primaryText)
                        Text("Ratio: \(entry.ratio, specifier: "%.2f")")
                            .foregroundColor(DesignSystem.primaryColor)
                    }
                    Text("Volume: \(Int(entry.volumePercent))%")
                        .foregroundColor(DesignSystem.primaryText)
                }
                .font(DesignSystem.Typography.bodyFont)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.ratioTier)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(entry.instrument == .vxx ? (entry.ratio >= 1.60 ? DesignSystem.long : entry.ratio >= 1.45 ? DesignSystem.amber : DesignSystem.short) : DesignSystem.muted)
                    Text(entry.arrowSignal.displayName)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(entry.arrowSignal.color)
                    Text(entry.keyLevelConfirmed ? "Level: Confirmed" : "Level: Missing")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(entry.keyLevelConfirmed ? DesignSystem.bullishColor : DesignSystem.warningColor)
                    Text(entry.patternConfirmed ? "Pattern: Confirmed" : "Pattern: Missing")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(entry.patternConfirmed ? DesignSystem.bullishColor : DesignSystem.warningColor)
                    Text(entry.timeWindow.displayName)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    Text(entry.newsRisk.displayName)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    Text(entry.timestamp, style: .time)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.08))
    }
}

enum TapeGateState: Equatable {
    case pass
    case fail
    case locked

    var icon: String {
        switch self {
        case .pass: return "checkmark.circle.fill"
        case .fail: return "xmark.circle.fill"
        case .locked: return "lock.fill"
        }
    }

    var color: Color {
        switch self {
        case .pass: return DesignSystem.bullishColor
        case .fail: return DesignSystem.dangerColor
        case .locked: return DesignSystem.mutedText
        }
    }
}

private struct TapeOrderRow: View {
    let index: Int
    let title: String
    let detail: String
    let state: TapeGateState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(index)")
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
                .frame(width: 28, height: 28)
                .background(state.color.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Text(detail)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: state.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(state.color)
        }
        .padding(12)
        .background(DesignSystem.panelBottom)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(state.color.opacity(state == .locked ? 0.16 : 0.32), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - View Model
@MainActor
class ManualDataEntryViewModel: ObservableObject {
    @Published var instrument: TradingInstrument = .vxx
    @Published var price: String = ""
    @Published var vixLevel: String = ""
    @Published var volumePercent: String = ""
    @Published var vwapPosition: VWAPPosition = .above
    @Published var arrowSignal: ArrowSignalInput = .none
    @Published var timeWindow: TimeWindowInput = .morning
    @Published var newsRisk: NewsRiskInput = .none
    @Published var keyLevelConfirmed: Bool = false
    @Published var patternConfirmed: Bool = false

    @Published var priceError: String?
    @Published var vixLevelError: String?
    @Published var volumePercentError: String?

    @Published var lastEntry: MarketDataEntry?

    // VXX/VIX Ratio calculation
    var calculatedRatio: VXXVIXRatio? {
        guard instrument == .vxx,
              let vxxValue = Double(price),
              let vixValue = Double(vixLevel),
              vxxValue > 0,
              vixValue > 0 else {
            return nil
        }
        return VXXVIXRatio(vxx: vxxValue, vix: vixValue)
    }

    var volumeWindowGateState: TapeGateState {
        guard let volumeValue = Double(volumePercent), volumeValue > 0 else { return .fail }
        return volumeValue >= 200 && timeWindow.isVXXEntryWindow ? .pass : .fail
    }

    var ratioGateState: TapeGateState {
        guard volumeWindowGateState == .pass else { return .locked }
        guard instrument == .vxx, let ratio = calculatedRatio?.ratio else { return .fail }
        return ratio >= 1.45 ? .pass : .fail
    }

    var levelGateState: TapeGateState {
        guard ratioGateState == .pass else { return .locked }
        return keyLevelConfirmed ? .pass : .fail
    }

    var patternGateState: TapeGateState {
        guard levelGateState == .pass else { return .locked }
        return patternConfirmed ? .pass : .fail
    }

    var volumeWindowGateDetail: String {
        guard let volumeValue = Double(volumePercent), volumeValue > 0 else {
            return "Start here. Need volume >200% and a valid VXX window."
        }
        if volumeValue < 200 {
            return "Volume \(Int(volumeValue))%. Need >200% before anything else."
        }
        if !timeWindow.isVXXEntryWindow {
            return "\(timeWindow.displayName) is not in the VXX playbook."
        }
        return "\(Int(volumeValue))% volume inside \(timeWindow.displayName)."
    }

    var ratioGateDetail: String {
        guard volumeWindowGateState == .pass else {
            return "Locked until volume and time pass."
        }
        guard instrument == .vxx else {
            return "Switch instrument to VXX for this desk read."
        }
        guard let ratio = calculatedRatio?.ratio else {
            return "Enter VXX and VIX to calculate the ratio."
        }
        return ratio >= 1.45
            ? "\(String(format: "%.2f", ratio)) passes. Size by tier."
            : "\(String(format: "%.2f", ratio)) fails. Need >1.45."
    }

    var levelGateDetail: String {
        guard ratioGateState == .pass else {
            return "Locked until ratio passes."
        }
        return keyLevelConfirmed
            ? "Level confirmed. VWAP read: \(vwapPosition.displayName)."
            : "Need VWAP, 50 SMA, round number, prior high, or support break."
    }

    var patternGateDetail: String {
        guard levelGateState == .pass else {
            return "Locked until level passes."
        }
        return patternConfirmed
            ? "Rejection is visible now. Do not chase after it moves."
            : "Wait for the rejection candle. No early entry."
    }

    var isValidEntry: Bool {
        validateFields()
        let vixValid = instrument == .vxx ? vixLevelError == nil && !vixLevel.isEmpty : true
        return priceError == nil &&
               vixValid &&
               volumePercentError == nil &&
               !price.isEmpty &&
               !volumePercent.isEmpty
    }

    func validateFields() {
        // Validate Instrument Price
        if !price.isEmpty {
            if let parsedPrice = Double(price), parsedPrice > 0, parsedPrice < 10_000 {
                priceError = nil
            } else {
                priceError = "Enter valid price (0-10000)"
            }
        }

        // Validate VIX Level
        if instrument == .vxx && !vixLevel.isEmpty {
            if let vix = Double(vixLevel), vix > 0, vix < 100 {
                vixLevelError = nil
            } else {
                vixLevelError = "Enter valid VIX (0-100)"
            }
        }

        // Validate Volume
        if !volumePercent.isEmpty {
            if let vol = Double(volumePercent), vol > 0, vol < 1000 {
                volumePercentError = nil
            } else {
                volumePercentError = "Enter valid volume %"
            }
        }
    }

    func saveEntry() -> Bool {
        guard isValidEntry,
              let priceValue = Double(price),
              let volumePercentValue = Double(volumePercent) else {
            return false
        }
        let vixLevelValue = Double(vixLevel) ?? 0

        let entry = MarketDataEntry(
            instrument: instrument,
            price: priceValue,
            vixLevel: vixLevelValue,
            volumePercent: volumePercentValue,
            vwapPosition: vwapPosition,
            arrowSignal: arrowSignal,
            keyLevelConfirmed: keyLevelConfirmed,
            patternConfirmed: patternConfirmed,
            timeWindow: timeWindow,
            newsRisk: newsRisk,
            timestamp: Date()
        )

        // Save to UserDefaults for persistence
        if let encoded = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(encoded, forKey: "lastMarketDataEntry")
        }

        lastEntry = entry

        // Update MarketDataService with manual entry
        MarketDataService.shared.updateWithManualEntry(entry)

        return true
    }

    func quickFillLastEntry() {
        guard let entry = lastEntry else { return }
        instrument = entry.instrument
        price = String(format: "%.2f", entry.price)
        vixLevel = String(format: "%.2f", entry.vixLevel)
        volumePercent = String(format: "%.0f", entry.volumePercent)
        vwapPosition = entry.vwapPosition
        arrowSignal = entry.arrowSignal
        keyLevelConfirmed = entry.keyLevelConfirmed
        patternConfirmed = entry.patternConfirmed
        timeWindow = entry.timeWindow
        newsRisk = entry.newsRisk
    }

    func quickFillSampleData() {
        instrument = .vxx
        price = "42.15"
        vixLevel = "18.50"
        volumePercent = "340"
        vwapPosition = .above
        arrowSignal = .bullish
        keyLevelConfirmed = true
        patternConfirmed = true
        timeWindow = .institutional
        newsRisk = .moderate
    }

    func clearForm() {
        instrument = .vxx
        price = ""
        vixLevel = ""
        volumePercent = ""
        vwapPosition = .above
        arrowSignal = .none
        keyLevelConfirmed = false
        patternConfirmed = false
        timeWindow = .morning
        newsRisk = .none
        priceError = nil
        vixLevelError = nil
        volumePercentError = nil
    }

    init() {
        // Load last entry from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "lastMarketDataEntry"),
           let entry = try? JSONDecoder().decode(MarketDataEntry.self, from: data) {
            lastEntry = entry
        }
    }
}

// MARK: - Data Models
struct MarketDataEntry: Codable {
    let instrument: TradingInstrument
    let price: Double
    let vixLevel: Double
    let volumePercent: Double
    let vwapPosition: VWAPPosition
    let arrowSignal: ArrowSignalInput
    let keyLevelConfirmed: Bool
    let patternConfirmed: Bool
    let timeWindow: TimeWindowInput
    let newsRisk: NewsRiskInput
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case instrument
        case price
        case vxxPrice
        case vixLevel
        case volumePercent
        case vwapPosition
        case arrowSignal
        case keyLevelConfirmed
        case patternConfirmed
        case timeWindow
        case newsRisk
        case timestamp
    }

    init(
        instrument: TradingInstrument,
        price: Double,
        vixLevel: Double,
        volumePercent: Double,
        vwapPosition: VWAPPosition,
        arrowSignal: ArrowSignalInput,
        keyLevelConfirmed: Bool,
        patternConfirmed: Bool,
        timeWindow: TimeWindowInput,
        newsRisk: NewsRiskInput,
        timestamp: Date
    ) {
        self.instrument = instrument
        self.price = price
        self.vixLevel = vixLevel
        self.volumePercent = volumePercent
        self.vwapPosition = vwapPosition
        self.arrowSignal = arrowSignal
        self.keyLevelConfirmed = keyLevelConfirmed
        self.patternConfirmed = patternConfirmed
        self.timeWindow = timeWindow
        self.newsRisk = newsRisk
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instrument = try container.decodeIfPresent(TradingInstrument.self, forKey: .instrument) ?? .vxx
        if let priceValue = try container.decodeIfPresent(Double.self, forKey: .price) {
            price = priceValue
        } else if let legacyPrice = try container.decodeIfPresent(Double.self, forKey: .vxxPrice) {
            price = legacyPrice
        } else {
            price = 0
        }
        vixLevel = try container.decodeIfPresent(Double.self, forKey: .vixLevel) ?? 0
        volumePercent = try container.decodeIfPresent(Double.self, forKey: .volumePercent) ?? 0
        vwapPosition = try container.decodeIfPresent(VWAPPosition.self, forKey: .vwapPosition) ?? .above
        arrowSignal = try container.decodeIfPresent(ArrowSignalInput.self, forKey: .arrowSignal) ?? .none
        keyLevelConfirmed = try container.decodeIfPresent(Bool.self, forKey: .keyLevelConfirmed) ?? false
        patternConfirmed = try container.decodeIfPresent(Bool.self, forKey: .patternConfirmed) ?? false
        timeWindow = try container.decodeIfPresent(TimeWindowInput.self, forKey: .timeWindow) ?? .morning
        newsRisk = try container.decodeIfPresent(NewsRiskInput.self, forKey: .newsRisk) ?? .none
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(instrument, forKey: .instrument)
        try container.encode(price, forKey: .price)
        try container.encode(vixLevel, forKey: .vixLevel)
        try container.encode(volumePercent, forKey: .volumePercent)
        try container.encode(vwapPosition, forKey: .vwapPosition)
        try container.encode(arrowSignal, forKey: .arrowSignal)
        try container.encode(keyLevelConfirmed, forKey: .keyLevelConfirmed)
        try container.encode(patternConfirmed, forKey: .patternConfirmed)
        try container.encode(timeWindow, forKey: .timeWindow)
        try container.encode(newsRisk, forKey: .newsRisk)
        try container.encode(timestamp, forKey: .timestamp)
    }

    // Computed ratio
    var ratio: Double {
        instrument == .vxx && vixLevel > 0 ? price / vixLevel : 0
    }

    /// Doc-faithful tier label. Sources the boundary table from `StrategySpec`
    /// so the audit catches any drift. Drops the old "(Rating: N)" notation —
    /// the doc doesn't use a numeric scoring system, so we shouldn't render one
    /// in primary UI.
    var ratioTier: String {
        guard instrument == .vxx else { return "N/A" }
        return StrategySpec.tier(forRatio: ratio).label
    }
}

enum VWAPPosition: String, Codable, CaseIterable {
    case above, below, at

    var displayName: String {
        switch self {
        case .above: return "Above VWAP"
        case .below: return "Below VWAP"
        case .at: return "At VWAP"
        }
    }

    var shortName: String {
        switch self {
        case .above: return "ABOVE"
        case .below: return "BELOW"
        case .at: return "AT"
        }
    }
}

enum ArrowSignalInput: String, Codable, CaseIterable {
    case none, bullish, bearish

    var displayName: String {
        switch self {
        case .none: return "No Arrow"
        case .bullish: return "Bullish (Up)"
        case .bearish: return "Bearish (Down)"
        }
    }

    var color: Color {
        switch self {
        case .none: return DesignSystem.muted
        case .bullish: return DesignSystem.long
        case .bearish: return DesignSystem.short
        }
    }
}

enum TimeWindowInput: String, Codable, CaseIterable {
    case open, preMarket, morning, lunch, afternoonFlex, powerHour, close, institutional, afterHours

    var displayName: String {
        switch self {
        case .open: return "Open (9:35-10:05)"
        case .preMarket: return "Pre-Market"
        case .morning: return "Morning (9:50-10:15)"
        case .lunch: return "Lunch (12:20-12:40)"
        case .afternoonFlex: return "Afternoon Flex (1:30-3:45)"
        case .powerHour: return "Power Hour (3:10-3:25)"
        case .close: return "Close (3:30-3:55)"
        case .institutional: return "Institutional (3:45-4:10)"
        case .afterHours: return "After Hours"
        }
    }

    var shortName: String {
        switch self {
        case .open: return "OPEN"
        case .preMarket: return "PRE"
        case .morning: return "MORN"
        case .lunch: return "LUNCH"
        case .afternoonFlex: return "FLEX"
        case .powerHour: return "POWER"
        case .close: return "CLOSE"
        case .institutional: return "FLOW"
        case .afterHours: return "AFTER"
        }
    }

    /// Per the strategy doc, only three windows are valid VXX entry windows:
    /// Morning Fade (9:50-10:15), Power Hour (3:10-3:25), Institutional Flow
    /// (3:45-4:10). Lunch is explicitly NOT a trading window — the doc lists
    /// it as a "skip trade" example. Open and Close are bookends, not entry
    /// windows. Drift fix 2026-05-14 (previous code accepted `.lunch`).
    var isVXXEntryWindow: Bool {
        switch self {
        case .morning, .powerHour, .institutional:
            return true
        case .open, .preMarket, .lunch, .afternoonFlex, .close, .afterHours:
            return false
        }
    }

    /// Only the doc-published reliability numbers (Morning 85, Power 80,
    /// Institutional 90). Returning fabricated numbers for the other windows
    /// violated [[feedback-tone-rules]] ("no win-rate % in primary UI") and
    /// was strategy drift — the doc doesn't quantify reliability for `.open`,
    /// `.close`, `.lunch`, etc. Drift fix 2026-05-14.
    var reliability: String? {
        switch self {
        case .institutional: return "90%"
        case .morning:       return "85%"
        case .powerHour:     return "80%"
        default:             return nil
        }
    }

    /// Volume requirement for criteria-1 (volume) gate, percent of 30-period
    /// average. Window-dependent per `StrategySpec`: Morning + Power = 200,
    /// Institutional = 300. Returns the gate-1 default 200 for non-entry
    /// windows so the read-out remains sensible, but those don't pass anyway
    /// via `isVXXEntryWindow`.
    var requiredVolumePercent: Double {
        switch self {
        case .morning:       return StrategySpec.morningWindow.volumeThresholdPercent
        case .powerHour:     return StrategySpec.powerHourWindow.volumeThresholdPercent
        case .institutional: return StrategySpec.institutionalWindow.volumeThresholdPercent
        default:             return StrategySpec.morningWindow.volumeThresholdPercent
        }
    }
}

enum TradingInstrument: String, Codable, CaseIterable {
    case vxx
    case spy

    var displayName: String {
        switch self {
        case .vxx: return "VXX"
        case .spy: return "SPY"
        }
    }

    var symbol: String {
        displayName
    }
}

enum NewsRiskInput: String, Codable, CaseIterable {
    case none
    case moderate
    case high

    var displayName: String {
        switch self {
        case .none: return "News: None"
        case .moderate: return "News: Moderate"
        case .high: return "News: High"
        }
    }

    func toNewsRisk() -> MarketData.NewsRisk {
        switch self {
        case .none: return .none
        case .moderate: return .moderate
        case .high: return .high
        }
    }
}
