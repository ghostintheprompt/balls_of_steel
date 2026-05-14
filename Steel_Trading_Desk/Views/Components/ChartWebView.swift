import SwiftUI
import WebKit

// MARK: - TradingView Chart Embed (Phase 5)
//
// Wraps the TradingView Advanced Chart widget in a WKWebView. Free, no auth,
// 15-minute delayed for cash equities. Status footer in the host view discloses
// the delay. Symbol prefix selects the venue (TradingView convention):
//   - VXX → "AMEX:VXX"
//   - VIX → "TVC:VIX"
//   - SPY → "AMEX:SPY"

struct ChartWebView: View {
    let symbol: String
    let interval: String
    let theme: String

    init(symbol: String, interval: String = "5", theme: String = "dark") {
        self.symbol = symbol
        self.interval = interval
        self.theme = theme
    }

    var body: some View {
        ChartWebViewBridge(symbol: symbol, interval: interval, theme: theme)
    }
}

// MARK: - Convenience symbol resolver

extension ChartWebView {
    static func tradingViewSymbol(for instrument: TradingInstrument) -> String {
        switch instrument {
        case .vxx: return "AMEX:VXX"
        case .spy: return "AMEX:SPY"
        }
    }
}

// MARK: - HTML payload (shared between platforms)

private func chartHTML(symbol: String, interval: String, theme: String) -> String {
    """
    <!doctype html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
            html, body, #tv { height: 100%; margin: 0; background: #000; }
        </style>
    </head>
    <body>
        <div id="tv"></div>
        <script src="https://s3.tradingview.com/tv.js"></script>
        <script>
            new TradingView.widget({
                autosize: true,
                symbol: "\(symbol)",
                interval: "\(interval)",
                timezone: "America/New_York",
                theme: "\(theme)",
                style: "1",
                locale: "en",
                toolbar_bg: "#000000",
                enable_publishing: false,
                hide_side_toolbar: true,
                hide_legend: false,
                hide_top_toolbar: false,
                container_id: "tv",
                studies: [
                    "VWAP@tv-basicstudies",
                    "MASimple@tv-basicstudies",
                    "Volume@tv-basicstudies"
                ]
            });
        </script>
    </body>
    </html>
    """
}

#if os(iOS)
import UIKit

private struct ChartWebViewBridge: UIViewRepresentable {
    let symbol: String
    let interval: String
    let theme: String

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        loadHTML(into: web)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        if context.coordinator.lastSymbol != symbol
            || context.coordinator.lastInterval != interval
            || context.coordinator.lastTheme != theme {
            loadHTML(into: web)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastSymbol: String = ""
        var lastInterval: String = ""
        var lastTheme: String = ""
    }

    private func loadHTML(into web: WKWebView) {
        let html = chartHTML(symbol: symbol, interval: interval, theme: theme)
        web.loadHTMLString(html, baseURL: URL(string: "https://www.tradingview.com"))
    }
}
#elseif os(macOS)
import AppKit

private struct ChartWebViewBridge: NSViewRepresentable {
    let symbol: String
    let interval: String
    let theme: String

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.setValue(false, forKey: "drawsBackground")
        loadHTML(into: web)
        return web
    }

    func updateNSView(_ web: WKWebView, context: Context) {
        loadHTML(into: web)
    }

    private func loadHTML(into web: WKWebView) {
        let html = chartHTML(symbol: symbol, interval: interval, theme: theme)
        web.loadHTMLString(html, baseURL: URL(string: "https://www.tradingview.com"))
    }
}
#endif
