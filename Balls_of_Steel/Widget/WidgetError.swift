import Foundation

enum WidgetError: LocalizedError {
    case marketClosed
    case noData
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .marketClosed:
            return "Market is currently closed"
        case .noData:
            return "No trading signals available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
} 