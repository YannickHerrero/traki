import AVFoundation
import AVKit
import CoreMedia
import Observation
import TrakiKit
import UIKit

/// Owns the system Picture in Picture presentation for the active timer.
///
/// PiP has no SwiftUI content source. This coordinator renders a compact timer
/// into an `AVSampleBufferDisplayLayer` and maps PiP's standard playback control
/// onto the shared `SessionController`, which remains the sole timer state.
@MainActor
@Observable
final class TimerPictureInPictureController: NSObject {
    private let sessionController: SessionController
    private var pictureInPictureController: AVPictureInPictureController?
    private var displayLayer: AVSampleBufferDisplayLayer?
    private var renderTimer: Timer?
    private var presentationTime: CMTime = .zero

    private(set) var isActive = false
    private(set) var lastError: Error?

    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }
    var canStart: Bool { isSupported && sessionController.isActive && !isActive }

    init(sessionController: SessionController) {
        self.sessionController = sessionController
        super.init()
    }

    func start() {
        guard canStart else { return }
        lastError = nil

        let displayLayer = AVSampleBufferDisplayLayer()
        displayLayer.videoGravity = .resizeAspect
        self.displayLayer = displayLayer
        presentationTime = .zero
        enqueueFrame()

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self)
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        pictureInPictureController = controller
        beginRendering()
        controller.startPictureInPicture()
    }

    /// Stops the PiP surface without changing the running session itself.
    func stop() {
        renderTimer?.invalidate()
        renderTimer = nil
        if pictureInPictureController?.isPictureInPictureActive == true {
            pictureInPictureController?.stopPictureInPicture()
        } else {
            tearDown()
        }
    }

    private func beginRendering() {
        renderTimer?.invalidate()
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.enqueueFrame()
        }
    }

    private func tearDown() {
        renderTimer?.invalidate()
        renderTimer = nil
        pictureInPictureController?.delegate = nil
        pictureInPictureController = nil
        displayLayer?.flushAndRemoveImage()
        displayLayer = nil
        isActive = false
    }

    private func enqueueFrame() {
        guard let displayLayer, displayLayer.isReadyForMoreMediaData else { return }
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
        displayLayer.enqueue(sampleBuffer)
        pictureInPictureController?.invalidatePlaybackState()
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
        tearDown()
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        lastError = error
        tearDown()
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
        enqueueFrame()
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
