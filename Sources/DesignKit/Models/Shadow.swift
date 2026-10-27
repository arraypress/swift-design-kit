//
//  Shadow.swift
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
    /// The shadow's colour, alpha and all.
    public var color: DesignColor
    /// Softness, in design units.
    public var blur: Double
    /// Offset right and down, in design units.
    public var x: Double
    /// Offset down, in design units.
    public var y: Double

    /// A shadow; the default is a soft half-black one below.
    public init(color: DesignColor = DesignColor("#00000080")!, blur: Double = 12, x: Double = 0, y: Double = 6) {
        self.color = color
        self.blur = blur
        self.x = x
        self.y = y
    }
}
