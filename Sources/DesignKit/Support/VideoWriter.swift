//
//  VideoWriter.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import AVFoundation
import CoreGraphics
import Foundation

/// H.264 frames into an MP4.
final class VideoWriter {
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let fps: Int
    private let size: CGSize

    init(url: URL, size: CGSize, fps: Int) throws(DesignError) {
        try? FileManager.default.removeItem(at: url)
        do { writer = try AVAssetWriter(outputURL: url, fileType: .mp4) } catch {
            throw .failed("could not start \(url.path): \(error.localizedDescription)")
        }
        input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: Int(size.width * size.height * 6), AVVideoExpectedSourceFrameRateKey: fps],
        ])
        input.expectsMediaDataInRealTime = false
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width), kCVPixelBufferHeightKey as String: Int(size.height),
        ])
        writer.add(input)
        guard writer.startWriting() else { throw .failed("could not start the video: \(writer.error?.localizedDescription ?? "?")") }
        writer.startSession(atSourceTime: .zero)
        self.fps = fps
        self.size = size
    }

    func append(_ image: CGImage, at index: Int) throws(DesignError) {
        while !input.isReadyForMoreMediaData { usleep(2000) }
        guard let pool = adaptor.pixelBufferPool else { throw .failed("no frame buffers for the video") }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        guard let buffer else { throw .failed("no frame buffer for frame \(index)") }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: Bitmaps.sRGB,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        guard adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps))) else {
            throw .failed("frame \(index) could not be written: \(writer.error?.localizedDescription ?? "?")")
        }
    }

    func finish() async throws(DesignError) {
        input.markAsFinished()
        await writer.finishWriting()
        if writer.status != .completed { throw .failed("the video could not be finished: \(writer.error?.localizedDescription ?? "?")") }
    }
}
