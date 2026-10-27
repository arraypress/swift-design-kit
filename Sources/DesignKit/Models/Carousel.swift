//
//  Carousel.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Several pages of one canvas that are swiped through — a carousel post —
/// sharing their type, palette, slots and, when it has one, one background
/// drawn across all of them (each page shows its slice, so the art runs on
/// from page to page). Its recipe is `"carousel": 1`.
public struct Carousel: Equatable, Sendable {

    /// The recipe format this build writes and reads.
    public static let formatVersion = 1

    /// The page every slide shares.
    public var canvas: CanvasSpec
    /// The template it was made from, for the record.
    public var template: String?
    /// The template's slots and the values they hold.
    public var vars: [String: String]
    /// The column grid, as a design's.
    public var grid: Grid
    /// The type, as a design's.
    public var fonts: Typesetting?
    /// How the palette roles are found, as a design's.
    public var palette: PaletteSpec?
    /// The google/fonts commit its Google faces were fetched at.
    public var googleFonts: String?
    /// The brand kit it was made with, by name, for the record.
    public var brand: String?
    /// A background layer drawn across every page.
    public var background: Layer?
    /// Each page's own layers, drawn over its slice of the background.
    public var pages: [[Layer]]

    /// A carousel of `pages` on `canvas`.
    public init(canvas: CanvasSpec, template: String? = nil, vars: [String: String] = [:], grid: Grid = .standard,
                fonts: Typesetting? = nil, palette: PaletteSpec? = nil, googleFonts: String? = nil, brand: String? = nil,
                background: Layer? = nil, pages: [[Layer]]) {
        self.canvas = canvas
        self.template = template
        self.vars = vars
        self.grid = grid
        self.fonts = fonts
        self.palette = palette
        self.googleFonts = googleFonts
        self.brand = brand
        self.background = background
        self.pages = pages
    }
}
