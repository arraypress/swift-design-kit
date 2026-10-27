//
//  Extrude.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Letters extruded into depth: copies stacked back from the face, shaded darker the further back they sit.
public struct Extrude: Equatable, Sendable {
    /// How deep, in design units.
    public var depth: Double
    /// Which way the depth runs, degrees clockwise from up (`135`: down and right).
    public var angle: Double
    /// The colour of the sides; `auto` is the letters' colour, darkened.
    public var color: Paint
    /// How much darker the back is than the front, `0…1`.
    public var shade: Double

    /// An extrusion `depth` deep at `angle`.
    public init(depth: Double = 24, angle: Double = 135, color: Paint = .auto, shade: Double = 0.5) {
        self.depth = depth
        self.angle = angle
        self.color = color
        self.shade = shade
    }
}
