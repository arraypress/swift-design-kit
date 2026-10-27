//
//  Plate.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Sizes are in design units: a thousandth of the canvas's shorter side (of
//  the trimmed page, for print), so an effect reads the same at every size.
//

import Foundation

/// A panel behind text, sized to its lines.
public struct Plate: Equatable, Sendable {
    /// The panel's colour, or `auto`: black or white at the least opacity
    /// that lifts the words to WCAG 4.5:1 over what is behind them.
    public var color: Paint
    /// Room round the lines, in design units.
    public var padding: Double
    /// Corner radius, in design units.
    public var radius: Double
    /// One panel per line (the highlighter idiom) instead of one for the block.
    public var perLine: Bool

    /// A plate of `color`.
    public init(color: Paint = .auto, padding: Double = 24, radius: Double = 8, perLine: Bool = false) {
        self.color = color
        self.padding = padding
        self.radius = radius
        self.perLine = perLine
    }
}
