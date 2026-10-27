//
//  OpenFont.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An open-licence family from the google/fonts repository at a pinned
/// commit — SIL Open Font License, Apache 2.0 or the Ubuntu Font Licence —
/// fetched on first use with its licence file beside it.
public struct OpenFont: Equatable, Sendable {
    /// One file in the family's folder: a font or the licence.
    public struct File: Equatable, Sendable {
        /// The file's name in the folder.
        public let name: String
        /// Its SHA-256, measured at the pinned commit.
        public let sha256: String
        /// Its size.
        public let bytes: Int
        /// For a font file: italic or upright, and its weight (a variable font's default).
        public let italic: Bool?
        /// Its weight, `100…900`.
        public let weight: Int?
    }

    /// A variable font's axis: its tag (`wght`) and range.
    public struct Axis: Equatable, Sendable, Codable {
        /// The axis tag: `wght`, `wdth`, `opsz`…
        public let tag: String
        /// The axis's lowest value.
        public let minimum: Double
        /// The axis's highest value.
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
    /// Serif, sans, mono, display, script or symbol.
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

    /// A family from the index.
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
