//
//  TextureKind.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a texture layer draws.
public enum TextureKind: String, DesignChoice {
    /// Paper fibre: soft blotches and fine grain.
    case paper
    /// A dot screen whose dots grow across the frame.
    case halftone
    /// Even per-pixel noise.
    case noise
    /// Horizontal lines, a monitor's or a print's.
    case scanlines
    /// Film dust: specks and hairs.
    case dust

    /// The mark size it draws at unless told, in design units.
    var defaultScale: Double {
        switch self {
        case .paper: 6
        case .halftone: 14
        case .noise: 1
        case .scanlines: 6
        case .dust: 3
        }
    }
}
