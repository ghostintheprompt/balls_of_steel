import Foundation
import ScreenCaptureKit
import AVFoundation
import AppKit
import Combine

// MARK: - ScreenRecorder
//
// Records this app's own window to a ProRes .mov, natively -- ScreenCaptureKit
// for capture, AVAssetWriter for encoding. No external binary: this app is
// sandboxed (`com.apple.security.app-sandbox`), which blocks launching an
// arbitrary subprocess like ffmpeg entirely. ScreenCaptureKit works fine
// inside the sandbox -- it's gated by the system's own Screen Recording
// permission (Privacy & Security), not an app-sandbox entitlement exception.
//
// Purpose per Michael 2026-09-08: record real alerts/trades hitting to show
// his old boss and friends, and to build his own accountability record.

@MainActor
final class ScreenRecorder: NSObject, ObservableObject {
    static let shared = ScreenRecorder()

    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var fileSizeBytes: Int64 = 0
    @Published private(set) var lastError: String?
    @Published private(set) var lastSavedURL: URL?

    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var sessionStarted = false
    private var startedAt: Date?
    private var timer: Timer?
    private var outputURL: URL?
    private let outputQueue = DispatchQueue(label: "app.mdrn.steel.screenrecorder.output")

    static var recordingsDirectory: URL {
        let base = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies")
        let dir = base.appendingPathComponent("Steel Trading Desk Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private override init() {
        super.init()
    }

    func toggle() {
        if isRecording {
            Task { await stop() }
        } else {
            Task { await start() }
        }
    }

    func start() async {
        guard !isRecording else { return }
        lastError = nil

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let window = content.windows.first(where: {
                $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
            }) else {
                lastError = "Could not find the Steel Trading Desk window to capture."
                return
            }

            let filter = SCContentFilter(desktopIndependentWindow: window)
            let scale = Int(NSScreen.main?.backingScaleFactor ?? 2)
            let width = max(Int(window.frame.width) * scale, 2)
            let height = max(Int(window.frame.height) * scale, 2)

            let config = SCStreamConfiguration()
            config.width = width
            config.height = height
            config.showsCursor = true
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            config.queueDepth = 5

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
            let url = Self.recordingsDirectory.appendingPathComponent(
                "Steel Trading Desk \(formatter.string(from: Date())).mov"
            )
            outputURL = url

            let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.proRes422,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true
            guard writer.canAdd(input) else {
                lastError = "Could not configure ProRes video output."
                return
            }
            writer.add(input)
            assetWriter = writer
            videoInput = input
            sessionStarted = false

            let stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: outputQueue)
            try await stream.startCapture()
            self.stream = stream

            isRecording = true
            startedAt = Date()
            elapsedSeconds = 0
            fileSizeBytes = 0
            startTimer()
        } catch {
            lastError = "Recording failed to start: \(error.localizedDescription)"
        }
    }

    func stop() async {
        guard isRecording else { return }
        timer?.invalidate()
        timer = nil

        do {
            try await stream?.stopCapture()
        } catch {
            lastError = "Recording stopped with an error: \(error.localizedDescription)"
        }
        stream = nil

        videoInput?.markAsFinished()
        if let writer = assetWriter {
            await writer.finishWriting()
            if writer.status == .failed, let error = writer.error {
                lastError = "Recording file failed to finalize: \(error.localizedDescription)"
            }
        }

        isRecording = false
        lastSavedURL = outputURL
        assetWriter = nil
        videoInput = nil
        sessionStarted = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }

    private func tick() {
        guard let started = startedAt else { return }
        elapsedSeconds = Date().timeIntervalSince(started)
        if let url = outputURL,
           let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSizeBytes = size
        }
    }

    func revealLastRecordingInFinder() {
        guard let url = lastSavedURL ?? outputURL else {
            NSWorkspace.shared.open(Self.recordingsDirectory)
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

extension ScreenRecorder: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, CMSampleBufferIsValid(sampleBuffer) else { return }
        Task { @MainActor in
            self.appendSample(sampleBuffer)
        }
    }

    @MainActor
    private func appendSample(_ sampleBuffer: CMSampleBuffer) {
        guard let writer = assetWriter, let input = videoInput else { return }
        if !sessionStarted {
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            sessionStarted = true
        }
        if input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }
}

extension ScreenRecorder: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            self.lastError = "Capture stopped unexpectedly: \(error.localizedDescription)"
            self.isRecording = false
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
