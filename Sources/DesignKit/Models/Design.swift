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

    /// The page.
    public var canvas: CanvasSpec
    /// The template it was made from, for the record.
    public var template: String?
    /// The template's slots and the values they hold. Text keeps its
    /// `{slot}` markers, so changing a value here changes the words.
    public var vars: [String: String]
    /// The column grid frames span.
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
    /// Every layer, back to front.
    public var layers: [Layer]

    /// A design of `layers` on `canvas`.
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
