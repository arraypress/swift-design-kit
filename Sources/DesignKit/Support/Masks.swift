//
//  Masks.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Grey masks for a parallax's layers and fills. Pure.
//

import CoreGraphics
import CoreImage
import Foundation

/// Grey masks for the layers and the fills.
enum Masks {

    /// One grey byte a pixel, top row first, as an image.
    static func gray(_ bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        guard bytes.count == width * height, let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                       space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    /// The grey bytes of `image`, top row first.
    static func bytes(of image: CGImage) -> [UInt8]? {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? bytes : nil
    }

    /// `mask` grown by `radius` pixels.
    static func grown(_ mask: CGImage?, by radius: Double) -> CGImage? {
        morph(mask, filter: "CIMorphologyMaximum", radius: radius)
    }

    /// `mask` shrunk by `radius` pixels.
    static func shrunk(_ mask: CGImage?, by radius: Double) -> CGImage? {
        morph(mask, filter: "CIMorphologyMinimum", radius: radius)
    }

    private static func morph(_ mask: CGImage?, filter: String, radius: Double) -> CGImage? {
        guard let mask else { return nil }
        let base = CIImage(cgImage: mask)
        let extent = base.extent
        let result = base.clampedToExtent().applyingFilter(filter, parameters: ["inputRadius": max(1, radius)]).cropped(to: extent)
        return Bitmaps.render(result, extent: extent).flatMap(grayscale)
    }

    /// A small mask stretched to `width`×`height` and softened by `sigma`.
    static func enlarged(_ mask: CGImage, width: Int, height: Int, sigma: Double) -> CGImage? {
        let extent = CGRect(x: 0, y: 0, width: width, height: height)
        let stretched = CIImage(cgImage: mask).samplingLinear()
            .transformed(by: CGAffineTransform(scaleX: Double(width) / Double(mask.width), y: Double(height) / Double(mask.height)))
        let soft = stretched.clampedToExtent().applyingGaussianBlur(sigma: sigma).cropped(to: extent)
        return Bitmaps.render(soft, extent: extent).flatMap(grayscale)
    }

    /// An RGB mask as one grey channel (CoreGraphics clips by a grey image's values).
    static func grayscale(_ image: CGImage) -> CGImage? {
        guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }
}
