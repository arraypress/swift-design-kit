//
//  ShapeContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A drawn shape.
public struct ShapeContent: Equatable, Sendable {
    /// The outline.
    public var shape: ShapeKind
    /// A flat fill; `nil` leaves it unfilled.
    public var fill: Paint?
    /// A blend instead of a flat fill.
    public var gradient: [DesignColor]?
    /// The blend's angle, degrees, 0 up, clockwise.
    public var angle: Double
    /// An outline round it.
    public var stroke: Stroke?
    /// Corner radius for `rounded`, in design units.
    public var radius: Double
    /// Corners for `polygon` and the ends of a `line`, as fractions of the frame.
    public var points: [[Double]]?
    /// A star's, burst's or badge's points; a film strip's holes along each edge.
    public var count: Int
    /// A star's or ring's inner radius, as a fraction of the outer.
    public var inner: Double
    /// How far a frame sits inside its box, in design units.
    public var inset: Double
    /// The space between a double frame's two lines, in design units.
    public var gap: Double
    /// A corner bracket's arm, or an arrow's head, as a fraction of the box's shorter side.
    public var length: Double

    /// A shape of `shape`.
    public init(shape: ShapeKind, fill: Paint? = nil, gradient: [DesignColor]? = nil, angle: Double = 180,
                stroke: Stroke? = nil, radius: Double = 40, points: [[Double]]? = nil, count: Int = 5,
                inner: Double = 0.45, inset: Double = 0, gap: Double = 12, length: Double = 0.18) {
        self.shape = shape
        self.fill = fill
        self.gradient = gradient
        self.angle = angle
        self.stroke = stroke
        self.radius = radius
        self.points = points
        self.count = count
        self.inner = inner
        self.inset = inset
        self.gap = gap
        self.length = length
    }
}
