import SwiftUI

struct DesignSystem {
    // MARK: - Colors
    static let primaryColor = Color.blue
    static let successColor = Color.green
    static let dangerColor = Color.red
    static let warningColor = Color.orange
    static let secondaryColor = Color.gray
    
    // MARK: - Trading Colors
    static let bullishColor = Color.green
    static let bearishColor = Color.red
    static let neutralColor = Color.gray
    
    // MARK: - Spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
    
    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16
    
    // MARK: - Typography
    struct Typography {
        static let titleFont = Font.title2.bold()
        static let headlineFont = Font.headline
        static let bodyFont = Font.body
        static let captionFont = Font.caption
        static let monospacedFont = Font.system(.body, design: .monospaced)
    }
    
    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 4
    
    // MARK: - Animation
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - Reusable Components

struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.spacing)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(DesignSystem.cornerRadius)
            .shadow(color: DesignSystem.cardShadow, radius: DesignSystem.shadowRadius)
    }
}

struct StandardButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return DesignSystem.primaryColor
            case .secondary: return DesignSystem.secondaryColor
            case .danger: return DesignSystem.dangerColor
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .danger: return .white
            case .secondary: return .primary
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(style.foregroundColor)
                .padding(.horizontal, DesignSystem.spacing)
                .padding(.vertical, DesignSystem.smallSpacing)
                .background(style.backgroundColor)
                .cornerRadius(DesignSystem.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriceDisplay: View {
    let price: Double
    let trend: PriceTrend?
    
    enum PriceTrend {
        case up, down, flat
        
        var color: Color {
            switch self {
            case .up: return DesignSystem.bullishColor
            case .down: return DesignSystem.bearishColor
            case .flat: return DesignSystem.neutralColor
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .flat: return "minus"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("$\(price, specifier: "%.2f")")
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(trend?.color ?? .primary)
            
            if let trend = trend {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
        }
    }
}
