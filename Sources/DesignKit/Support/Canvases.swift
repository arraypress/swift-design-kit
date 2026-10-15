//
//  Canvases.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  From a preset to a page, and from a page to the rectangles everything is
//  placed in. All rectangles are pixels, origin top-left (as a design tool
//  measures), over the whole bitmap — trim plus bleed.
//

import CoreGraphics
import Foundation

enum Canvases {

    static let millimetresPerInch = 25.4
    static let printDPI = 300.0
    static let printBleedMM = 3.0
    static let printSafeMM = 5.0

    /// A print preset: millimetres at 300 dpi, 3 mm bleed, 5 mm safe.
    static func printPreset(_ name: String, _ summary: String, _ widthMM: Double, _ heightMM: Double) -> Preset {
        Preset(name: name, summary: summary + " — print, 300 dpi, 3 mm bleed, crop marks",
               width: widthMM, height: heightMM, dpi: printDPI, bleedMM: printBleedMM,
               safe: Insets(top: printSafeMM / heightMM, bottom: printSafeMM / heightMM,
                            left: printSafeMM / widthMM, right: printSafeMM / widthMM),
               rules: PlatformRules(needsBleed: true))
    }

    /// Millimetres to pixels at `dpi`.
    static func pixels(_ millimetres: Double, dpi: Double) -> Int {
        Int((millimetres / millimetresPerInch * dpi).rounded())
    }

    /// The page a preset makes.
    static func spec(for preset: Preset) -> CanvasSpec {
        guard let dpi = preset.dpi else {
            return CanvasSpec(preset: preset.name, width: Int(preset.width), height: Int(preset.height), safe: preset.safe)
        }
        return CanvasSpec(preset: preset.name, width: pixels(preset.width, dpi: dpi), height: pixels(preset.height, dpi: dpi),
                          dpi: dpi, bleed: pixels(preset.bleedMM, dpi: dpi), safe: preset.safe, cropMarks: true)
    }

    /// One fraction of the shorter side, as per-edge fractions.
    static func uniformSafe(_ fraction: Double, width: Int, height: Int) -> Insets {
        let inset = fraction * Double(min(width, height))
        return Insets(top: inset / Double(height), bottom: inset / Double(height),
                      left: inset / Double(width), right: inset / Double(width))
    }

    /// The rectangles a spec lays out.
    static func geometry(_ spec: CanvasSpec) -> CanvasGeometry {
        let bleed = Double(spec.bleed)
        let trim = CGRect(x: bleed, y: bleed, width: Double(spec.width), height: Double(spec.height))
        let safe = CGRect(x: trim.minX + trim.width * spec.safe.left, y: trim.minY + trim.height * spec.safe.top,
                          width: trim.width * (1 - spec.safe.left - spec.safe.right),
                          height: trim.height * (1 - spec.safe.top - spec.safe.bottom))
        return CanvasGeometry(pixelWidth: spec.width + 2 * spec.bleed, pixelHeight: spec.height + 2 * spec.bleed,
                              trim: trim, safe: safe, unit: Double(min(spec.width, spec.height)) / 1000, dpi: spec.dpi)
    }
}
