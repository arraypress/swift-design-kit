//
//  ScrimEdge.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Which edge a background's scrim darkens from.
public enum ScrimEdge: String, DesignChoice {
    /// Darkest at the bottom.
    case bottom
    /// Darkest at the top.
    case top
    /// Darkest at the top and the bottom.
    case both
    /// Measured: deep where the words sit over something bright, light where
    /// they already read, on the edge they are nearest.
    case auto
}
