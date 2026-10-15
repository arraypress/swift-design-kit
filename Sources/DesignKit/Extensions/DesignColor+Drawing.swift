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

    /// The colour as CoreGraphics draws it.
    var cgColor: CGColor {
        let c = components
        return CGColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
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
