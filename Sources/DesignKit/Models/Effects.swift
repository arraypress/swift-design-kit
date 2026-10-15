//
//  Effects.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Sizes are in design units: a thousandth of the canvas's shorter side (of
//  the trimmed page, for print), so an effect reads the same at every size.
//

import Foundation

/// A drop shadow cast by everything the layer draws.
public struct Shadow: Equatable, Sendable {
    public var color: DesignColor
    /// Softness, in design units.
    public var blur: Double
    /// Offset right and down, in design units.
    public var x: Double
    public var y: Double

    public init(color: DesignColor = DesignColor("#00000080")!, blur: Double = 12, x: Double = 0, y: Double = 6) {
        self.color = color
        self.blur = blur
        self.x = x
        self.y = y
    }
}

/// A soft light round everything the layer draws.
public struct Glow: Equatable, Sendable {
    public var color: DesignColor
    /// How far it reaches, in design units.
    public var radius: Double

    public init(color: DesignColor, radius: Double = 20) {
        self.color = color
        self.radius = radius
    }
}

/// An outline: round text, a mask's shape, a shape, or a cut-out's edge.
public struct Stroke: Equatable, Sendable {
    public var color: DesignColor
    /// Thickness, in design units.
    public var width: Double
    /// Text only: a keyline round filled letters, or the outline alone.
    public var style: StrokeStyle

    public init(color: DesignColor, width: Double = 4, style: StrokeStyle = .outline) {
        self.color = color
        self.width = width
        self.style = style
    }
}

/// A panel behind text, sized to its lines.
public struct Plate: Equatable, Sendable {
    /// The panel's colour, or `auto`: black or white at the least opacity
    /// that lifts the words to WCAG 4.5:1 over what is behind them.
    public var color: TextColor
    /// Room round the lines, in design units.
    public var padding: Double
    /// Corner radius, in design units.
    public var radius: Double
    /// One panel per line (the highlighter idiom) instead of one for the block.
    public var perLine: Bool

    public init(color: TextColor = .auto, padding: Double = 24, radius: Double = 8, perLine: Bool = false) {
        self.color = color
        self.padding = padding
        self.radius = radius
        self.perLine = perLine
    }
}

/// The scrim a background lays over itself so words read.
public struct Scrim: Equatable, Sendable {
    public var edge: ScrimEdge
    /// `0…1`; ignored by `auto`, which measures.
    public var strength: Double

    public init(edge: ScrimEdge = .auto, strength: Double = 0.5) {
        self.edge = edge
        self.strength = strength
    }
}
