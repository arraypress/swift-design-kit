//
//  FontFamily.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A family as `design fonts` lists it.
public struct FontFamily: Codable, Equatable, Sendable {
    /// The family's own name.
    public var family: String
    /// The name a design uses (`inter` for a bundled face; the family otherwise).
    public var name: String
    /// `installed`, `bundled` or `open` (fetched on first use).
    public var source: String
    /// Its styles in words: `Regular`, `Bold Italic`, `100–900`.
    public var styles: [String]
    /// Serif, sans, mono, display, script or symbol.
    public var category: FontCategory
    /// A few words for its feel, from its traits.
    public var mood: String
    /// Whether its licence bits allow embedding it in a PDF (`nil`: not known
    /// until fetched). When not, the PDF draws its words as pictures.
    public var embeddable: Bool?
    /// The licence, for open fonts.
    public var licence: String?
    /// Whether an open font is already fetched.
    public var fetched: Bool?
    /// A variable font's axes: `wght 100–900`.
    public var axes: [String]?

    /// A family as listed.
    public init(family: String, name: String, source: String, styles: [String], category: FontCategory, mood: String,
                embeddable: Bool?, licence: String?, fetched: Bool?, axes: [String]? = nil) {
        self.family = family
        self.name = name
        self.source = source
        self.styles = styles
        self.category = category
        self.mood = mood
        self.embeddable = embeddable
        self.licence = licence
        self.fetched = fetched
        self.axes = axes
    }
}
