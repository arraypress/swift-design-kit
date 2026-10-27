//
//  Preset.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A named page size with its safe area and the rules the place it is going
/// to sets.
public struct Preset: Equatable, Sendable, Codable {

    /// `cover`, `story`, `a4`…
    public var name: String
    /// What it is for, in a line.
    public var summary: String
    /// The finished size in pixels (screen) or millimetres (print, with `dpi`).
    public var width: Double
    /// The finished height, in pixels or millimetres as `width` is.
    public var height: Double
    /// Set for print: sizes are millimetres and become pixels at this resolution.
    public var dpi: Double?
    /// Print bleed, millimetres.
    public var bleedMM: Double
    /// Where words stay clear of what the destination draws over or crops.
    public var safe: Insets
    /// What the destination requires, checked on every make.
    public var rules: PlatformRules

    /// A preset called `name`.
    public init(name: String, summary: String, width: Double, height: Double, dpi: Double? = nil,
                bleedMM: Double = 0, safe: Insets, rules: PlatformRules = PlatformRules()) {
        self.name = name
        self.summary = summary
        self.width = width
        self.height = height
        self.dpi = dpi
        self.bleedMM = bleedMM
        self.safe = safe
        self.rules = rules
    }
}
