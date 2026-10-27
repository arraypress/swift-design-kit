//
//  ParallaxReport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

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

    /// A report.
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
