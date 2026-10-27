//
//  BlendMode.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// How a layer combines with what is under it.
public enum BlendMode: String, DesignChoice {
    /// Drawn over what is under it.
    case normal
    /// Darkens: the colours multiplied.
    case multiply
    /// Lightens: the inverse of multiply.
    case screen
    /// Multiply in the darks, screen in the lights.
    case overlay
    /// The darker of the two, channel by channel.
    case darken
    /// The lighter of the two, channel by channel.
    case lighten
    /// Brightens what is under it by the layer's colour.
    case colorDodge = "color-dodge"
    /// Darkens what is under it by the layer's colour.
    case colorBurn = "color-burn"
    /// A gentle overlay, lit softly.
    case softLight = "soft-light"
    /// Overlay with the layer and what is under it swapped.
    case hardLight = "hard-light"
    /// The difference of the two colours.
    case difference
    /// Like difference, with less contrast.
    case exclusion
    /// The layer's hue, the rest from what is under it.
    case hue
    /// The layer's saturation, the rest from what is under it.
    case saturation
    /// The layer's hue and saturation, the lightness from what is under it.
    case color
    /// The layer's lightness, the colour from what is under it.
    case luminosity
    /// Linear burn: CoreGraphics' plus-darker.
    case linearBurn = "linear-burn"
    /// Linear dodge (add): CoreGraphics' plus-lighter.
    case linearDodge = "linear-dodge"

    /// The CoreGraphics mode that draws it — the same in a bitmap and a PDF
    /// (PDF has no linear burn or dodge; a PDF draws those layers as pictures).
    public var cgBlendMode: CGBlendMode {
        switch self {
        case .normal: .normal
        case .multiply: .multiply
        case .screen: .screen
        case .overlay: .overlay
        case .darken: .darken
        case .lighten: .lighten
        case .colorDodge: .colorDodge
        case .colorBurn: .colorBurn
        case .softLight: .softLight
        case .hardLight: .hardLight
        case .difference: .difference
        case .exclusion: .exclusion
        case .hue: .hue
        case .saturation: .saturation
        case .color: .color
        case .luminosity: .luminosity
        case .linearBurn: .plusDarker
        case .linearDodge: .plusLighter
        }
    }

    /// Photoshop's four-letter key for it.
    public var psdKey: String {
        switch self {
        case .normal: "norm"
        case .multiply: "mul "
        case .screen: "scrn"
        case .overlay: "over"
        case .darken: "dark"
        case .lighten: "lite"
        case .colorDodge: "div "
        case .colorBurn: "idiv"
        case .softLight: "sLit"
        case .hardLight: "hLit"
        case .difference: "diff"
        case .exclusion: "smud"
        case .hue: "hue "
        case .saturation: "sat "
        case .color: "colr"
        case .luminosity: "lum "
        case .linearBurn: "lbrn"
        case .linearDodge: "lddg"
        }
    }
}
