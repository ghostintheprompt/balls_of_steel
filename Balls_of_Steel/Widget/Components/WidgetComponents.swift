import SwiftUI
import WidgetKit

// MARK: - Legacy Widget Components (Deprecated)
// These components are kept for backward compatibility
// New widgets should use WidgetDesignSystem components

@available(*, deprecated, message: "Use WidgetDesignSystem.EmptyState instead")
struct NoSignalsView: View {
    var body: some View {
        WidgetDesignSystem.EmptyState()
    }
}

@available(*, deprecated, message: "Use WidgetDesignSystem.CompactSignalRow instead") 
struct WidgetSignalRowView: View {
    let signal: Signal
    
    var body: some View {
        WidgetDesignSystem.CompactSignalRow(signal: signal)
    }
} 