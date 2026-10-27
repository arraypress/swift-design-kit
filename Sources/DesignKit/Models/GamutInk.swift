//
//  GamutInk.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One word or shape colour, sent to CMYK and back.
public struct GamutInk: Codable, Equatable, Sendable {
    /// The colour, as hex.
    public var color: String
    /// How far it moves (ΔE76).
    public var deltaE: Double
    /// The CMYK it prints as, in percent.
    public var cmyk: [Double]
    /// Whether it moves more than ``PrintColor/outOfGamut``.
    public var outside: Bool
}
