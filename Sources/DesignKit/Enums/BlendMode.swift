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
    case normal
    case multiply
    case screen
    case overlay
    case darken
    case lighten
    case colorDodge = "color-dodge"
    case colorBurn = "color-burn"
    case softLight = "soft-light"
    case hardLight = "hard-light"
    case difference
    case exclusion
    case hue
    case saturation
    case color
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
