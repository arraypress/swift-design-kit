//
//  PaletteRoles.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The palette as found for one design: every role's colour, and where it came from.
public struct PaletteRoles: Codable, Equatable, Sendable {
    /// The art's main colour.
    public var dominant: DesignColor
    /// The art's second colour.
    public var secondary: DesignColor
    /// The colour that stands out.
    public var accent: DesignColor
    /// A quiet colour: the dominant's hue, little chroma.
    public var neutral: DesignColor
    /// Near-white, tinted with the dominant's hue.
    public var light: DesignColor
    /// Near-black, tinted with the dominant's hue.
    public var dark: DesignColor
    /// `art` (the accent is one of the art's colours) or the harmony rule that made it.
    public var accentFrom: String

    /// The colour for `role`.
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
