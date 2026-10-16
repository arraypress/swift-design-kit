//
//  ColorRole.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A colour by the part it plays, taken from the art: what words and shapes
/// name so a design keeps to a few colours that belong to its picture.
public enum ColorRole: String, DesignChoice {
    /// The art's main colour (its largest share).
    case dominant
    /// The art's second colour.
    case secondary
    /// The colour that stands out: from the art when it has one far enough
    /// round the wheel, else made by the harmony rule.
    case accent
    /// A quiet colour: the dominant's hue with almost no chroma.
    case neutral
    /// Near-white, tinted with the dominant's hue.
    case light
    /// Near-black, tinted with the dominant's hue.
    case dark
}

/// How the accent is found from the dominant colour, round the OKLCh wheel.
public enum Harmony: String, DesignChoice {
    /// The art's own most colourful colour far enough from the dominant;
    /// else complementary.
    case auto
    /// 30° away: calm, close.
    case analogous
    /// 180° away: the strongest contrast.
    case complementary
    /// 150° away: contrast with less clash.
    case split
    /// The dominant's own hue, lighter or darker: one colour.
    case mono
}
