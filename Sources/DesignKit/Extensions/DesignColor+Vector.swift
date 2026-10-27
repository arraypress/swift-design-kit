//
//  DesignColor+Vector.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

extension DesignColor {
    /// `#RRGGBB`, alpha dropped (SVG takes opacity separately).
    var rgbHex: String { String(hex.prefix(7)) }

    /// A CoreGraphics colour back as a design colour (sRGB).
    static func from(_ color: CGColor) -> DesignColor {
        let srgb = color.converted(to: Bitmaps.sRGB, intent: .defaultIntent, options: nil) ?? color
        let c = srgb.components ?? [1, 1, 1, 1]
        let rgb = c.count >= 3 ? (c[0], c[1], c[2]) : (c[0], c[0], c[0])
        return DesignColor(hex: ColorParsing.hex(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: c.last ?? 1))
    }
}
