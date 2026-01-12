import Foundation
import Combine

@MainActor
class MarketDataService: ObservableObject {
    static let shared = MarketDataService()
    @Published private(set) var latestQuotes: [String: Quote] = [:]
    private let marketService = SchwabService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for quotes
    private var quoteCache: [String: Quote] = [:]
    private var subscribers: [String: Int] = [:]
    
    // VWAP calculator
    private let vwapCalculator = VWAPCalculator.shared
    
    // Publishers for real-time data
    private var marketDataSubjects: [String: CurrentValueSubject<MarketData?, Never>] = [:]
    
    func subscribeToMarketData(symbol: String) -> AnyPublisher<MarketData?, Never> {
        if marketDataSubjects[symbol] == nil {
            marketDataSubjects[symbol] = CurrentValueSubject(nil)
            subscribers[symbol, default: 0] += 1
            
            // Subscribe to real-time quotes
            marketService.subscribeToQuotes(symbol: symbol)
                .sink { [weak self] quote in
                    self?.handleQuoteUpdate(symbol: symbol, quote: quote)
                }
                .store(in: &cancellables)
        }
        
        return marketDataSubjects[symbol]?.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }
    
    private func handleQuoteUpdate(symbol: String, quote: Quote) {
        let vwap = vwapCalculator.calculate(price: quote.price, volume: quote.volume)
        
        let marketData = MarketData(
            quote: quote,
            vwap: vwap,
            volume: quote.volume,
            trades: quote.lastSize,
            ivRank: 0.0,
            daysToEarnings: 30,
            hasFundamentalNews: false,
            vix: 15.0,
            vixDailyChange: 0.0,
            spyDailyChange: 0.0,
            hasZDTEOptions: false,
            averageVolume: quote.volume,
            averageOptionsVolume: 0,
            optionsVolume: 0,
            rsi: 50.0,
            emaBreakout: false,
            vwapBreakout: false,
            isWeeklyExpiration: false,
            otmProbability: 0.5,
            minutesSinceMarketOpen: 30,
            marketOpen: Date().addingTimeInterval(-30*60).timeIntervalSince1970,
            detectedPattern: nil,
            technicalIndicators: nil,
            detectedArrowSignal: nil
        )
        
        marketDataSubjects[symbol]?.send(marketData)
        quoteCache[symbol] = quote
    }
    
    // For non-streaming access (fallback)
    func latestQuote(symbol: String) -> Quote? {
        quoteCache[symbol]
    }
    
    // Called by SchwabService to update cache
    func updateQuoteCache(_ quote: Quote) {
        quoteCache[quote.symbol] = quote
    }
    
    // Missing getScanner method for SignalScanner
    func getScanner() -> AnyPublisher<MarketData, Never> {
        // Scan multiple symbols for signals
        let symbols = ["SPY", "QQQ", "IWM", "AAPL", "MSFT", "GOOGL", "AMZN", "TSLA"]
        
        return Publishers.MergeMany(
            symbols.map { symbol in
                subscribeToMarketData(symbol: symbol)
                    .compactMap { $0 }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // Cleanup
    func unsubscribe(symbol: String) {
        subscribers[symbol, default: 0] -= 1
        if subscribers[symbol] == 0 {
            marketDataSubjects.removeValue(forKey: symbol)
            subscribers.removeValue(forKey: symbol)
        }
    }

    // MARK: - Manual Data Entry Support
    /// Educational mode - Updates market data from manual user input
    /// This is the primary data source for the educational app
    func updateWithManualEntry(_ entry: MarketDataEntry) {
        // Convert manual entry to Quote
        let vwap = entry.vwapPosition == .above ? entry.vxxPrice - 0.20 : entry.vxxPrice + 0.20
        let vxxQuote = Quote(
            symbol: "VXX",
            price: entry.vxxPrice,
            volume: Int(entry.volumePercent) * 10_000, // Approximate volume
            vwap: vwap,
            previousClose: entry.vxxPrice * 0.98, // Approximate
            timestamp: entry.timestamp,
            recentCandles: [] // Manual entry doesn't provide candles
        )

        let vixQuote = Quote(
            symbol: "VIX",
            price: entry.vixLevel,
            volume: 0,
            vwap: entry.vixLevel,
            previousClose: entry.vixLevel * 0.98,
            timestamp: entry.timestamp,
            recentCandles: []
        )

        // Create MarketData with arrow signal
        let arrowSignal: ArrowSignal? = {
            switch entry.arrowSignal {
            case .bullish:
                return ArrowSignal(
                    direction: .bullish,
                    timestamp: entry.timestamp,
                    volumeConfirmation: volumeConfirmation(for: entry.volumePercent),
                    technicalConfluence: [],
                    timeWindow: timeWindow(for: entry.timeWindow),
                    strength: signalStrength(volume: entry.volumePercent)
                )
            case .bearish:
                return ArrowSignal(
                    direction: .bearish,
                    timestamp: entry.timestamp,
                    volumeConfirmation: volumeConfirmation(for: entry.volumePercent),
                    technicalConfluence: [],
                    timeWindow: timeWindow(for: entry.timeWindow),
                    strength: signalStrength(volume: entry.volumePercent)
                )
            case .none:
                return nil
            }
        }()

        let marketData = MarketData(
            quote: vxxQuote,
            vwap: vwap,
            volume: Int(entry.volumePercent) * 10_000,
            trades: 0,
            ivRank: 0.0,
            daysToEarnings: 30,
            hasFundamentalNews: false,
            vix: entry.vixLevel,
            vixDailyChange: 0.0,
            spyDailyChange: 0.0,
            hasZDTEOptions: false,
            averageVolume: 1_000_000,
            averageOptionsVolume: 0,
            optionsVolume: 0,
            rsi: 50.0,
            emaBreakout: false,
            vwapBreakout: false,
            isWeeklyExpiration: false,
            otmProbability: 0.5,
            minutesSinceMarketOpen: 30,
            marketOpen: Date().addingTimeInterval(-30*60).timeIntervalSince1970,
            detectedPattern: nil,
            technicalIndicators: nil,
            detectedArrowSignal: arrowSignal
        )

        // Update cache and notify subscribers
        quoteCache["VXX"] = vxxQuote
        quoteCache["VIX"] = vixQuote
        marketDataSubjects["VXX"]?.send(marketData)
        latestQuotes["VXX"] = vxxQuote
        latestQuotes["VIX"] = vixQuote
    }

    // Helper: Volume confirmation level
    private func volumeConfirmation(for volumePct: Double) -> ArrowSignal.VolumeConfirmation {
        if volumePct >= 400 {
            return .majorInstitution
        } else if volumePct >= 300 {
            return .institutional
        } else if volumePct >= 200 {
            return .standard
        } else {
            return .none
        }
    }

    // Helper: Signal strength
    private func signalStrength(volume: Double) -> ArrowSignal.SignalStrength {
        if volume >= 300 {
            return .strong
        } else if volume >= 200 {
            return .moderate
        } else {
            return .weak
        }
    }

    // Helper: Time window conversion
    private func timeWindow(for input: TimeWindowInput) -> ArrowSignal.TimeWindow {
        switch input {
        case .morning:
            return .morningFade
        case .lunch:
            return .lunchDrift
        case .powerHour:
            return .institutionalFlow // Map to closest available
        case .institutional:
            return .institutionalFlow
        default:
            return .other
        }
    }
}