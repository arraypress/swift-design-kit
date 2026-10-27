//
//  Mask.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The outline a picture is clipped to.
public struct Mask: Equatable, Sendable {
    /// The outline.
    public var shape: MaskShape
    /// Corner radius for `rounded`, in design units.
    public var radius: Double
    /// Corners for `polygon`, as fractions of the frame (`[[0.5, 0], [1, 1], [0, 1]]`).
    public var points: [[Double]]?

    /// A mask of `shape`.
    public init(shape: MaskShape, radius: Double = 40, points: [[Double]]? = nil) {
        self.shape = shape
        self.radius = radius
        self.points = points
    }
}
