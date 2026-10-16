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

    public static let formatVersion = 1

    public var canvas: CanvasSpec
    public var template: String?
    public var vars: [String: String]
    public var grid: Grid
    public var fonts: Typesetting?
    public var palette: PaletteSpec?
    public var googleFonts: String?
    public var brand: String?
    /// A background layer drawn across every page.
    public var background: Layer?
    /// Each page's own layers, drawn over its slice of the background.
    public var pages: [[Layer]]

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

/// A starter carousel: a cover page, a page for each item of one slot
/// (`{item}`, `{n}`, `{count}` fill it), and an end page.
public struct CarouselTemplate: Equatable, Sendable {
    public var name: String
    public var summary: String
    public var preset: String
    public var slots: [TemplateSlot]
    public var pairing: String?
    public var palette: PaletteSpec?
    /// The slot whose items make the middle pages (`|` or new lines between them).
    public var repeats: String
    /// JSON: the background layer, and each kind of page's layers.
    public var background: Data?
    public var cover: Data
    public var each: Data
    public var end: Data?
}
