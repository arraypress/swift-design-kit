//
//  TextContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Words.
public struct TextContent: Equatable, Sendable {
    /// The words. `{slot}` markers are filled from the design's vars;
    /// `**accent**`, `*italic*` and `~muted~` style spans.
    public var text: String
    /// A role (`display`, `text`: the design's pairing says which face), a
    /// family installed on this Mac, a bundled face (`inter`, `source-serif`,
    /// `jetbrains-mono`), an open font (fetched on first use), or a path to a
    /// `.ttf` / `.otf`. `nil` is the system face.
    public var font: String?
    /// `thin` … `black`; `nil` is the role's weight, or bold.
    public var weight: String?
    /// Size, in design units.
    public var size: Double
    /// A named size on the design's type scale (`title`, `body`…), used instead of `size`.
    public var step: SizeStep?
    /// The smallest `fit: shrink` goes, in design units.
    public var minSize: Double?
    /// The most lines the words may take.
    public var maxLines: Int?
    /// Whether the words shrink to fit the frame.
    public var fit: TextFitMode
    /// Letter spacing, in thousandths of the size.
    public var tracking: Double
    /// A multiple of the natural line height.
    public var lineHeight: Double
    /// How the words are cased when drawn.
    public var textCase: TextCase
    /// How lines align across the frame.
    public var align: TextAlign
    /// Where the block of lines sits, top to bottom.
    public var valign: VerticalAlign
    /// The letters' colour.
    public var color: Paint
    /// The colour `**accent**` spans take.
    public var accent: Paint?
    /// The colour `~muted~` spans take.
    public var muted: Paint?
    /// Letters filled with a blend, top to bottom.
    public var gradient: [DesignColor]?
    /// A keyline round the letters, or the outline alone.
    public var stroke: Stroke?
    /// A panel behind the lines.
    public var plate: Plate?
    /// What the words keep clear of, moving to another anchor when they would cover it.
    public var avoid: [Avoid]
    /// Variable-font axes by tag (`wght`, `wdth`, `slnt`, `opsz`, or the font's own).
    public var axes: [String: Double]?
    /// OpenType features by tag, 1 on and 0 off (`smcp`, `liga`, `tnum`, `onum`, `ss01`).
    public var features: [String: Int]?
    /// Styling for some of the letters.
    public var letters: [LetterStyle]?
    /// Set along an arc, a circle or a wave instead of across the frame (one line).
    public var path: TextPath?
    /// Depth behind the letters.
    public var extrude: Extrude?
    /// A line inside the letters.
    public var inline: Inline?

    /// Words, set by these rules.
    public init(text: String, font: String? = nil, weight: String? = nil, size: Double = 80, step: SizeStep? = nil,
                minSize: Double? = nil, maxLines: Int? = nil, fit: TextFitMode = .shrink, tracking: Double = 0,
                lineHeight: Double = 1, textCase: TextCase = .none, align: TextAlign = .center,
                valign: VerticalAlign = .middle, color: Paint = .color(.white), accent: Paint? = nil,
                muted: Paint? = nil, gradient: [DesignColor]? = nil, stroke: Stroke? = nil,
                plate: Plate? = nil, avoid: [Avoid] = [], axes: [String: Double]? = nil, features: [String: Int]? = nil,
                letters: [LetterStyle]? = nil, path: TextPath? = nil, extrude: Extrude? = nil, inline: Inline? = nil) {
        self.text = text
        self.font = font
        self.weight = weight
        self.size = size
        self.step = step
        self.minSize = minSize
        self.maxLines = maxLines
        self.fit = fit
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.textCase = textCase
        self.align = align
        self.valign = valign
        self.color = color
        self.accent = accent
        self.muted = muted
        self.gradient = gradient
        self.stroke = stroke
        self.plate = plate
        self.avoid = avoid
        self.axes = axes
        self.features = features
        self.letters = letters
        self.path = path
        self.extrude = extrude
        self.inline = inline
    }
}
