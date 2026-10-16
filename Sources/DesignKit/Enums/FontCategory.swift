//
//  FontCategory.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What kind of face a family is, guessed from its traits (CoreText's
/// stylistic class and the monospace bit) and, where those are silent, its name.
public enum FontCategory: String, DesignChoice {
    case serif
    case sans
    case mono
    /// Made for large sizes only: fat faces, ornamental, stencil, inline.
    case display
    /// Handwriting, brush and connected scripts.
    case script
    /// Symbols, dingbats, emoji, braille.
    case symbol
}
