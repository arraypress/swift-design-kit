//
//  Inline.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A line drawn inside the letters, following their outline (the inline
/// display style). For an outline alone, `stroke` with `"style": "hollow"`.
public struct Inline: Equatable, Sendable {
    /// The line's colour.
    public var color: Paint
    /// The line's thickness, in design units.
    public var width: Double
    /// How far inside the letters' edge it runs, in design units.
    public var inset: Double

    /// An inline of `color`, `width` thick, `inset` inside the edge.
    public init(color: Paint = .color(.white), width: Double = 3, inset: Double = 4) {
        self.color = color
        self.width = width
        self.inset = inset
    }
}
