//
//  Fade.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Fades a layer out toward one edge (or out from its centre).
public struct Fade: Equatable, Sendable {
    /// Where it fades to.
    public var edge: FadeEdge
    /// Fully there up to this far across the frame toward the edge (`0…1`)…
    public var start: Double
    /// …and gone by here.
    public var end: Double

    /// A fade toward `edge`, from `start` to `end`.
    public init(edge: FadeEdge = .bottom, start: Double = 0.5, end: Double = 1) {
        self.edge = edge
        self.start = start
        self.end = end
    }
}
