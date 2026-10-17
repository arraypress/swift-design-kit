//
//  Bitmaps.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  sRGB, 8-bit, premultiplied — the one bitmap every render and measurement
//  uses, so the same design gives the same bytes.
//

import CoreGraphics
import CoreImage
import Foundation

enum Bitmaps {

    static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    /// A clear bitmap context.
    static func context(width: Int, height: Int) -> CGContext? {
        guard width > 0, height > 0 else { return nil }
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.interpolationQuality = .high
        return context
    }

    /// `draw` run into a fresh `width`×`height` bitmap.
    static func image(width: Int, height: Int, _ draw: (CGContext) -> Void) -> CGImage? {
        guard let context = context(width: width, height: height) else { return nil }
        draw(context)
        return context.makeImage()
    }

    /// `image` covering (`fill`) or inside (`fit`) a `width`×`height` bitmap,
    /// centred on `focus` (fractions) when it crops.
    static func fitted(_ image: CGImage, width: Int, height: Int, mode: FitMode, focus: [Double]? = nil,
                       backdrop: CGColor? = nil) -> CGImage? {
        Bitmaps.image(width: width, height: height) { context in
            if let backdrop {
                context.setFillColor(backdrop)
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
            context.draw(image, in: placement(of: image, in: CGRect(x: 0, y: 0, width: width, height: height), mode: mode,
                                              focus: focus, flippedY: true))
        }
    }

    /// Where `image` is drawn in `frame` for `mode`. With `flippedY` the frame
    /// is in CoreGraphics space and `focus` still reads from the top.
    static func placement(of image: CGImage, in frame: CGRect, mode: FitMode, focus: [Double]?, flippedY: Bool) -> CGRect {
        let iw = Double(image.width), ih = Double(image.height)
        let scale = mode == .fill ? max(frame.width / iw, frame.height / ih) : min(frame.width / iw, frame.height / ih)
        let w = iw * scale, h = ih * scale
        let fx = focus?.first ?? 0.5, fy = focus?.last ?? 0.5
        var x = frame.minX + (frame.width - w) * fx
        var y = frame.minY + (frame.height - h) * (flippedY ? 1 - fy : fy)
        if mode == .fit {
            x = frame.midX - w / 2
            y = frame.midY - h / 2
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// How much larger `image` is drawn than it is, for `mode` in a `width`×`height` frame.
    static func enlargement(of image: CGImage, width: Double, height: Double, mode: FitMode) -> Double {
        let sx = width / Double(image.width), sy = height / Double(image.height)
        return mode == .fill ? max(sx, sy) : min(sx, sy)
    }

    /// A Core Image result back as a CGImage, through one shared context.
    static func render(_ image: CIImage, extent: CGRect) -> CGImage? {
        ciContext.createCGImage(image, from: extent, format: .RGBA8, colorSpace: sRGB)
    }

    static let ciContext = CIContext(options: [.cacheIntermediates: false, .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!])
}

extension Bitmaps {
    /// The RGBA bytes of `image`, premultiplied, as drawn into the one bitmap.
    static func rgba(_ image: CGImage) -> [UInt8]? {
        guard let context = context(width: image.width, height: image.height), let data = context.data else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Array(UnsafeBufferPointer(start: data.bindMemory(to: UInt8.self, capacity: image.width * image.height * 4),
                                         count: image.width * image.height * 4))
    }

    /// The bytes drawn so far in a context made by ``context(width:height:)``, top row first.
    static func bytes(of context: CGContext) -> [UInt8]? {
        guard let data = context.data, context.bytesPerRow == context.width * 4 else { return nil }
        let count = context.width * context.height * 4
        return Array(UnsafeBufferPointer(start: data.bindMemory(to: UInt8.self, capacity: count), count: count))
    }

    /// `draw` run into a fresh bitmap, as bytes.
    static func bytes(width: Int, height: Int, _ draw: (CGContext) -> Void) -> [UInt8]? {
        guard let context = context(width: width, height: height) else { return nil }
        draw(context)
        return bytes(of: context)
    }
}
