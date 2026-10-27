//
//  Pairing.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A display face and a text face that go together, with the rhythm of
/// sizes they are set at. Each role lists candidates in order: faces this
/// Mac ships first, then bundled and open ones (fetched on first use) — the
/// first that is here, or can be fetched, is taken.
public struct Pairing: Codable, Equatable, Sendable {
    /// Kebab-case: `editorial`.
    public var name: String
    /// What it looks like, in a line.
    public var summary: String
    /// Words for the feel of it: `elegant`, `loud`, `technical`.
    public var mood: [String]
    /// Candidates for the display face, in order.
    public var display: [Face]
    /// Candidates for the text face, in order.
    public var text: [Face]
    /// The type scale (1.25 minor third … 1.618 golden).
    public var scale: Double
    /// The `body` size, in design units.
    public var base: Double

    /// A pairing called `name`.
    public init(name: String, summary: String, mood: [String], display: [Face], text: [Face], scale: Double, base: Double) {
        self.name = name
        self.summary = summary
        self.mood = mood
        self.display = display
        self.text = text
        self.scale = scale
        self.base = base
    }
}
