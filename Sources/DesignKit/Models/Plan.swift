//
//  Plan.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CanvasKit
import CoreGraphics
import Foundation

/// Where each layer went and what was decided about it as it was drawn.
public struct Plan: Sendable {
    /// Frames, pixels, origin top-left.
    public var frames: [String: CGRect]
    /// Each text layer's laid-out lines (CoreGraphics space of the full bitmap).
    public var fits: [String: TextFit]
    /// Each text layer's ink colour and plate colour, as decided.
    public var text: [String: TextDecision]
    /// The art under text layers, keyed by which art layers it is.
    var art: [String: ArtLook] = [:]
    /// The palette roles, from the art.
    public var palette: PaletteRoles?

    /// The colour `paint` stands for: a colour, a role from the palette;
    /// `nil` for `auto` (decided per layer) or a role with no palette.
    func color(_ paint: Paint?) -> DesignColor? {
        switch paint {
        case .color(let color)?: color
        case .role(let role)?: palette?[role]
        case .auto?, nil: nil
        }
    }
}
