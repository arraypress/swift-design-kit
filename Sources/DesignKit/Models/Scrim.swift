//
//  Scrim.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Sizes are in design units: a thousandth of the canvas's shorter side (of
//  the trimmed page, for print), so an effect reads the same at every size.
//

import Foundation

/// The scrim a background lays over itself so words read.
public struct Scrim: Equatable, Sendable {
    /// Which edge it darkens from.
    public var edge: ScrimEdge
    /// `0…1`; ignored by `auto`, which measures.
    public var strength: Double

    /// A scrim from `edge` at `strength`.
    public init(edge: ScrimEdge = .auto, strength: Double = 0.5) {
        self.edge = edge
        self.strength = strength
    }
}
