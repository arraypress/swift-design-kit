//
//  Placement.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Where a layer goes, said as a rule rather than in pixels, so one template
//  is right at 3000² and at A3: an anchor in an area, a size as fractions of
//  that area, a margin, a span of the column grid, or a place below another
//  layer.
//

import Foundation

/// A layer's frame, by rule.
public struct Placement: Equatable, Sendable {

    /// The area the frame is placed in. Backgrounds default to `bleed`,
    /// everything else to `safe`. Inside a group, the group's frame.
    public var area: Area?

    /// The point of the area the frame holds on to.
    public var anchor: Anchor

    /// Width as a fraction of the area.
    public var width: Double

    /// Height as a fraction of the area. With `aspect`, derived from the width.
    public var height: Double

    /// Width over height; when set, the height follows the width.
    public var aspect: Double?

    /// Inset from the anchored edges, as a fraction of the area's shorter side.
    public var margin: Double

    /// A nudge, as fractions of the area (right and down are positive).
    public var x: Double
    /// The nudge down, as a fraction of the area's height.
    public var y: Double

    /// A span of the column grid: first column (from 1) and how many.
    /// Sets the frame's left edge and width; the anchor still places it vertically.
    public var columns: [Int]?

    /// Placed under (or over) an earlier layer, by its id: the frame's top
    /// goes `gap` below that layer's drawn bottom (its lines, for text).
    public var below: String?
    /// Placed over an earlier layer, by its id: the frame's bottom goes `gap` above its drawn top.
    public var above: String?

    /// The space for `below` / `above`, as a fraction of the area's height.
    public var gap: Double

    /// A frame by rule; the default is the whole area.
    public init(area: Area? = nil, anchor: Anchor = .center, width: Double = 1, height: Double = 1,
                aspect: Double? = nil, margin: Double = 0, x: Double = 0, y: Double = 0,
                columns: [Int]? = nil, below: String? = nil, above: String? = nil, gap: Double = 0) {
        self.area = area
        self.anchor = anchor
        self.width = width
        self.height = height
        self.aspect = aspect
        self.margin = margin
        self.x = x
        self.y = y
        self.columns = columns
        self.below = below
        self.above = above
        self.gap = gap
    }

    /// The whole area.
    public static let full = Placement()
}
