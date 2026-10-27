//
//  TextMeasure.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One text layer, measured on the drawn pixels.
public struct TextMeasure: Codable, Equatable, Sendable {
    /// The layer's path.
    public var layer: String
    /// The layer's id, when it has one.
    public var id: String?
    /// The words as drawn (markup removed).
    public var words: String
    /// The size drawn, after any shrinking: pixels, and design units.
    public var sizePixels: Double
    /// The size drawn, in design units.
    public var sizeUnits: Double
    /// Points on paper, for print.
    public var sizePoints: Double?
    /// How many lines it was set in.
    public var lines: Int
    /// Whether it fits its frame.
    public var fits: Bool
    /// Where the ink is, pixels, top-left: `[x, y, width, height]`.
    public var ink: [Double]?
    /// Whether its ink stays inside the safe area.
    public var insideSafe: Bool
    /// Whether its ink stays inside the trim.
    public var insideTrim: Bool
    /// WCAG ratio of the letters against the ring of pixels round them.
    public var contrast: Double?
    /// The ratio it needs: 3 for large type, 4.5 otherwise.
    public var contrastNeeded: Double
    /// Share of the words on-device text recognition reads back; `nil` when
    /// recognition could not run.
    public var readBack: Double?
    /// Share of the letters' pixels on the subject of the art under them
    /// (Vision's foreground mask); `0` when there is no subject, `nil` when
    /// Vision could not run.
    public var onSubject: Double?
    /// The letters' colour, as decided.
    public var color: String
    /// The plate's colour, when one is drawn.
    public var plate: String?
    /// The anchor `avoid` moved it to, when it did.
    public var movedTo: String?
    /// Why it moved, or how much of what it avoids it still covers.
    public var note: String?
}
