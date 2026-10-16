//
//  PrintColor.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  CMYK for print: pictures converted by ColorSync into the generic CMYK
//  profile (perceptual, the photographic intent), with their transparency
//  kept as a soft mask; and the gamut measured — every colour the design
//  shows, sent to CMYK and back (relative colorimetric, which clips what is
//  out of gamut rather than squeezing it), with the difference as CIE76 ΔE.
//

import CanvasKit
import CoreGraphics
import Foundation
import ImageIO
import Legibility

public enum PrintColor {

    /// The CMYK print files are written in: macOS's Generic CMYK Profile.
    public static let cmyk = CGColorSpace(name: CGColorSpace.genericCMYK)!

    /// A colour that moves more than this (ΔE76) on the way to CMYK and back
    /// is out of gamut: about four times what a careful eye notices (2.3).
    public static let outOfGamut = 10.0

    /// What a CMYK PDF cannot hold as the design has it.
    public static func notes(_ prepared: PreparedDesign) -> [String] {
        let blended = Layouter.entries(prepared.design.layers).contains { entry in
            let layer = entry.layer
            if case .group = layer.content { return true }
            return layer.opacity < 1 || layer.blend != .normal || layer.shadow != nil || layer.glow != nil || layer.fade != nil
        }
        return blended ? ["layers with opacity, a blend, a shadow, a glow, a fade or a group are blended in an RGB transparency group "
                          + "(CoreGraphics' PDF writer has no CMYK blending space): their inks are CMYK, the blend is converted by the printer"] : []
    }

    /// `image` as CMYK pixels, its alpha kept as a soft mask.
    static func converted(_ image: CGImage) -> CGImage? {
        guard var bytes = Pixels.rgba(of: image) else { return nil }
        let width = image.width, height = image.height
        var opaque = true
        var alpha = [UInt8](repeating: 255, count: width * height)
        for index in 0..<(width * height) {
            let a = bytes[index * 4 + 3]
            alpha[index] = a
            if a < 255 {
                opaque = false
                // Colour without the alpha folded in, so edges keep their colour.
                if a > 0 {
                    for channel in 0..<3 {
                        bytes[index * 4 + channel] = UInt8(min(255, (Double(bytes[index * 4 + channel]) * 255 / Double(a)).rounded()))
                    }
                }
            }
            bytes[index * 4 + 3] = 255
        }
        guard let rgb = bytes.withUnsafeMutableBytes({ raw -> CGImage? in
            CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                      space: Bitmaps.sRGB, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)?.makeImage()
        }), let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                     space: cmyk, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.setRenderingIntent(.perceptual)
        context.interpolationQuality = .none
        context.draw(rgb, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let converted = context.makeImage() else { return nil }
        if opaque { return compact(converted) }
        guard let provider = CGDataProvider(data: Data(alpha) as CFData),
              let mask = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                                 space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider,
                                 decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return converted }
        return converted.masking(mask)
    }

    /// A large opaque picture carried as CMYK JPEG (quality 0.92): a PDF
    /// passes JPEG data through as it is, where raw pixels of a grainy A3
    /// background come to tens of megabytes.
    static func compact(_ image: CGImage) -> CGImage {
        guard image.width * image.height >= 512 * 512 else { return image }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else { return image }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
        guard CGImageDestinationFinalize(destination), let source = CGImageSourceCreateWithData(data, nil),
              let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return image }
        return decoded
    }

    /// How far the design's colours move on the way to CMYK.
    public static func gamut(of image: CGImage, inks: [String]) -> GamutReport {
        // The picture at most 400 px on its longest side: enough to count shares.
        let scale = min(1, 400 / Double(max(image.width, image.height)))
        let width = max(1, Int(Double(image.width) * scale)), height = max(1, Int(Double(image.height) * scale))
        guard let small = Bitmaps.image(width: width, height: height, { $0.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height)) }),
              let before = Pixels.rgba(of: small),
              let cmykContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: cmyk, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return GamutReport(outside: 0, worst: 0, inks: [])
        }
        cmykContext.setRenderingIntent(.relativeColorimetric)
        cmykContext.draw(small, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let printed = cmykContext.makeImage(),
              let back = Bitmaps.image(width: width, height: height, { context in
                  context.setRenderingIntent(.relativeColorimetric)
                  context.draw(printed, in: CGRect(x: 0, y: 0, width: width, height: height))
              }), let after = Pixels.rgba(of: back) else { return GamutReport(outside: 0, worst: 0, inks: []) }
        var outside = 0, worst = 0.0
        for index in stride(from: 0, to: before.count, by: 4) {
            let delta = deltaE(rgb(before, index), rgb(after, index))
            if delta > outOfGamut { outside += 1 }
            worst = max(worst, delta)
        }
        let moved = inks.compactMap { hex -> GamutInk? in
            guard let color = DesignColor(hex) else { return nil }
            let c = color.components
            let source = CGColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: 1)
            guard let printed = source.converted(to: cmyk, intent: .relativeColorimetric, options: nil),
                  let returned = printed.converted(to: Bitmaps.sRGB, intent: .relativeColorimetric, options: nil),
                  let parts = returned.components, parts.count >= 3 else { return nil }
            let delta = deltaE((c.red, c.green, c.blue), (parts[0], parts[1], parts[2]))
            let k = printed.components ?? []
            return GamutInk(color: color.hex, deltaE: (delta * 10).rounded() / 10,
                            cmyk: k.prefix(4).map { ($0 * 1000).rounded() / 10 }, outside: delta > outOfGamut)
        }
        return GamutReport(outside: (Double(outside) / Double(width * height) * 1000).rounded() / 1000,
                           worst: (worst * 10).rounded() / 10, inks: moved)
    }

    static func rgb(_ bytes: [UInt8], _ index: Int) -> (Double, Double, Double) {
        (Double(bytes[index]) / 255, Double(bytes[index + 1]) / 255, Double(bytes[index + 2]) / 255)
    }

    /// CIE76 ΔE between two sRGB colours (D65 Lab).
    static func deltaE(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
        let x = lab(a), y = lab(b)
        return ((x.0 - y.0) * (x.0 - y.0) + (x.1 - y.1) * (x.1 - y.1) + (x.2 - y.2) * (x.2 - y.2)).squareRoot()
    }

    static func lab(_ rgb: (Double, Double, Double)) -> (Double, Double, Double) {
        func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let r = linear(rgb.0), g = linear(rgb.1), b = linear(rgb.2)
        let x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        func f(_ t: Double) -> Double { t > 216.0 / 24389 ? cbrt(t) : (24389.0 / 27 * t + 16) / 116 }
        return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)))
    }
}

/// How the design's colours fare in CMYK.
public struct GamutReport: Codable, Equatable, Sendable {
    /// The share of the picture's pixels that move more than ``PrintColor/outOfGamut``.
    public var outside: Double
    /// The furthest any pixel moves (ΔE76).
    public var worst: Double
    /// Each word and shape colour: how far it moves, and the CMYK it prints as (percent).
    public var inks: [GamutInk]
}

public struct GamutInk: Codable, Equatable, Sendable {
    public var color: String
    public var deltaE: Double
    public var cmyk: [Double]
    public var outside: Bool
}
