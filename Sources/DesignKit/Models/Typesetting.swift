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

/// An open-licence family from the google/fonts repository at a pinned
/// commit — SIL Open Font License, Apache 2.0 or the Ubuntu Font Licence —
/// fetched on first use with its licence file beside it.
public struct OpenFont: Equatable, Sendable {
    public struct File: Equatable, Sendable {
        public let name: String
        public let sha256: String
        public let bytes: Int
        /// For a font file: italic or upright, and its weight (a variable font's default).
        public let italic: Bool?
        public let weight: Int?
    }

    /// A variable font's axis: its tag (`wght`) and range.
    public struct Axis: Equatable, Sendable, Codable {
        public let tag: String
        public let minimum: Double
        public let maximum: Double
    }

    /// Its Google Fonts name.
    public let family: String
    /// The family CoreText reads from its files (usually the same).
    public let drawnFamily: String
    /// Its folder in google/fonts.
    public let folder: String
    /// `ofl`, `apache` or `ufl`: the licence, and where the folder lives.
    public let licenceFolder: String
    public let category: FontCategory
    /// Variable axes, empty for a static family.
    public let axes: [Axis]
    /// The font files, then the licence file.
    public let files: [File]

    /// The licence, as SPDX names it.
    public var licence: String {
        switch licenceFolder {
        case "apache": "Apache-2.0"
        case "ufl": "UFL-1.0"
        default: "OFL-1.1"
        }
    }

    /// Where a file is fetched from.
    public func url(of file: File) -> URL {
        let escaped = file.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "[],"))) ?? file.name
        return URL(string: "https://raw.githubusercontent.com/google/fonts/\(OpenFonts.commit)/\(licenceFolder)/\(folder)/\(escaped)")!
    }

    /// The font files (not the licence).
    public var fontFiles: [File] { files.filter { $0.name.hasSuffix(".ttf") || $0.name.hasSuffix(".otf") } }

    /// The licence file kept beside the fonts.
    public var licenceFile: File? { files.first { !$0.name.hasSuffix(".ttf") && !$0.name.hasSuffix(".otf") } }

    /// Its styles in words: `Regular`, `Bold Italic`, or a variable range (`100–900`).
    public var styles: [String] {
        let names = [100: "Thin", 200: "ExtraLight", 300: "Light", 400: "Regular", 500: "Medium", 600: "SemiBold",
                     700: "Bold", 800: "ExtraBold", 900: "Black"]
        let weightAxis = axes.first { $0.tag == "wght" }
        return fontFiles.map { file in
            let italic = file.italic == true
            if let weightAxis {
                return "\(Int(weightAxis.minimum))–\(Int(weightAxis.maximum))\(italic ? " Italic" : "")"
            }
            let weight = names[file.weight ?? 400] ?? "\(file.weight ?? 400)"
            return italic ? (weight == "Regular" ? "Italic" : "\(weight) Italic") : weight
        }
    }

    /// One of the few dozen `design fonts` lists without `--google`.
    public var isCurated: Bool { OpenFonts.curated.contains(folder) }

    public init(family: String, drawnFamily: String? = nil, folder: String, licenceFolder: String = "ofl",
                category: FontCategory, axes: [Axis] = [], files: [File]) {
        self.family = family
        self.drawnFamily = drawnFamily ?? family
        self.folder = folder
        self.licenceFolder = licenceFolder
        self.category = category
        self.axes = axes
        self.files = files
    }
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
    /// A variable font's axes: `wght 100–900`.
    public var axes: [String]?

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
