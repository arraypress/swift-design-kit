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
