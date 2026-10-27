//
//  GamutReport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How the design's colours fare in CMYK.
public struct GamutReport: Codable, Equatable, Sendable {
    /// The share of the picture's pixels that move more than ``PrintColor/outOfGamut``.
    public var outside: Double
    /// The furthest any pixel moves (ΔE76).
    public var worst: Double
    /// Each word and shape colour: how far it moves, and the CMYK it prints as (percent).
    public var inks: [GamutInk]
}
