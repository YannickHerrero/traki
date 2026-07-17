import AVFoundation
import AVKit
import CoreMedia
import Observation
import SwiftUI
import TrakiKit
import UIKit

/// A view-backed source is required for the sample-buffer PiP content source to
/// become eligible on a physical device. It is visually insignificant in Traki,
/// while keeping the renderer attached to the app's window.
final class TimerPictureInPictureSourceView: UIView {
    override class var layerClass: AnyClass { AVSampleBufferDisplayLayer.self }

    var displayLayer: AVSampleBufferDisplayLayer { layer as! AVSampleBufferDisplayLayer }
}

struct TimerPictureInPictureSource: UIViewRepresentable {
    let pictureInPicture: TimerPictureInPictureController

    func makeUIView(context: Context) -> TimerPictureInPictureSourceView {
        pictureInPicture.sourceView
    }

    func updateUIView(_ uiView: TimerPictureInPictureSourceView, context: Context) {}
}

/// Owns the system Picture in Picture presentation for the active timer.
///
/// PiP has no SwiftUI content source. This coordinator renders a compact timer
/// into a view-backed `AVSampleBufferDisplayLayer` and maps PiP's standard
/// playback control onto the shared `SessionController`, which remains the sole
/// timer state.
@MainActor
@Observable
final class TimerPictureInPictureController: NSObject {
    let sourceView = TimerPictureInPictureSourceView()

    private let sessionController: SessionController
    private var pictureInPictureController: AVPictureInPictureController?
    private var possibleObservation: NSKeyValueObservation?
    private var renderTimer: Timer?
    private var presentationTime: CMTime = .zero

    private(set) var isActive = false
    private(set) var isPossible = false
    private(set) var automaticStartEnabled = false
    private(set) var errorMessage: String?

    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }
    var canEnableAutomaticStart: Bool { isSupported && sessionController.isActive }

    init(sessionController: SessionController) {
        self.sessionController = sessionController
        super.init()
        sourceView.displayLayer.videoGravity = .resizeAspect
    }

    /// Prepares the view-backed source before the user taps PiP. AVKit updates
    /// `isPictureInPicturePossible` asynchronously once that source is eligible.
    func prepare() {
        guard sessionController.isActive, isSupported else { return }
        guard pictureInPictureController == nil else { return }

        presentationTime = .zero
        enqueueFrame(force: true)
        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sourceView.displayLayer,
            playbackDelegate: self)
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = automaticStartEnabled
        pictureInPictureController = controller
        possibleObservation = controller.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] controller, _ in
            let isPossible = controller.isPictureInPicturePossible
            Task { @MainActor [weak self] in
                self?.isPossible = isPossible
            }
        }
    }

    /// Arms or disarms AVKit's system-managed automatic PiP transition. PiP is
    /// started by iOS as the app leaves the foreground; the app must not attempt
    /// to force itself into the background.
    func setAutomaticStartEnabled(_ enabled: Bool) {
        guard enabled else {
            automaticStartEnabled = false
            pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = false
            if !isActive { stopRendering() }
            return
        }
        guard canEnableAutomaticStart else {
            errorMessage = "Picture in Picture is unavailable on this device."
            return
        }

        automaticStartEnabled = true
        errorMessage = nil
        prepare()
        pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = true
        beginRendering()
    }

    /// Stops PiP rendering without changing the running session itself.
    func stop() {
        stopRendering()
        pictureInPictureController?.stopPictureInPicture()
    }

    /// Releases PiP resources once tracking ends. This never saves or pauses a
    /// session; that remains the root coordinator's responsibility.
    func invalidate() {
        stop()
        possibleObservation?.invalidate()
        possibleObservation = nil
        pictureInPictureController?.delegate = nil
        pictureInPictureController = nil
        sourceView.displayLayer.sampleBufferRenderer.flush(removingDisplayedImage: true, completionHandler: nil)
        isActive = false
        isPossible = false
        automaticStartEnabled = false
        presentationTime = .zero
    }

    func dismissError() {
        errorMessage = nil
    }

    private func beginRendering() {
        guard renderTimer == nil else { return }
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.enqueueFrame()
            }
        }
    }

    private func stopRendering() {
        renderTimer?.invalidate()
        renderTimer = nil
    }

    private func enqueueFrame(force: Bool = false) {
        let renderer = sourceView.displayLayer.sampleBufferRenderer
        guard force || renderer.isReadyForMoreMediaData else { return }
        guard let pixelBuffer = makePixelBuffer() else { return }

        var formatDescription: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        ) == noErr, let formatDescription else { return }

        presentationTime = presentationTime + CMTime(value: 1, timescale: 2)
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 2),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid)
        var sampleBuffer: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        ) == noErr, let sampleBuffer else { return }
        markForImmediateDisplay(sampleBuffer)
        renderer.enqueue(sampleBuffer)
        pictureInPictureController?.invalidatePlaybackState()
    }

    private func markForImmediateDisplay(_ sampleBuffer: CMSampleBuffer) {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
              let attachment = (attachments as NSArray).firstObject as? NSMutableDictionary else { return }
        attachment[kCMSampleAttachmentKey_DisplayImmediately] = true
    }

    private func makePixelBuffer() -> CVPixelBuffer? {
        let width = 480
        let height = 270
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        var pixelBuffer: CVPixelBuffer?
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                  kCVPixelFormatType_32BGRA, attributes as CFDictionary,
                                  &pixelBuffer) == kCVReturnSuccess,
              let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer), width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        let mode = sessionController.mode ?? .flashcards
        context.setFillColor(UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(UIColor(mode.baseColor).withAlphaComponent(0.25).cgColor)
        context.fillEllipse(in: CGRect(x: -80, y: -130, width: 640, height: 340))

        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let status = sessionController.isRunning ? "TRACKING" : "PAUSED"
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor(white: 1, alpha: 0.62),
            .kern: 2.2,
            .paragraphStyle: paragraph,
        ]
        ("\(mode.displayName.uppercased())  ·  \(status)" as NSString)
            .draw(in: CGRect(x: 24, y: 40, width: width - 48, height: 28), withAttributes: statusAttributes)

        let clockAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 78, weight: .heavy),
            .foregroundColor: UIColor(mode.baseColor),
            .paragraphStyle: paragraph,
        ]
        (TrakiFormat.clock(sessionController.elapsed()) as NSString)
            .draw(in: CGRect(x: 24, y: 94, width: width - 48, height: 96), withAttributes: clockAttributes)

        let hintAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor(white: 1, alpha: 0.72),
            .paragraphStyle: paragraph,
        ]
        (sessionController.isRunning ? "Use PiP controls to pause" : "Use PiP controls to resume" as NSString)
            .draw(in: CGRect(x: 24, y: 211, width: width - 48, height: 24), withAttributes: hintAttributes)
        return pixelBuffer
    }
}

extension TimerPictureInPictureController: @preconcurrency AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = false
        if !automaticStartEnabled { stopRendering() }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        isActive = false
        if !automaticStartEnabled { stopRendering() }
        errorMessage = error.localizedDescription
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // The tracking host is driven by SessionController and is already ready
        // to display the active timer as soon as the app becomes foregrounded.
        completionHandler(sessionController.isActive)
    }
}

extension TimerPictureInPictureController: @preconcurrency AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        if playing {
            sessionController.resume()
        } else {
            sessionController.pause()
        }
        enqueueFrame(force: true)
        pictureInPictureController.invalidatePlaybackState()
    }

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        !sessionController.isRunning
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    skipByInterval skipInterval: CMTime,
                                    completion completionHandler: @escaping @Sendable () -> Void) {
        completionHandler()
    }

    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        true
    }
}
