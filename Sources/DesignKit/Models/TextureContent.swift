//
//  TextureContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A texture drawn over what is under it — usually blended (`multiply`,
/// `overlay`, `screen`) at a low opacity. The same seed draws the same grain.
public struct TextureContent: Equatable, Sendable {
    /// What it draws.
    public var kind: TextureKind
    /// The ink.
    public var color: DesignColor
    /// The size of its marks (dots, lines, specks), in design units.
    public var scale: Double
    /// How much of it there is, `0…1`.
    public var density: Double
    /// Halftone dots grow toward this direction, scanlines run along it (degrees, 0 up).
    public var angle: Double
    /// The seed it is drawn from.
    public var seed: UInt64

    /// A texture of `kind`; `scale` defaults to the kind's own.
    public init(kind: TextureKind, color: DesignColor = .black, scale: Double? = nil, density: Double = 0.5,
                angle: Double = 180, seed: UInt64 = 1) {
        self.kind = kind
        self.color = color
        self.scale = scale ?? kind.defaultScale
        self.density = density
        self.angle = angle
        self.seed = seed
    }
}
