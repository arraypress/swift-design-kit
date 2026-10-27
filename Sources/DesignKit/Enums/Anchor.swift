//
//  Anchor.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Which point of its area a layer's frame holds on to.
public enum Anchor: String, DesignChoice {
    /// The top-left corner.
    case topLeft = "top-left"
    /// The middle of the top edge.
    case top
    /// The top-right corner.
    case topRight = "top-right"
    /// The middle of the left edge.
    case left
    /// The centre.
    case center
    /// The middle of the right edge.
    case right
    /// The bottom-left corner.
    case bottomLeft = "bottom-left"
    /// The middle of the bottom edge.
    case bottom
    /// The bottom-right corner.
    case bottomRight = "bottom-right"

    /// `0` left, `0.5` centre, `1` right.
    public var horizontal: Double {
        switch self {
        case .topLeft, .left, .bottomLeft: 0
        case .top, .center, .bottom: 0.5
        case .topRight, .right, .bottomRight: 1
        }
    }

    /// `0` top, `0.5` middle, `1` bottom.
    public var vertical: Double {
        switch self {
        case .topLeft, .top, .topRight: 0
        case .left, .center, .right: 0.5
        case .bottomLeft, .bottom, .bottomRight: 1
        }
    }

    /// The anchor at these fractions (each 0, 0.5 or 1).
    static func at(horizontal: Double, vertical: Double) -> Anchor {
        allCases.first { $0.horizontal == horizontal && $0.vertical == vertical } ?? .center
    }

    /// Top and bottom swapped.
    public var flippedVertically: Anchor { .at(horizontal: horizontal, vertical: 1 - vertical) }

    /// Left and right swapped.
    public var flippedHorizontally: Anchor { .at(horizontal: 1 - horizontal, vertical: vertical) }
}
