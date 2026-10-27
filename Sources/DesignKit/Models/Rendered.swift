//
//  Rendered.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// A finished design: the picture, how it was laid out, and what the checks measured.
public struct Rendered: Sendable {
    /// The design as prepared: made pictures pinned, fonts registered.
    public let prepared: PreparedDesign
    /// Where each layer went and what was decided about it.
    public let plan: Plan
    /// The full-size picture, out to the bleed.
    public let image: CGImage
    /// What the checks measured.
    public let report: CheckReport
}
