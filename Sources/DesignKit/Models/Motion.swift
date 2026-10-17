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
    /// For `parallax`: the depth, fill and subject models that ran, written when made.
    public var depthModel: String?
    public var fillModel: String?
    public var subjectModel: String?

    public init(kind: MotionKind = .zoom, seconds: Double = 6, fps: Int = 30, amount: Double = 0.06, leaks: Double = 0,
                particles: Int = 0, grain: Double = 0.04, seed: UInt64 = 1, depthModel: String? = nil, fillModel: String? = nil,
                subjectModel: String? = nil) {
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
        self.subjectModel = subjectModel
    }

    /// Frames in the loop.
    public var frameCount: Int { max(2, Int((seconds * Double(fps)).rounded())) }
}

public enum MotionKind: String, DesignChoice {
    /// A slow push in and back out.
    case zoom
    /// A slow figure-of-eight drift.
    case drift
    /// 2.5D in rigid layers: the subject cut out whole and moving most, the
    /// background behind it filled and split by depth into 2–3 planes that
    /// move less the further they are.
    case parallax
}

/// What a layered parallax measured.
public struct ParallaxReport: Codable, Equatable, Sendable {
    /// Background planes the depth was split into (1–3).
    public var planes: Int
    /// Whether a subject was found and moved as one layer.
    public var subject: Bool
    /// The lowest share, over every frame, of the subject's silhouette (its
    /// mask moved by its one transform) that shows the subject: 1 is whole.
    public var integrity: Double?
    /// The most pixels on any frame deep inside the silhouette showing something else.
    public var leaked: Int?
    /// The subject cut again from three rendered frames against its moved mask (intersection over union).
    public var recut: Double?
    /// The furthest, in pixels, the subject slides against the far plane: what the fill behind it covers.
    public var reveal: Double
    /// Whether the move was cut down so the fill behind the subject stays small.
    public var limited: Bool

    public init(planes: Int, subject: Bool, integrity: Double? = nil, leaked: Int? = nil, recut: Double? = nil, reveal: Double,
                limited: Bool) {
        self.planes = planes
        self.subject = subject
        self.integrity = integrity
        self.leaked = leaked
        self.recut = recut
        self.reveal = reveal
        self.limited = limited
    }
}
