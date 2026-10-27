//
//  PaletteSpec.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How a design's palette roles are found: from the art, by a harmony rule,
/// with any role pinned to a colour.
public struct PaletteSpec: Equatable, Sendable {
    /// How the accent is found from the dominant colour.
    public var harmony: Harmony
    /// Roles set by hand (`accent: #FF3366`), which win over the art.
    public var fixed: [ColorRole: DesignColor]

    /// A palette found by `harmony`, with `fixed` roles pinned.
    public init(harmony: Harmony = .auto, fixed: [ColorRole: DesignColor] = [:]) {
        self.harmony = harmony
        self.fixed = fixed
    }

    /// Harmony `auto`, no role pinned.
    public static let standard = PaletteSpec()
}
