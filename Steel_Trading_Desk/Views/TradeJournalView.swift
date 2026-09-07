import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Trade Journal
//
// Simple by default: one line per trade (symbol, outcome, P&L, when).
// Pro options live behind a tap, not in front of you: expanding a row shows
// the full snapshot the desk had at entry (VWAP, ratio, VIX, window) plus
// the screenshot captured at that moment, and a copy button for pasting the
// whole thing into a review conversation. Nothing here is fake -- every
// field comes from the real entry SignalMonitor.startTrade recorded.

struct TradeJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var journal = TradeJournal.shared
    @State private var expandedEntryID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(DesignSystem.hairline).frame(height: 1)

            if journal.entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(journal.entries) { entry in
                            TradeJournalRow(
                                entry: entry,
                                isExpanded: expandedEntryID == entry.id,
                                onToggle: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        expandedEntryID = expandedEntryID == entry.id ? nil : entry.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(DesignSystem.bg.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TRADE JOURNAL")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(1.6)
                    .foregroundColor(DesignSystem.amber)
                Text(journal.entries.isEmpty ? "No trades yet" : "\(journal.entries.count) logged")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            Spacer()
            #if os(macOS)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(DesignSystem.primaryText)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(DesignSystem.bg1)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
            .keyboardShortcut(.cancelAction)
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.bg)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 28))
                .foregroundColor(DesignSystem.muted)
            Text("No trades logged yet.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)
            Text("Entries are captured automatically the moment you take a trade -- entry price, VWAP, ratio, VIX, trading window, and a screenshot of the desk at that moment.")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.faint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private struct TradeJournalRow: View {
    let entry: JournalEntry
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    outcomeDot

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.symbol) · \(entry.strategy)")
                            .font(DesignSystem.Typography.bodyFont)
                            .foregroundColor(DesignSystem.primaryText)
                        Text(entry.timestamp, style: .relative)
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.faint)
                    }

                    Spacer()

                    pnlText

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DesignSystem.muted)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                detail
            }
        }
        .background(DesignSystem.panel)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
    }

    private var outcomeDot: some View {
        Circle()
            .fill(outcomeColor)
            .frame(width: 8, height: 8)
    }

    private var outcomeColor: Color {
        switch entry.outcome {
        case "win": return DesignSystem.long
        case "loss": return DesignSystem.short
        default: return DesignSystem.amber
        }
    }

    private var pnlText: some View {
        Group {
            if let pnl = entry.realizedPnL {
                Text(String(format: "%+.2f", pnl))
                    .foregroundColor(pnl >= 0 ? DesignSystem.long : DesignSystem.short)
            } else {
                Text("OPEN")
                    .foregroundColor(DesignSystem.amber)
            }
        }
        .font(DesignSystem.Typography.captionFont)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle().fill(DesignSystem.hairline).frame(height: 1)

            VStack(spacing: 6) {
                detailRow("Entry", String(format: "$%.2f", entry.entryPrice))
                detailRow("VWAP", String(format: "$%.2f", entry.vwap))
                detailRow("Ratio", String(format: "%.3f", entry.vxxVixRatio))
                detailRow("VIX", String(format: "%.2f", entry.vixLevel))
                detailRow("Window", entry.tradingWindow)
                if let exitPrice = entry.exitPrice {
                    detailRow("Exit", String(format: "$%.2f", exitPrice))
                }
            }

            #if os(macOS)
            if TradeEvidenceCapture.screenshotExists(for: entry.idempotencyKey) {
                screenshotThumbnail
            }
            #endif

            Button {
                copyReviewText()
            } label: {
                Label("Copy for Review", systemImage: "doc.on.clipboard")
                    .font(DesignSystem.Typography.captionFont)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(DesignSystem.amber)
        }
        .padding(12)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.0)
                .foregroundColor(DesignSystem.mutedText)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.text2)
        }
    }

    #if os(macOS)
    private var screenshotThumbnail: some View {
        let url = TradeEvidenceCapture.screenshotURL(for: entry.idempotencyKey)
        return Group {
            if let image = NSImage(contentsOf: url) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius).stroke(DesignSystem.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Open full-size screenshot")
            }
        }
    }
    #endif

    private func copyReviewText() {
        let pnlStr = entry.realizedPnL.map { String(format: "%+.2f", $0) } ?? "open"
        let text = """
        \(entry.symbol) · \(entry.strategy)
        Entry: $\(String(format: "%.2f", entry.entryPrice)) | VWAP: $\(String(format: "%.2f", entry.vwap))
        Window: \(entry.tradingWindow) | Ratio: \(String(format: "%.3f", entry.vxxVixRatio)) | VIX: \(String(format: "%.2f", entry.vixLevel))
        Outcome: \(entry.outcome.uppercased()) | P&L: \(pnlStr)
        Time: \(DateFormatter.localizedString(from: entry.timestamp, dateStyle: .short, timeStyle: .short))
        """
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
}
