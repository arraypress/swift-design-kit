//
//  TextPath.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A line the words are set along instead of across the frame.
public struct TextPath: Equatable, Sendable {
    /// The line: an arc, a circle or a wave.
    public var shape: TextPathShape
    /// An arc's curve, `-1…1`: positive bows up (a rainbow), negative down (a smile).
    public var bend: Double
    /// Where on a circle the words are centred, degrees clockwise from the top.
    public var start: Double
    /// A wave's crests across the frame.
    public var waves: Double
    /// A wave's height, as a fraction of the frame's height.
    public var amplitude: Double

    /// A path of `shape`.
    public init(shape: TextPathShape, bend: Double = 0.5, start: Double = 0, waves: Double = 1.5, amplitude: Double = 0.25) {
        self.shape = shape
        self.bend = bend
        self.start = start
        self.waves = waves
        self.amplitude = amplitude
    }
}
