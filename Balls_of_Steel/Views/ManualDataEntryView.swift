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
                        dataEntryForm
                        quickFillSection
                        actionButtons

                        if let lastEntry = viewModel.lastEntry {
                            lastEntryCard(lastEntry)
                        }
                    }
                    .padding(20)
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

            Text("Post the chart. Let the app read it.")
                .font(DesignSystem.Typography.titleFont)
                .foregroundColor(DesignSystem.primaryText)

            Text("Pull the setup from ThinkOrSwim or Schwab. No auto-feed. No fake certainty. You choose the numbers, and the desk decides whether it deserves attention.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)

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
                    .cornerRadius(8)
            } else if volumePct >= 300 {
                Label("INSTITUTIONAL FLOW", systemImage: "star.fill")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.dangerColor)
                    .cornerRadius(8)
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
                RoundedRectangle(cornerRadius: 8)
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
                // Below 1.35 - Red zone
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(height: 8)
                    .overlay(
                        Text("1.35")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .offset(x: -15, y: -10)
                    )

                // 1.35-1.45 - Orange zone
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(height: 8)
                    .overlay(
                        Text("1.45")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .offset(x: -15, y: -10)
                    )

                // 1.45-1.55 - Cyan zone
                Rectangle()
                    .fill(Color.cyan.opacity(0.3))
                    .frame(height: 8)
                    .overlay(
                        Text("1.55")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .offset(x: -15, y: -10)
                    )

                // 1.55-1.60 - Yellow zone
                Rectangle()
                    .fill(Color.yellow.opacity(0.5))
                    .frame(height: 8)
                    .overlay(
                        Text("1.60")
                            .font(.system(size: 8))
                            .foregroundColor(.black)
                            .offset(x: -15, y: -10)
                    )

                // Above 1.60 - Green zone
                Rectangle()
                    .fill(Color.green.opacity(0.4))
                    .frame(height: 8)
            }
            .cornerRadius(4)
            .overlay(
                // Current position indicator
                GeometryReader { geometry in
                    let position = ratioToPosition(ratio: currentRatio, width: geometry.size.width)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .position(x: position, y: 4)
                }
            )
        }
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
        case .premiumFade: return DesignSystem.bullishColor
        case .strongFade: return DesignSystem.primaryColor
        case .normalFade: return Color.cyan
        case .weakFade: return DesignSystem.warningColor
        case .noFade: return DesignSystem.bearishColor
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
                    .background(viewModel.isValidEntry ? DesignSystem.primaryColor : DesignSystem.secondaryColor.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(14)
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
                        .foregroundColor(entry.instrument == .vxx ? (entry.ratio >= 1.60 ? DesignSystem.bullishColor : entry.ratio >= 1.45 ? Color.cyan : DesignSystem.warningColor) : DesignSystem.mutedText)
                    Text(entry.arrowSignal.displayName)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(entry.arrowSignal.color)
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
        try container.encode(timeWindow, forKey: .timeWindow)
        try container.encode(newsRisk, forKey: .newsRisk)
        try container.encode(timestamp, forKey: .timestamp)
    }

    // Computed ratio
    var ratio: Double {
        instrument == .vxx && vixLevel > 0 ? price / vixLevel : 0
    }

    var ratioTier: String {
        guard instrument == .vxx else { return "N/A" }
        if ratio >= 1.60 {
            return "Premium Fade (Rating: 3)"
        } else if ratio >= 1.55 {
            return "Strong Fade (Rating: 2)"
        } else if ratio >= 1.45 {
            return "Normal Fade (Rating: 1)"
        } else if ratio >= 1.35 {
            return "Weak Fade"
        } else {
            return "No Fade"
        }
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
        case .none: return .gray
        case .bullish: return .green
        case .bearish: return .red
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

    var reliability: String {
        switch self {
        case .institutional: return "90%"
        case .morning: return "85%"
        case .powerHour: return "80%"
        case .afternoonFlex: return "72%"
        case .open, .close: return "78%"
        case .lunch: return "70%"
        default: return "50%"
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
