//
//  GradientFill.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A GradientKit wallpaper: the same seed, palette and motif draw the same picture.
public struct GradientFill: Equatable, Sendable {
    /// The seed the wallpaper is drawn from.
    public var seed: UInt64
    /// A palette's name (`lagoon`, `sea-glass`), `dark` / `light` (made from
    /// the seed), or `nil` for one of the soft palettes picked by the seed.
    public var palette: String?
    /// A motif's name (`flow`, `mesh`, `aurora`…), or `nil` for one of the
    /// featured motifs picked by the seed.
    public var motif: String?

    /// A wallpaper from `seed`.
    public init(seed: UInt64, palette: String? = nil, motif: String? = nil) {
        self.seed = seed
        self.palette = palette
        self.motif = motif
    }
}
