//
//  Brand.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A brand kit: a logo, colours for the palette roles, and the type — laid
/// over any template or recipe. Applied by value: the colours, faces and
/// logo go into the design itself, so a recipe replays the same after the
/// brand changes.
public struct Brand: Equatable, Sendable {
    /// Lowercase, kebab-case: `mine`.
    public var name: String
    /// The logo picture (a path; the CLI keeps a copy named by its content).
    public var logo: String?
    /// Palette roles the brand pins (`accent`, `dark`…).
    public var colors: [ColorRole: DesignColor]
    /// A type pairing, or faces given by hand.
    public var pairing: String?
    public var display: Face?
    public var text: Face?
    /// Where the logo goes; `nil` picks the corner the words leave free.
    public var corner: Anchor?
    /// The logo's width, as a share of the safe area's width.
    public var logoWidth: Double

    public init(name: String, logo: String? = nil, colors: [ColorRole: DesignColor] = [:], pairing: String? = nil,
                display: Face? = nil, text: Face? = nil, corner: Anchor? = nil, logoWidth: Double = 0.14) {
        self.name = name
        self.logo = logo
        self.colors = colors
        self.pairing = pairing
        self.display = display
        self.text = text
        self.corner = corner
        self.logoWidth = logoWidth
    }
}
