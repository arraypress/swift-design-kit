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
    public var height: Double
    /// Set for print: sizes are millimetres and become pixels at this resolution.
    public var dpi: Double?
    /// Print bleed, millimetres.
    public var bleedMM: Double
    public var safe: Insets
    public var rules: PlatformRules

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

/// What a destination requires of a picture, checked on every make.
public struct PlatformRules: Equatable, Sendable, Codable {
    /// The smallest it takes, in pixels.
    public var minimumWidth: Int?
    public var minimumHeight: Int?
    /// The largest it takes, in pixels.
    public var maximumWidth: Int?
    public var maximumHeight: Int?
    /// Must be exactly square.
    public var square: Bool
    /// Must carry bleed (print).
    public var needsBleed: Bool

    public init(minimumWidth: Int? = nil, minimumHeight: Int? = nil, maximumWidth: Int? = nil,
                maximumHeight: Int? = nil, square: Bool = false, needsBleed: Bool = false) {
        self.minimumWidth = minimumWidth
        self.minimumHeight = minimumHeight
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
        self.square = square
        self.needsBleed = needsBleed
    }
}
