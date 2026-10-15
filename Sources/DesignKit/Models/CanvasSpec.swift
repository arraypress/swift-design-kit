//
//  CanvasSpec.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The page: its finished size in pixels, the safe insets words stay inside,
/// and for print the resolution, the bleed and the crop marks.
///
/// A design file may name only a `preset`; a design that has been made holds
/// every number, so a replay does not depend on the preset staying the same.
public struct CanvasSpec: Equatable, Sendable {

    /// The preset it came from, if any — also what the platform checks follow.
    public var preset: String?

    /// The finished (trimmed) size, in pixels.
    public var width: Int
    public var height: Int

    /// Pixels per inch, for print; `nil` for a screen.
    public var dpi: Double?

    /// Picture carried past the trim on every side, in pixels (print).
    public var bleed: Int

    /// Where words stay inside, as fractions of the finished width (left,
    /// right) and height (top, bottom).
    public var safe: Insets

    /// Print crop marks in the PDF.
    public var cropMarks: Bool

    public init(preset: String? = nil, width: Int, height: Int, dpi: Double? = nil, bleed: Int = 0,
                safe: Insets = Insets(uniform: 0.06), cropMarks: Bool = false) {
        self.preset = preset
        self.width = width
        self.height = height
        self.dpi = dpi
        self.bleed = bleed
        self.safe = safe
        self.cropMarks = cropMarks
    }
}

/// Insets as fractions: top and bottom of the height, left and right of the width.
public struct Insets: Equatable, Sendable {
    public var top: Double
    public var bottom: Double
    public var left: Double
    public var right: Double

    public init(top: Double, bottom: Double, left: Double, right: Double) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }

    /// The same fraction on every side.
    public init(uniform value: Double) {
        self.init(top: value, bottom: value, left: value, right: value)
    }
}
