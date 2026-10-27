//
//  TextFitMode.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Whether text shrinks to fit its frame.
public enum TextFitMode: String, DesignChoice {
    /// Step the size down until it fits (height, `max_lines`, a single word on one line).
    case shrink
    /// Draw at the size given; overflow is reported by the checks.
    case none
}
