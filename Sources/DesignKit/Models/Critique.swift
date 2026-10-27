//
//  Critique.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One design, judged.
public struct Critique: Codable, Equatable, Sendable {
    /// The design's name.
    public var design: String
    /// The whole judgement in a line.
    public var verdict: String
    /// A check failed: not ready to use.
    public var blocking: Bool
    /// The weakest words' contrast (WCAG ratio), and the lowest read-back.
    public var contrast: Double?
    /// The lowest share of any words read back.
    public var readBack: Double?
    /// The most of any words' letters on the art's subject.
    public var onSubject: Double
    /// Every text block fits its frame.
    public var fits: Bool
    /// How many faces the words are set in.
    public var faces: Int
    /// How many colours words and shapes are drawn in, besides the art's own.
    public var colors: Int
    /// Every block lines up with another or with the page; the ones that do not.
    public var aligned: Bool
    /// The blocks that line up with nothing, by id.
    public var loose: [String]
    /// The space round all the words.
    public var margins: Margins
    /// The largest size over the next one down.
    public var hierarchy: Double?
    /// The checks' findings, and the layout's.
    public var findings: [Finding]
}
