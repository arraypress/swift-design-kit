//
//  CanvasGeometry.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// A page laid out in pixels, origin top-left, over the whole bitmap.
public struct CanvasGeometry: Equatable, Sendable {
    /// The bitmap: trim plus bleed on every side.
    public let pixelWidth: Int
    public let pixelHeight: Int
    /// The finished page.
    public let trim: CGRect
    /// Where words stay.
    public let safe: CGRect
    /// Pixels per design unit (a thousandth of the trim's shorter side).
    public let unit: Double
    /// Print resolution, when the page is for print.
    public let dpi: Double?

    /// The whole bitmap, out to the bleed.
    public var bleed: CGRect { CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight) }

    /// The rectangle an area names.
    public func rect(_ area: Area) -> CGRect {
        switch area {
        case .safe: safe
        case .trim: trim
        case .bleed: bleed
        }
    }
}
