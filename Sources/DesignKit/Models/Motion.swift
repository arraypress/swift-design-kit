//
//  Motion.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How an animated cover moves: a seamless loop of the art under still
/// words — for a Spotify Canvas or a story. No video model: the design's own
/// art is pushed, drifted or split by depth, with light and grain over it.
public struct MotionSpec: Equatable, Sendable {
    public var kind: MotionKind
    /// The loop's length, 3…8 seconds.
    public var seconds: Double
    /// Frames a second.
    public var fps: Int
    /// How far it moves: the share the art is pushed in, drifted or parted, `0.01…0.2`.
    public var amount: Double
    /// Light leaks over the art, `0…1`.
    public var leaks: Double
    /// Specks of dust drifting up, how many.
    public var particles: Int
    /// Film grain over the art, `0…1`.
    public var grain: Double
    /// The seed for the leaks, specks and grain.
    public var seed: UInt64
    /// For `parallax`: the depth model and the fill model that ran, written when made.
    public var depthModel: String?
    public var fillModel: String?

    public init(kind: MotionKind = .zoom, seconds: Double = 6, fps: Int = 30, amount: Double = 0.06, leaks: Double = 0,
                particles: Int = 0, grain: Double = 0.04, seed: UInt64 = 1, depthModel: String? = nil, fillModel: String? = nil) {
        self.kind = kind
        self.seconds = seconds
        self.fps = fps
        self.amount = amount
        self.leaks = leaks
        self.particles = particles
        self.grain = grain
        self.seed = seed
        self.depthModel = depthModel
        self.fillModel = fillModel
    }

    /// Frames in the loop.
    public var frameCount: Int { max(2, Int((seconds * Double(fps)).rounded())) }
}

public enum MotionKind: String, DesignChoice {
    /// A slow push in and back out.
    case zoom
    /// A slow figure-of-eight drift.
    case drift
    /// 2.5D: the nearer part of the art (by its depth) moves more than the rest; what it uncovers is filled.
    case parallax
}
