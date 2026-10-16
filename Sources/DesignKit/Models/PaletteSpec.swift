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
    public var harmony: Harmony
    /// Roles set by hand (`accent: #FF3366`), which win over the art.
    public var fixed: [ColorRole: DesignColor]

    public init(harmony: Harmony = .auto, fixed: [ColorRole: DesignColor] = [:]) {
        self.harmony = harmony
        self.fixed = fixed
    }

    public static let standard = PaletteSpec()
}

/// The palette as found for one design: every role's colour, and where it came from.
public struct PaletteRoles: Codable, Equatable, Sendable {
    public var dominant: DesignColor
    public var secondary: DesignColor
    public var accent: DesignColor
    public var neutral: DesignColor
    public var light: DesignColor
    public var dark: DesignColor
    /// `art` (the accent is one of the art's colours) or the harmony rule that made it.
    public var accentFrom: String

    public subscript(role: ColorRole) -> DesignColor {
        switch role {
        case .dominant: dominant
        case .secondary: secondary
        case .accent: accent
        case .neutral: neutral
        case .light: light
        case .dark: dark
        }
    }
}
