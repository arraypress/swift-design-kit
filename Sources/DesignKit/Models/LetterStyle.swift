//
//  LetterStyle.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

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
    /// Their colour.
    public var color: Paint?
    /// A multiple of the layer's size.
    public var size: Double?
    /// Their weight (`thin` … `black`).
    public var weight: String?
    /// How far above the baseline, as a fraction of the layer's size.
    public var baseline: Double?
    /// Extra space after each letter, in thousandths of the size.
    public var tracking: Double?

    /// Styling for the letters a range, a word or a match picks.
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
