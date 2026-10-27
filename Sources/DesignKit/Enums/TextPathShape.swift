//
//  TextPathShape.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The line `path` sets words along.
public enum TextPathShape: String, DesignChoice {
    /// Bowed across the frame: up (a rainbow) or down (a smile), by `bend`.
    case arc
    /// Round a circle inscribed in the frame, centred at `start`.
    case circle
    /// A sine wave across the frame.
    case wave
}
