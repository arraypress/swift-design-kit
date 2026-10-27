//
//  Template.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

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
    /// The column grid its frames span.
    public var grid: Grid
    /// The type pairing it is set in, unless the maker picks another.
    public var pairing: String?
    /// How its palette roles are found.
    public var palette: PaletteSpec?
    /// The layers as written, `{slot}` markers and all: JSON, read strictly
    /// once the slots are filled (a marker can stand for a colour or a
    /// whole background, which only reads once it is one).
    public var layers: Data

    /// A template called `name`.
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
