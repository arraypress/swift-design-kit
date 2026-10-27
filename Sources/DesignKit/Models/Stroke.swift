//
//  Stroke.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Sizes are in design units: a thousandth of the canvas's shorter side (of
//  the trimmed page, for print), so an effect reads the same at every size.
//

import Foundation

/// An outline: round text, a mask's shape, a shape, or a cut-out's edge.
public struct Stroke: Equatable, Sendable {
    /// The outline's colour.
    public var color: Paint
    /// Thickness, in design units.
    public var width: Double
    /// Text only: a keyline round filled letters, or the outline alone.
    public var style: StrokeStyle
    /// Dashes and gaps, in design units (`[12, 8]`); shapes and lines only.
    public var dash: [Double]?

    /// An outline of `color`, `width` thick.
    public init(color: Paint, width: Double = 4, style: StrokeStyle = .outline, dash: [Double]? = nil) {
        self.color = color
        self.width = width
        self.style = style
        self.dash = dash
    }
}
