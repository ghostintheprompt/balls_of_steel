import SwiftUI
import StoreKit

struct UnlockView: View {
    @StateObject private var storeKit = StoreKitService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            DesignSystem.backgroundTop.ignoresSafeArea()
            
            VStack(spacing: 32) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(DesignSystem.mutedText)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding()

                SteelDeskMark(size: 100)
                
                VStack(spacing: 8) {
                    Text("INSTITUTIONAL PRO")
                        .font(DesignSystem.Typography.heroFont)
                        .foregroundColor(DesignSystem.primaryText)
                    
                    Text("Unlock the supreme power of the tape.")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(icon: "bolt.fill", title: "SCHWAB API INTEGRATION", detail: "Automated real-time data flow.")
                    featureRow(icon: "books.vertical.fill", title: "SUPREME PROMPT LIBRARY", detail: "Institutional Flow & Power Hour prompts.")
                    featureRow(icon: "chart.pie.fill", title: "UNLIMITED JOURNALING", detail: "Complete trade history & analytics.")
                    featureRow(icon: "shield.checkered", title: "HARD-EXIT DISCIPLINE", detail: "Automated risk management alerts.")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                if storeKit.hasProUnlock {
                    Text("PRO UNLOCKED")
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.successColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.successColor.opacity(0.12))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 16) {
                        if let product = storeKit.products.first {
                            Button(action: {
                                Task {
                                    try? await storeKit.purchase()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text("UNLOCK NOW")
                                        .font(DesignSystem.Typography.headlineFont)
                                    Text(product.displayPrice)
                                        .font(DesignSystem.Typography.captionFont)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.primaryColor)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button("Restore Purchases") {
                            Task {
                                await storeKit.restorePurchases()
                            }
                        }
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    }
                    .padding(.horizontal, 32)
                }
                
                Text("One-time purchase. No subscriptions. No bullshit.")
                    .font(DesignSystem.Typography.labelFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .padding(.bottom, 24)
            }
        }
    }
    
    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.primaryColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)
                Text(detail)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
        }
    }
}
