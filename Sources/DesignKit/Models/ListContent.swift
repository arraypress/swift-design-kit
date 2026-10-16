//
//  ListContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A list of names or titles fitted into one box: a festival line-up by
//  billing tier, a tracklist, credits. Sizes are design units.
//

import Foundation

/// A list fitted into the layer's frame: every item kept whole, the
/// biggest size at which all of them fit taken (each tier shrunk by the
/// same share). When drawn it is a set of text lines, each checked like
/// any text layer.
public struct ListContent: Equatable, Sendable {
    /// The items as written: an array, or text — `{slot}` markers and all —
    /// with items split by `|` or new lines, tiers by `||`, and an item's
    /// detail (a running time) after `::`.
    public var items: ListItems
    /// `inline`: each tier's items run on together with a separator, line
    /// breaks balanced (a line-up). `lines`: one item a line, in columns (a tracklist).
    public var flow: ListFlow
    /// Columns, for `lines`.
    public var columns: Int
    /// Each tier's size, top billing first; tiers past the last take the last.
    public var sizes: [Double]
    /// Each tier's weight; `nil` is bold.
    public var weights: [String]?
    /// Between items on a line, for `inline`.
    public var separator: String
    /// `01`, `02`… before each item, for `lines`.
    public var numbered: Bool
    /// As a text layer's `font`: a role, a family, a file.
    public var font: String?
    public var color: Paint
    /// The separators' and numbers' colour; `nil` is the items'.
    public var separatorColor: Paint?
    /// The details' colour (running times); `nil` is the items'.
    public var detailColor: Paint?
    public var align: TextAlign
    public var valign: VerticalAlign
    public var textCase: TextCase
    /// Letter spacing, thousandths of the size.
    public var tracking: Double
    /// The space a line takes, as a multiple of its size.
    public var lineHeight: Double
    /// The smallest share of the sizes the list may shrink to.
    public var minScale: Double

    /// The lines it was laid out into, when prepared — drawn and checked as text layers. Not written to a recipe.
    public var lines: [Layer] = []
    /// Whether every item fitted, when prepared.
    public var fitted: Bool?

    public init(items: ListItems, flow: ListFlow = .inline, columns: Int = 1, sizes: [Double] = [140, 80, 50],
                weights: [String]? = nil, separator: String = "·", numbered: Bool = false, font: String? = nil,
                color: Paint = .color(.white), separatorColor: Paint? = nil, detailColor: Paint? = nil,
                align: TextAlign = .center, valign: VerticalAlign = .middle, textCase: TextCase = .none,
                tracking: Double = 0, lineHeight: Double = 1.25, minScale: Double = 0.3) {
        self.items = items
        self.flow = flow
        self.columns = columns
        self.sizes = sizes
        self.weights = weights
        self.separator = separator
        self.numbered = numbered
        self.font = font
        self.color = color
        self.separatorColor = separatorColor
        self.detailColor = detailColor
        self.align = align
        self.valign = valign
        self.textCase = textCase
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.minScale = minScale
    }

    public static func == (a: ListContent, b: ListContent) -> Bool {
        a.items == b.items && a.flow == b.flow && a.columns == b.columns && a.sizes == b.sizes && a.weights == b.weights
            && a.separator == b.separator && a.numbered == b.numbered && a.font == b.font && a.color == b.color
            && a.separatorColor == b.separatorColor && a.detailColor == b.detailColor && a.align == b.align
            && a.valign == b.valign && a.textCase == b.textCase && a.tracking == b.tracking && a.lineHeight == b.lineHeight
            && a.minScale == b.minScale
    }
}

/// A list's items: written out, or text to split once its slots are filled.
public enum ListItems: Equatable, Sendable {
    case items([ListItem])
    case text(String)
}

/// One name, title or credit.
public struct ListItem: Equatable, Sendable {
    public var text: String
    /// Billing, from 1 (the top).
    public var tier: Int
    /// What sits beside it on its line (a running time), for `lines`.
    public var detail: String?

    public init(text: String, tier: Int = 1, detail: String? = nil) {
        self.text = text
        self.tier = tier
        self.detail = detail
    }
}

public enum ListFlow: String, DesignChoice {
    /// Items run on with separators, lines balanced: a line-up.
    case inline
    /// One item a line, in columns: a tracklist, credits.
    case lines
}
