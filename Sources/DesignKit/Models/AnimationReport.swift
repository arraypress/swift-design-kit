//
//  AnimationReport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a loop measured.
public struct AnimationReport: Codable, Equatable, Sendable {
    /// The MP4 written.
    public var file: String
    /// The video's width, in pixels.
    public var width: Int
    /// The video's height, in pixels.
    public var height: Int
    /// How many frames make one loop.
    public var frames: Int
    /// The loop's length.
    public var seconds: Double
    /// Frames a second.
    public var fps: Int
    /// The motion as made (with the models a parallax used).
    public var motion: MotionSpec
    /// The last frame against the first, over the typical step between frames: about 1 is seamless.
    public var seam: Double
    /// Each text layer's lowest contrast over all frames.
    public var lowestContrast: [String: Double]
    /// Each text layer's lowest read-back over three frames.
    public var readBack: [String: Double]
    /// For a parallax: its planes and whether the subject stayed whole.
    public var parallax: ParallaxReport?
    /// What the checks found on the loop, failures first.
    public var findings: [Finding]
    /// No failures (warnings allowed).
    public var passed: Bool { !findings.contains { $0.level == .fail } }
}
