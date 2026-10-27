//
//  Glow.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Sizes are in design units: a thousandth of the canvas's shorter side (of
//  the trimmed page, for print), so an effect reads the same at every size.
//

import Foundation

/// A soft light round everything the layer draws.
public struct Glow: Equatable, Sendable {
    /// The glow's colour.
    public var color: Paint
    /// How far it reaches, in design units.
    public var radius: Double

    /// A glow of `color` reaching `radius`.
    public init(color: Paint, radius: Double = 20) {
        self.color = color
        self.radius = radius
    }
}
