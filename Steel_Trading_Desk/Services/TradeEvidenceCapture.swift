#if os(macOS)
import AppKit

// MARK: - TradeEvidenceCapture
//
// Grabs a screenshot of the desk at the moment a trade is entered so there's
// a real record to check against if something goes wrong. Uses the window's
// own view-rendering (bitmapImageRepForCachingDisplay), not screen capture --
// that avoids the macOS Screen Recording permission prompt entirely, since
// this only ever needs the app's own already-rendered content, not the
// screen. Paired 1:1 with a JournalEntry via `idempotencyKey` as the shared
// filename key, so no schema change was needed on JournalEntry itself.

enum TradeEvidenceCapture {
    static func captureAndSave(idempotencyKey: String) {
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }),
              let contentView = window.contentView else { return }

        let bounds = contentView.bounds
        guard bounds.width > 0, bounds.height > 0,
              let rep = contentView.bitmapImageRepForCachingDisplay(in: bounds) else { return }
        contentView.cacheDisplay(in: bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }

        let directory = evidenceDirectory()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: screenshotURL(for: idempotencyKey))
    }

    static func screenshotURL(for idempotencyKey: String) -> URL {
        evidenceDirectory().appendingPathComponent("\(idempotencyKey).png")
    }

    static func screenshotExists(for idempotencyKey: String) -> Bool {
        FileManager.default.fileExists(atPath: screenshotURL(for: idempotencyKey).path)
    }

    private static func evidenceDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Steel Trading Desk", isDirectory: true)
            .appendingPathComponent("TradeEvidence", isDirectory: true)
    }
}
#endif
