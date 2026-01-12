import SwiftUI
import WidgetKit

struct TradingWidgetView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            if entry.isLoading {
                WidgetDesignSystem.LoadingIndicator()
            } else if let error = entry.error {
                WidgetDesignSystem.ErrorIndicator(error: error)
            } else {
                switch family {
                case .systemSmall:
                    SmallWidgetView(entry: entry)
                case .systemMedium:
                    MediumWidgetView(entry: entry)
                case .systemLarge:
                    LargeWidgetView(entry: entry)
                @unknown default:
                    SmallWidgetView(entry: entry) // Fallback to small
                }
            }
        }
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }
} 