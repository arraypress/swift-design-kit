//
//  SourceNote.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Where a picture came from and how it fits its frame.
public struct SourceNote: Codable, Equatable, Sendable {
    /// The layer's path and id.
    public var layer: String
    /// The layer's id, when it has one.
    public var id: String?
    /// `file`, `cutout`, `ai`, `gradient`, `color`.
    public var kind: String
    /// The picture's own size before enlarging, in pixels.
    public var sourceWidth: Int
    /// The picture's own height before enlarging, in pixels.
    public var sourceHeight: Int
    /// How many times larger than its own pixels it is drawn, before and after enlarging on this machine.
    public var enlargement: Double
    /// How many times larger than its own pixels it is drawn after enlarging.
    public var enlargementAfter: Double
    /// Whether it was enlarged on this machine.
    public var upscaled: Bool
    /// The upscaler that did it (`swinir@<revision>`).
    public var upscaledWith: String? = nil
    /// The upscaler the recipe was made with, when another enlarged it this time.
    public var upscaledWithWas: String? = nil
}
