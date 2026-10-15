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
    case softLight = "soft-light"

    /// The CoreGraphics mode that draws it — the same in a bitmap and a PDF.
    public var cgBlendMode: CGBlendMode {
        switch self {
        case .normal: .normal
        case .multiply: .multiply
        case .screen: .screen
        case .overlay: .overlay
        case .softLight: .softLight
        }
    }
}
