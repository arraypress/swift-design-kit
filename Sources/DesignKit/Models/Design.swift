//
//  Design.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A one-page design — and its recipe, `"design": 1`.
///
/// The canvas, every layer in order, the template it came from and the
/// values its slots were filled with. Made pictures and looks are pinned in
/// it (model, revision, seed, prompt; the grade inline), so the same design
/// on the same build draws the same pixels.
public struct Design: Equatable, Sendable {

    /// The recipe format this build writes and reads.
    public static let formatVersion = 1

    public var canvas: CanvasSpec
    /// The template it was made from, for the record.
    public var template: String?
    /// The template's slots and the values they hold. Text keeps its
    /// `{slot}` markers, so changing a value here changes the words.
    public var vars: [String: String]
    public var grid: Grid
    /// The type: a pairing, and the faces it resolved to (pinned when made).
    public var fonts: Typesetting?
    /// How the palette roles (`accent`, `dominant`…) are found from the art.
    public var palette: PaletteSpec?
    /// The google/fonts commit its Google faces were fetched at — pinned when
    /// made, so a replay on a build that fetches from another commit says so.
    public var googleFonts: String?
    /// The brand kit it was made with, by name — for the record only: the
    /// brand's colours, faces and logo are written into the design itself.
    public var brand: String?
    /// How it moves when written as a video (`-o loop.mp4`).
    public var motion: MotionSpec?
    public var layers: [Layer]

    public init(canvas: CanvasSpec, template: String? = nil, vars: [String: String] = [:],
                grid: Grid = .standard, fonts: Typesetting? = nil, palette: PaletteSpec? = nil,
                googleFonts: String? = nil, brand: String? = nil, layers: [Layer]) {
        self.canvas = canvas
        self.template = template
        self.vars = vars
        self.grid = grid
        self.fonts = fonts
        self.palette = palette
        self.googleFonts = googleFonts
        self.brand = brand
        self.motion = nil
        self.layers = layers
    }
}

/// A starter design with slots: `cover-clean` with `title`, `artist`,
/// `background`.
public struct Template: Equatable, Sendable {
    /// Kebab-case: `cover-clean`.
    public var name: String
    /// What it is, in a line.
    public var summary: String
    /// The preset it is drawn for.
    public var preset: String
    /// The values it takes (`--var title=…`), each with a default.
    public var slots: [TemplateSlot]
    public var grid: Grid
    /// The type pairing it is set in, unless the maker picks another.
    public var pairing: String?
    /// How its palette roles are found.
    public var palette: PaletteSpec?
    /// The layers as written, `{slot}` markers and all: JSON, read strictly
    /// once the slots are filled (a marker can stand for a colour or a
    /// whole background, which only reads once it is one).
    public var layers: Data

    public init(name: String, summary: String, preset: String, slots: [TemplateSlot], grid: Grid = .standard,
                pairing: String? = nil, palette: PaletteSpec? = nil, layers: Data) {
        self.name = name
        self.summary = summary
        self.preset = preset
        self.slots = slots
        self.grid = grid
        self.pairing = pairing
        self.palette = palette
        self.layers = layers
    }
}

/// One value a template takes.
public struct TemplateSlot: Equatable, Sendable, Codable {
    /// Lowercase: `title`.
    public var name: String
    /// What it fills, in a few words.
    public var summary: String
    /// Used when no value is given.
    public var defaultValue: String

    public init(name: String, summary: String, defaultValue: String) {
        self.name = name
        self.summary = summary
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name, summary
        case defaultValue = "default"
    }
}
