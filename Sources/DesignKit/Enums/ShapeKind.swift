//
//  ShapeKind.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A shape layer's outline.
public enum ShapeKind: String, DesignChoice {
    /// A rectangle filling the box.
    case rect
    /// A rectangle with round corners (`radius`).
    case rounded
    /// The ellipse inscribed in the box.
    case ellipse
    /// A line through `points`.
    case line
    /// The corners given in `points`.
    case polygon
    /// A star of `count` points (`inner` for its inner radius).
    case star
    /// A border inside the box (`inset`, `radius` for round corners).
    case frame
    /// Two borders, `gap` apart.
    case doubleFrame = "double-frame"
    /// An L at each corner, `length` long.
    case brackets
    /// A film strip's edges: bands top and bottom with `count` sprocket holes each.
    case filmStrip = "film-strip"
    /// A line with a head at its end (`points`, `length` for the head).
    case arrow
    /// A ring: the ellipse with its middle (`inner`) cut out.
    case ring
    /// A many-pointed burst (`count`, `inner`).
    case burst
    /// A seal with a scalloped edge (`count` scallops).
    case badge
    /// A rule with a small diamond at its centre.
    case divider
}
