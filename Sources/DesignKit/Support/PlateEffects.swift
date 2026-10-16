//
//  PlateEffects.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What a background does to its picture, in order: blur, duotone, the look
//  (with grain and vignette), darken, scrim. The blur, the look and the
//  scrim are CanvasKit's own; duotone maps the picture's tones between two
//  colours.
//

import CanvasKit
import CoreGraphics
import CoreImage
import Foundation
import VideoGrade

enum PlateEffects {

    /// `plate` with `content`'s treatments. `unit` is pixels per design unit;
    /// `textRegions` (CoreGraphics space) are what an `auto` scrim protects.
    static func apply(_ content: BackgroundContent, to plate: CGImage, look: VideoGrade?, unit: Double,
                      textRegions: [CGRect]) throws(DesignError) -> CGImage {
        var image = plate
        if content.blur > 0 { image = SlideRenderer.blurred(image, radius: content.blur * unit) }
        if let duotone = content.duotone, duotone.count == 2 { image = self.duotone(image, dark: duotone[0], light: duotone[1]) }
        if let map = content.gradientMap, map.count >= 2 { image = gradientMapped(image, through: map) }

        var grade = look ?? VideoGrade()
        if content.grain > 0 { grade.grain = content.grain }
        if content.vignette > 0 { grade.vignette = content.vignette * 2 }
        if grade != VideoGrade() {
            do { image = try SlideRenderer.graded(image, with: grade) } catch {
                throw .failed("the look could not be applied: \(error.localizedDescription)")
            }
        }

        var dim = content.darken, scrim = 0.0, edge = CanvasKit.ScrimEdge.bottom
        if let wanted = content.scrim {
            switch wanted.edge {
            case .auto:
                let canvas = Canvas(width: image.width, height: image.height)
                let measured = SlideRenderer.adaptiveWashes(plate: image, textRegions: textRegions, canvas: canvas,
                                                            declared: (content.darken, wanted.strength, .bottom))
                (dim, scrim, edge) = (measured.0, measured.1, measured.2)
            case .bottom: (scrim, edge) = (wanted.strength, .bottom)
            case .top: (scrim, edge) = (wanted.strength, .top)
            case .both: (scrim, edge) = (wanted.strength, .both)
            }
        }
        if dim > 0 || scrim > 0, let washes = SlideRenderer.renderWashes(dim: dim, scrim: scrim, edge: edge,
                                                                        width: image.width, height: image.height) {
            image = Bitmaps.image(width: image.width, height: image.height) { context in
                let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
                context.draw(image, in: bounds)
                context.draw(washes, in: bounds)
            } ?? image
        }
        return image
    }

    /// The picture's tones (luminance) mapped through `colors`, darkest
    /// first, evenly spaced — on the CPU through a 256-step table, so the
    /// same picture maps to the same bytes.
    static func gradientMapped(_ image: CGImage, through colors: [DesignColor]) -> CGImage {
        let parts = colors.map(\.components)
        var table = [(UInt8, UInt8, UInt8)](repeating: (0, 0, 0), count: 256)
        for index in 0..<256 {
            let t = Double(index) / 255 * Double(parts.count - 1)
            let low = min(parts.count - 2, Int(t)), f = t - Double(low)
            func mix(_ a: Double, _ b: Double) -> UInt8 { UInt8(((a + (b - a) * f) * 255).rounded()) }
            table[index] = (mix(parts[low].red, parts[low + 1].red), mix(parts[low].green, parts[low + 1].green),
                            mix(parts[low].blue, parts[low + 1].blue))
        }
        let width = image.width, height = image.height
        guard let context = Bitmaps.context(width: width, height: height), let data = context.data else { return image }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        for i in 0..<(width * height) {
            let r = Double(pixels[i * 4]), g = Double(pixels[i * 4 + 1]), b = Double(pixels[i * 4 + 2])
            let entry = table[Int((0.2126 * r + 0.7152 * g + 0.0722 * b).rounded())]
            let a = Double(pixels[i * 4 + 3]) / 255
            pixels[i * 4] = UInt8((Double(entry.0) * a).rounded())
            pixels[i * 4 + 1] = UInt8((Double(entry.1) * a).rounded())
            pixels[i * 4 + 2] = UInt8((Double(entry.2) * a).rounded())
        }
        return context.makeImage() ?? image
    }

    /// The picture's tones mapped from `dark` to `light`.
    static func duotone(_ image: CGImage, dark: DesignColor, light: DesignColor) -> CGImage {
        let input = CIImage(cgImage: image)
        let mapped = input.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(cgColor: dark.withAlpha(1).cgColor),
            "inputColor1": CIColor(cgColor: light.withAlpha(1).cgColor),
        ])
        return Bitmaps.render(mapped, extent: input.extent) ?? image
    }
}
