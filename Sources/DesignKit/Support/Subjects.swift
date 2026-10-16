//
//  Subjects.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The main subject of a picture — the microphone on the desk, the person,
//  the vase — as its own pixels: Vision's foreground-instance mask, every
//  instance it lifts. Measured on a generated podcast cover: the mask is
//  the microphone and its cable and nothing of the window or the desk
//  (12% of the picture), in 0.2 s. A flat colour or a plain gradient lifts
//  nothing.
//
//  Run through Legibility's `VisionRetry`, so a busy Neural Engine is asked
//  again and then answered on the CPU; a search that could not run says so
//  rather than reporting an empty picture.
//

import CoreGraphics
import CoreVideo
import Foundation
import Legibility
import Vision

enum Subjects {

    /// What a search found.
    enum Search: Sendable, Equatable {
        /// The subject's pixels, top row first, the picture's size.
        case found([Bool])
        /// Nothing stands out as a subject.
        case nothing
        /// Vision could not run at all.
        case failed
    }

    /// Mask values at or above this are subject (Vision's mask is soft at the edges).
    static let threshold: Float = 0.5

    /// The subject in `image`.
    static func find(in image: CGImage) -> Search {
        guard let ran = VisionRetry.perform(on: image, { VNGenerateForegroundInstanceMaskRequest() }) else { return .failed }
        guard let result = ran.request.results?.first, !result.allInstances.isEmpty else { return .nothing }
        guard let buffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: ran.handler) else {
            return .failed
        }
        let mask = pixels(of: buffer)
        guard mask.count == image.width * image.height else { return .failed }
        return mask.contains(true) ? .found(mask) : .nothing
    }

    /// A one-channel mask buffer as booleans, top row first.
    static func pixels(of buffer: CVPixelBuffer) -> [Bool] {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return [] }
        let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        let isFloat = CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_OneComponent32Float
        let cutoff = UInt8(threshold * 255)
        var mask = [Bool](repeating: false, count: width * height)
        for y in 0..<height {
            let row = base.advanced(by: y * stride)
            for x in 0..<width {
                mask[y * width + x] = isFloat
                    ? row.load(fromByteOffset: x * 4, as: Float.self) >= threshold
                    : row.load(fromByteOffset: x, as: UInt8.self) >= cutoff
            }
        }
        return mask
    }

    /// The share (`0…1`) of `ink`'s pixels that lie on `subject` (both top
    /// row first, the same size); `nil` when there is no ink.
    static func share(of ink: [Bool], on subject: [Bool]) -> Double? {
        guard ink.count == subject.count else { return nil }
        var inked = 0, on = 0
        for index in ink.indices where ink[index] {
            inked += 1
            if subject[index] { on += 1 }
        }
        return inked == 0 ? nil : Double(on) / Double(inked)
    }
}
