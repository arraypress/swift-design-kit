//
//  DesignColor+Drawing.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CanvasKit
import CoreGraphics
import Foundation
import Legibility

public extension DesignColor {

    /// sRGB components, `0…1`.
    var components: (red: Double, green: Double, blue: Double, alpha: Double) { ColorParsing.components(hex) }

    /// The colour as CoreGraphics draws it — in the print file's CMYK while
    /// one is being drawn (``Inks/space``), sRGB otherwise.
    var cgColor: CGColor {
        let c = components
        return Inks.converted(CGColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: c.alpha))
    }

    /// The colour mixed toward black by `amount` (`0…1`), alpha kept.
    func darkened(_ amount: Double) -> DesignColor {
        let c = components, keep = 1 - min(1, max(0, amount))
        return DesignColor(hex: ColorParsing.hex(red: c.red * keep, green: c.green * keep, blue: c.blue * keep, alpha: c.alpha))
    }

    /// The colour as the text engine takes it.
    var slide: SlideColor { SlideColor(hex) }

    /// WCAG relative luminance (alpha ignored).
    var luminance: Double {
        let c = components
        return Contrast.luminance(red: c.red, green: c.green, blue: c.blue)
    }

    /// The same colour at `alpha`.
    func withAlpha(_ alpha: Double) -> DesignColor {
        let c = components
        return DesignColor(hex: ColorParsing.hex(red: c.red, green: c.green, blue: c.blue, alpha: alpha))
    }
}
