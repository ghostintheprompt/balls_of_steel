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
            marketService.subscribeToQuotes(symbol)
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
            trades: quote.lastSize
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
}