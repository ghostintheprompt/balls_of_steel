import SwiftUI
import WidgetKit

// MARK: - Widget Components (Simplified)

struct NoSignalsView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("Scanning for signals...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct WidgetSignalRowView: View {
    let signal: Signal

    var body: some View {
        HStack(spacing: 4) {
            Text(signal.symbol)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
            Text("$\(signal.entry, specifier: "%.2f")")
                .font(.caption2)
            Spacer()
            Text(signal.strategy.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
} 