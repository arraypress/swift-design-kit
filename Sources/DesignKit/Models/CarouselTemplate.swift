//
//  CarouselTemplate.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A starter carousel: a cover page, a page for each item of one slot
/// (`{item}`, `{n}`, `{count}` fill it), and an end page.
public struct CarouselTemplate: Equatable, Sendable {
    /// Kebab-case: `carousel-steps`.
    public var name: String
    /// What it is, in a line.
    public var summary: String
    /// The preset it is drawn for.
    public var preset: String
    /// The values it takes, each with a default.
    public var slots: [TemplateSlot]
    /// The type pairing it is set in.
    public var pairing: String?
    /// How its palette roles are found.
    public var palette: PaletteSpec?
    /// The slot whose items make the middle pages (`|` or new lines between them).
    public var repeats: String
    /// JSON: the background layer, and each kind of page's layers.
    public var background: Data?
    /// The cover page's layers.
    public var cover: Data
    /// The layers of the page made for each item.
    public var each: Data
    /// The end page's layers.
    public var end: Data?
}
