//
//  Typography.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The finer type controls a text layer takes: words set along a path,
//  letters extruded into depth, a line drawn inside them, and styling for
//  some of the letters only. Sizes are design units.
//

import Foundation

/// A line the words are set along instead of across the frame.
public struct TextPath: Equatable, Sendable {
    public var shape: TextPathShape
    /// An arc's curve, `-1…1`: positive bows up (a rainbow), negative down (a smile).
    public var bend: Double
    /// Where on a circle the words are centred, degrees clockwise from the top.
    public var start: Double
    /// A wave's crests across the frame.
    public var waves: Double
    /// A wave's height, as a fraction of the frame's height.
    public var amplitude: Double

    public init(shape: TextPathShape, bend: Double = 0.5, start: Double = 0, waves: Double = 1.5, amplitude: Double = 0.25) {
        self.shape = shape
        self.bend = bend
        self.start = start
        self.waves = waves
        self.amplitude = amplitude
    }
}

/// Letters extruded into depth: copies stacked back from the face, shaded darker the further back they sit.
public struct Extrude: Equatable, Sendable {
    /// How deep, in design units.
    public var depth: Double
    /// Which way the depth runs, degrees clockwise from up (`135`: down and right).
    public var angle: Double
    /// The colour of the sides; `auto` is the letters' colour, darkened.
    public var color: Paint
    /// How much darker the back is than the front, `0…1`.
    public var shade: Double

    public init(depth: Double = 24, angle: Double = 135, color: Paint = .auto, shade: Double = 0.5) {
        self.depth = depth
        self.angle = angle
        self.color = color
        self.shade = shade
    }
}

/// A line drawn inside the letters, following their outline (the inline
/// display style). For an outline alone, `stroke` with `"style": "hollow"`.
public struct Inline: Equatable, Sendable {
    public var color: Paint
    /// The line's thickness, in design units.
    public var width: Double
    /// How far inside the letters' edge it runs, in design units.
    public var inset: Double

    public init(color: Paint = .color(.white), width: Double = 3, inset: Double = 4) {
        self.color = color
        self.width = width
        self.inset = inset
    }
}

/// Styling for some of the letters: a range of characters, a word, or every
/// place some words appear — counted in the words as drawn (slots filled,
/// markup removed, cased).
public struct LetterStyle: Equatable, Sendable {
    /// Characters `[from, to)` from 0.
    public var range: [Int]?
    /// The nth word, from 1 (negative counts from the end: `-1` is the last).
    public var word: Int?
    /// Every place these words appear (case ignored).
    public var match: String?
    public var color: Paint?
    /// A multiple of the layer's size.
    public var size: Double?
    public var weight: String?
    /// How far above the baseline, as a fraction of the layer's size.
    public var baseline: Double?
    /// Extra space after each letter, in thousandths of the size.
    public var tracking: Double?

    public init(range: [Int]? = nil, word: Int? = nil, match: String? = nil, color: Paint? = nil, size: Double? = nil,
                weight: String? = nil, baseline: Double? = nil, tracking: Double? = nil) {
        self.range = range
        self.word = word
        self.match = match
        self.color = color
        self.size = size
        self.weight = weight
        self.baseline = baseline
        self.tracking = tracking
    }
}
