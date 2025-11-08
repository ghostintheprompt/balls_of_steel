import SwiftUI
import WidgetKit

// MARK: - Main Widget Views
struct SmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: WidgetDesignSystem.smallSpacing) {
            // Market status header
            WidgetDesignSystem.MarketStatusIndicator(
                phase: entry.currentPhase,
                date: entry.date
            )
            
            Divider()
            
            // Signal content
            if let signal = entry.prioritySignals.first {
                WidgetDesignSystem.CompactSignalRow(signal: signal)
            } else {
                WidgetDesignSystem.EmptyState()
            }
        }
        .widgetPadding(for: .systemSmall)
        .widgetStyle()
        .widgetAnimation()
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: WidgetDesignSystem.smallSpacing) {
            // Market status header
            WidgetDesignSystem.MarketStatusIndicator(
                phase: entry.currentPhase,
                date: entry.date
            )
            
            Divider()
            
            // Signals list
            if !entry.signals.isEmpty {
                let topSignals = entry.signals.topSignals(for: .systemMedium)
                
                ForEach(Array(topSignals.enumerated()), id: \.element.id) { index, signal in
                    WidgetDesignSystem.CompactSignalRow(signal: signal)
                    
                    if index < topSignals.count - 1 {
                        Divider()
                            .opacity(0.5)
                    }
                }
            } else {
                WidgetDesignSystem.EmptyState()
            }
            
            Spacer(minLength: 0)
        }
        .widgetPadding(for: .systemMedium)
        .widgetStyle()
        .widgetAnimation()
    }
}

struct LargeWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: WidgetDesignSystem.defaultSpacing) {
            // Enhanced header with time
            HStack {
                WidgetDesignSystem.MarketStatusIndicator(
                    phase: entry.currentPhase,
                    date: entry.date
                )
                
                Spacer()
                
                Text(entry.timeDisplay)
                    .font(WidgetDesignSystem.Typography.labelFont)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Detailed signals list
            if !entry.signals.isEmpty {
                let topSignals = entry.signals.topSignals(for: .systemLarge)
                
                ScrollView {
                    LazyVStack(spacing: WidgetDesignSystem.smallSpacing) {
                        ForEach(topSignals) { signal in
                            DetailedSignalRow(signal: signal)
                        }
                    }
                }
            } else {
                VStack {
                    WidgetDesignSystem.EmptyState()
                    
                    Text(entry.statusMessage)
                        .font(WidgetDesignSystem.Typography.labelFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer(minLength: 0)
        }
        .widgetPadding(for: .systemLarge)
        .widgetStyle()
        .widgetAnimation()
    }
}

// MARK: - Enhanced Signal Row for Large Widget
struct DetailedSignalRow: View {
    let signal: Signal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: WidgetDesignSystem.tinySpacing) {
                HStack {
                    Text(signal.displaySymbol)
                        .font(WidgetDesignSystem.Typography.symbolFont)
                        .foregroundColor(.primary)
                    
                    Text(signal.strategy.shortName)
                        .font(WidgetDesignSystem.Typography.labelFont)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: WidgetDesignSystem.smallSpacing) {
                    priceLabel("Entry", signal.entry, .primary)
                    priceLabel("Stop", signal.stop, WidgetDesignSystem.dangerColor)
                    priceLabel("Target", signal.target, WidgetDesignSystem.successColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: WidgetDesignSystem.tinySpacing) {
                Circle()
                    .fill(signal.strategy.color)
                    .frame(width: WidgetDesignSystem.indicatorSize, height: WidgetDesignSystem.indicatorSize)
                
                Text(signal.compactRiskReward)
                    .font(WidgetDesignSystem.Typography.labelFont)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, WidgetDesignSystem.tinySpacing)
    }
    
    private func priceLabel(_ label: String, _ price: Double, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            Text("$\(price, specifier: "%.2f")")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
    }
} 