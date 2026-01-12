import SwiftUI
import WidgetKit

// MARK: - Widget Design System
struct WidgetDesignSystem {
    // MARK: - Spacing
    static let tinySpacing: CGFloat = 2
    static let smallSpacing: CGFloat = 4
    static let defaultSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 12
    
    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 6
    static let capsuleRadius: CGFloat = 100
    
    // MARK: - Colors
    static let primaryColor = Color.blue
    static let successColor = Color.green
    static let dangerColor = Color.red
    static let warningColor = Color.orange
    static let mutedColor = Color.secondary
    
    // MARK: - Typography
    struct Typography {
        static let symbolFont = Font.system(.caption, design: .monospaced).weight(.bold)
        static let priceFont = Font.caption2
        static let statusFont = Font.caption.weight(.medium)
        static let labelFont = Font.caption2
    }
    
    // MARK: - Widget Specific Constants
    static let smallWidgetPadding: CGFloat = 8
    static let mediumWidgetPadding: CGFloat = 12
    static let indicatorSize: CGFloat = 8
    static let maxSignalsInWidget = 3
}

// MARK: - Widget Components
extension WidgetDesignSystem {
    
    struct CompactSignalRow: View {
        let signal: Signal
        
        var body: some View {
            HStack(spacing: WidgetDesignSystem.smallSpacing) {
                // Symbol
                Text(signal.symbol)
                    .font(WidgetDesignSystem.Typography.symbolFont)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Price
                Text("$\(signal.entry, specifier: "%.2f")")
                    .font(WidgetDesignSystem.Typography.priceFont)
                    .foregroundColor(.secondary)
                
                // Strategy indicator
                Circle()
                    .fill(signal.strategy.color)
                    .frame(width: WidgetDesignSystem.indicatorSize, height: WidgetDesignSystem.indicatorSize)
            }
            .padding(.vertical, WidgetDesignSystem.tinySpacing)
        }
    }
    
    struct MarketStatusIndicator: View {
        let phase: MarketPhase
        let date: Date
        
        private var isMarketOpen: Bool {
            date.isWithinTradingHours()
        }
        
        var body: some View {
            HStack(spacing: WidgetDesignSystem.smallSpacing) {
                // Status icon
                Image(systemName: isMarketOpen ? "clock" : "clock.badge.exclamationmark")
                    .foregroundColor(isMarketOpen ? WidgetDesignSystem.successColor : WidgetDesignSystem.dangerColor)
                    .font(.caption2)
                
                // Phase text
                Text(phase.rawValue)
                    .font(WidgetDesignSystem.Typography.statusFont)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Phase indicator
                if isMarketOpen {
                    HStack(spacing: WidgetDesignSystem.tinySpacing) {
                        Circle()
                            .fill(phase.color)
                            .frame(width: WidgetDesignSystem.indicatorSize, height: WidgetDesignSystem.indicatorSize)
                        Text(phase.rawValue)
                            .font(WidgetDesignSystem.Typography.labelFont)
                            .foregroundColor(phase.color)
                    }
                    .padding(.horizontal, WidgetDesignSystem.smallSpacing)
                    .padding(.vertical, WidgetDesignSystem.tinySpacing)
                    .background(
                        Capsule()
                            .fill(phase.color.opacity(0.1))
                    )
                }
            }
        }
    }
    
    struct ErrorIndicator: View {
        let error: Error
        
        var body: some View {
            VStack(spacing: WidgetDesignSystem.smallSpacing) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(WidgetDesignSystem.dangerColor)
                    .font(.caption)
                
                Text("Widget Error")
                    .font(WidgetDesignSystem.Typography.statusFont)
                
                Text(error.localizedDescription)
                    .font(WidgetDesignSystem.Typography.labelFont)
                    .foregroundColor(WidgetDesignSystem.mutedColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(WidgetDesignSystem.defaultSpacing)
        }
    }
    
    struct LoadingIndicator: View {
        var body: some View {
            VStack(spacing: WidgetDesignSystem.smallSpacing) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Loading signals...")
                    .font(WidgetDesignSystem.Typography.labelFont)
                    .foregroundColor(WidgetDesignSystem.mutedColor)
            }
            .padding(WidgetDesignSystem.defaultSpacing)
        }
    }
    
    struct EmptyState: View {
        var body: some View {
            HStack(spacing: WidgetDesignSystem.smallSpacing) {
                Image(systemName: "magnifyingglass")
                    .font(.caption2)
                    .foregroundColor(WidgetDesignSystem.mutedColor)
                
                Text("Scanning for signals...")
                    .font(WidgetDesignSystem.Typography.labelFont)
                    .foregroundColor(WidgetDesignSystem.mutedColor)
            }
        }
    }
}
