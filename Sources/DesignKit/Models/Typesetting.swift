//
//  Typesetting.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The type a design is set in: a pairing from the catalogue, and the two
/// faces it resolved to — pinned when the design is made, so a replay sets
/// the same faces. Text layers name the roles (`"font": "display"`,
/// `"font": "text"`) rather than faces.
public struct Typesetting: Equatable, Sendable {
    /// A pairing's name (`editorial`), or `nil` for faces given by hand.
    public var pairing: String?
    /// The face for titles and the other large words.
    public var display: Face?
    /// The face for everything else.
    public var text: Face?
    /// The type scale: each named size step is this many times the last.
    public var scale: Double?
    /// The `body` size, in design units.
    public var base: Double?

    /// Type by pairing, by faces, or both.
    public init(pairing: String? = nil, display: Face? = nil, text: Face? = nil, scale: Double? = nil, base: Double? = nil) {
        self.pairing = pairing
        self.display = display
        self.text = text
        self.scale = scale
        self.base = base
    }
}
