import SwiftUI

// MARK: - Manual Data Entry View
// Educational tool - Enter market data manually from your trading platform

struct ManualDataEntryView: View {
    @StateObject private var viewModel = ManualDataEntryViewModel()
    @State private var showingSaved = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with educational messaging
                    educationalHeader

                    // Manual Entry Form
                    dataEntryForm

                    // Quick Fill Options
                    quickFillSection

                    // Action Buttons
                    actionButtons

                    // Last Entry Preview
                    if let lastEntry = viewModel.lastEntry {
                        lastEntryCard(lastEntry)
                    }
                }
                .padding()
            }
            .navigationTitle("Manual Data Entry")
            .alert("Data Saved", isPresented: $showingSaved) {
                Button("OK") { }
            } message: {
                Text("Market data saved successfully. Use Prompt Coach to analyze this setup.")
            }
        }
    }

    // MARK: - Educational Header
    private var educationalHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Enter Live Data From Your Platform")
                    .font(.headline)
            }

            Text("This app is educational only. Connect to ThinkOrSwim, Schwab, or your trading platform for live data. Enter the values manually below.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Label("No Auto-Trading", systemImage: "xmark.shield")
                    .font(.caption)
                    .foregroundColor(.red)
                Label("You Execute", systemImage: "person.fill.checkmark")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Data Entry Form
    private var dataEntryForm: some View {
        VStack(spacing: 16) {
            Text("Current Market Data")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // VXX Price
            VStack(alignment: .leading, spacing: 8) {
                Label("VXX Price", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("e.g., 42.15", text: $viewModel.vxxPrice)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                if let error = viewModel.vxxPriceError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // VIX Level
            VStack(alignment: .leading, spacing: 8) {
                Label("VIX Level", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("e.g., 18.50", text: $viewModel.vixLevel)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                if let error = viewModel.vixLevelError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Volume Percentage
            VStack(alignment: .leading, spacing: 8) {
                Label("Volume (% of Average)", systemImage: "waveform")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                HStack {
                    TextField("e.g., 340", text: $viewModel.volumePercent)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                if let error = viewModel.volumePercentError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                // Volume indicator
                if let volumePct = Double(viewModel.volumePercent), volumePct > 0 {
                    volumeIndicator(volumePct)
                }
            }

            Divider()

            // VWAP Position
            VStack(alignment: .leading, spacing: 8) {
                Label("Price vs VWAP", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("VWAP Position", selection: $viewModel.vwapPosition) {
                    Text("Above VWAP").tag(VWAPPosition.above)
                    Text("Below VWAP").tag(VWAPPosition.below)
                    Text("At VWAP").tag(VWAPPosition.at)
                }
                .pickerStyle(.segmented)
            }

            // Arrow Signal
            VStack(alignment: .leading, spacing: 8) {
                Label("Arrow Signal", systemImage: "arrow.up.arrow.down.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("Arrow Signal", selection: $viewModel.arrowSignal) {
                    Text("No Arrow").tag(ArrowSignalInput.none)
                    Text("Bullish ⬆").tag(ArrowSignalInput.bullish)
                    Text("Bearish ⬇").tag(ArrowSignalInput.bearish)
                }
                .pickerStyle(.segmented)
            }

            // Time Window
            VStack(alignment: .leading, spacing: 8) {
                Label("Trading Window", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("Window", selection: $viewModel.timeWindow) {
                    Text("Pre-Market").tag(TimeWindowInput.preMarket)
                    Text("Morning (9:50-10:15)").tag(TimeWindowInput.morning)
                    Text("Lunch (12:20-12:40)").tag(TimeWindowInput.lunch)
                    Text("Power Hour (3:10-3:25)").tag(TimeWindowInput.powerHour)
                    Text("Institutional (3:45-4:10)").tag(TimeWindowInput.institutional)
                    Text("After Hours").tag(TimeWindowInput.afterHours)
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Volume Indicator
    private func volumeIndicator(_ volumePct: Double) -> some View {
        HStack(spacing: 8) {
            if volumePct >= 400 {
                Label("MAJOR INSTITUTION", systemImage: "star.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(8)
            } else if volumePct >= 300 {
                Label("INSTITUTIONAL FLOW", systemImage: "star.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
            } else if volumePct >= 200 {
                Label("Standard Entry OK", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Below Threshold - Skip", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Quick Fill Section
    private var quickFillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Fill Options")
                .font(.headline)

            HStack(spacing: 12) {
                Button(action: { viewModel.quickFillLastEntry() }) {
                    Label("Last Entry", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.lastEntry == nil)

                Button(action: { viewModel.quickFillSampleData() }) {
                    Label("Sample Data", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(action: { viewModel.clearForm() }) {
                Label("Clear All Fields", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                if viewModel.saveEntry() {
                    showingSaved = true
                }
            }) {
                Label("Save & Analyze", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValidEntry ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.isValidEntry)

            if !viewModel.isValidEntry {
                Text("Fill all required fields with valid data")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Last Entry Card
    private func lastEntryCard(_ entry: MarketDataEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Entry")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VXX: $\(entry.vxxPrice, specifier: "%.2f")")
                    Text("VIX: \(entry.vixLevel, specifier: "%.2f")")
                    Text("Volume: \(Int(entry.volumePercent))%")
                }
                .font(.subheadline)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.arrowSignal.displayName)
                        .font(.caption)
                        .foregroundColor(entry.arrowSignal.color)
                    Text(entry.timeWindow.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - View Model
@MainActor
class ManualDataEntryViewModel: ObservableObject {
    @Published var vxxPrice: String = ""
    @Published var vixLevel: String = ""
    @Published var volumePercent: String = ""
    @Published var vwapPosition: VWAPPosition = .above
    @Published var arrowSignal: ArrowSignalInput = .none
    @Published var timeWindow: TimeWindowInput = .morning

    @Published var vxxPriceError: String?
    @Published var vixLevelError: String?
    @Published var volumePercentError: String?

    @Published var lastEntry: MarketDataEntry?

    var isValidEntry: Bool {
        validateFields()
        return vxxPriceError == nil &&
               vixLevelError == nil &&
               volumePercentError == nil &&
               !vxxPrice.isEmpty &&
               !vixLevel.isEmpty &&
               !volumePercent.isEmpty
    }

    func validateFields() {
        // Validate VXX Price
        if !vxxPrice.isEmpty {
            if let price = Double(vxxPrice), price > 0, price < 1000 {
                vxxPriceError = nil
            } else {
                vxxPriceError = "Enter valid price (0-1000)"
            }
        }

        // Validate VIX Level
        if !vixLevel.isEmpty {
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
              let vxxPriceValue = Double(vxxPrice),
              let vixLevelValue = Double(vixLevel),
              let volumePercentValue = Double(volumePercent) else {
            return false
        }

        let entry = MarketDataEntry(
            vxxPrice: vxxPriceValue,
            vixLevel: vixLevelValue,
            volumePercent: volumePercentValue,
            vwapPosition: vwapPosition,
            arrowSignal: arrowSignal,
            timeWindow: timeWindow,
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
        vxxPrice = String(format: "%.2f", entry.vxxPrice)
        vixLevel = String(format: "%.2f", entry.vixLevel)
        volumePercent = String(format: "%.0f", entry.volumePercent)
        vwapPosition = entry.vwapPosition
        arrowSignal = entry.arrowSignal
        timeWindow = entry.timeWindow
    }

    func quickFillSampleData() {
        vxxPrice = "42.15"
        vixLevel = "18.50"
        volumePercent = "340"
        vwapPosition = .above
        arrowSignal = .bullish
        timeWindow = .institutional
    }

    func clearForm() {
        vxxPrice = ""
        vixLevel = ""
        volumePercent = ""
        vwapPosition = .above
        arrowSignal = .none
        timeWindow = .morning
        vxxPriceError = nil
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
    let vxxPrice: Double
    let vixLevel: Double
    let volumePercent: Double
    let vwapPosition: VWAPPosition
    let arrowSignal: ArrowSignalInput
    let timeWindow: TimeWindowInput
    let timestamp: Date
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
        case .bullish: return "Bullish ⬆"
        case .bearish: return "Bearish ⬇"
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
    case preMarket, morning, lunch, powerHour, institutional, afterHours

    var displayName: String {
        switch self {
        case .preMarket: return "Pre-Market"
        case .morning: return "Morning (9:50-10:15)"
        case .lunch: return "Lunch (12:20-12:40)"
        case .powerHour: return "Power Hour (3:10-3:25)"
        case .institutional: return "Institutional (3:45-4:10)"
        case .afterHours: return "After Hours"
        }
    }

    var reliability: String {
        switch self {
        case .institutional: return "90%"
        case .morning: return "85%"
        case .powerHour: return "80%"
        case .lunch: return "70%"
        default: return "50%"
        }
    }
}
