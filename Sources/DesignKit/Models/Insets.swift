//
//  Insets.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Insets as fractions: top and bottom of the height, left and right of the width.
public struct Insets: Equatable, Sendable {
    /// The top inset, a fraction of the height.
    public var top: Double
    /// The bottom inset, a fraction of the height.
    public var bottom: Double
    /// The left inset, a fraction of the width.
    public var left: Double
    /// The right inset, a fraction of the width.
    public var right: Double

    /// Insets from four fractions.
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
