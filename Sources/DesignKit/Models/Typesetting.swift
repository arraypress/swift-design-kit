//
//  Typesetting.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A face: a family and the weight it is set in.
public struct Face: Codable, Equatable, Sendable {
    /// An installed family, a bundled one (`inter`), or an open font by name
    /// (`Playfair Display`, fetched on first use).
    public var family: String
    /// One of the text weights (`regular` … `black`).
    public var weight: String

    public init(family: String, weight: String = "regular") {
        self.family = family
        self.weight = weight
    }
}

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

    public init(pairing: String? = nil, display: Face? = nil, text: Face? = nil, scale: Double? = nil, base: Double? = nil) {
        self.pairing = pairing
        self.display = display
        self.text = text
        self.scale = scale
        self.base = base
    }
}

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
    public var display: [Face]
    public var text: [Face]
    /// The type scale (1.25 minor third … 1.618 golden).
    public var scale: Double
    /// The `body` size, in design units.
    public var base: Double

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

/// An open-licence (OFL 1.1) family from the google/fonts repository at a
/// pinned commit, fetched on first use.
public struct OpenFont: Equatable, Sendable {
    public struct File: Equatable, Sendable {
        public let name: String
        public let sha256: String
        public let bytes: Int
    }

    /// The family name CoreText reads from its files.
    public let family: String
    /// Its folder under `ofl/` in google/fonts.
    public let folder: String
    public let category: FontCategory
    /// The font files and the licence, `OFL.txt`.
    public let files: [File]
    public var licence: String { "OFL-1.1" }

    /// Where a file is fetched from.
    public func url(of file: File) -> URL {
        let escaped = file.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "[],"))) ?? file.name
        return URL(string: "https://raw.githubusercontent.com/google/fonts/\(OpenFonts.commit)/ofl/\(folder)/\(escaped)")!
    }

    /// The font files (not the licence).
    public var fontFiles: [File] { files.filter { $0.name.hasSuffix(".ttf") || $0.name.hasSuffix(".otf") } }
}

/// A family as `design fonts` lists it.
public struct FontFamily: Codable, Equatable, Sendable {
    public var family: String
    /// The name a design uses (`inter` for a bundled face; the family otherwise).
    public var name: String
    /// `installed`, `bundled` or `open` (fetched on first use).
    public var source: String
    public var styles: [String]
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
}
