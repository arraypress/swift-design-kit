//
//  Prepared.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A design with everything outside it fetched and made: pictures loaded,
//  lifted, enlarged and treated; made pictures drawn; fonts registered. What
//  is left is drawing, which is quick and the same every time.
//

import CanvasKit
import CoreGraphics
import Foundation

/// A design ready to draw. Layers are keyed by their path: `2` for the
/// third layer, `2.0` for the first inside it.
public struct PreparedDesign: Sendable {
    /// The design as made (made pictures pinned, looks inline).
    public let design: Design
    public let geometry: CanvasGeometry
    /// Pictures by layer: a background's finished plate (its frame's size),
    /// an image layer's picture (lifted when a cut-out), a QR code.
    let pictures: [String: PreparedPicture]
    /// The family each text layer draws in (`nil`: the system face).
    let families: [String: String]
    /// Where each picture came from and how far it is enlarged.
    public let sources: [SourceNote]
}

/// One prepared picture.
struct PreparedPicture: Sendable {
    let image: CGImage
    /// A sticker outline behind a cut-out: the lifted subject grown by the
    /// stroke and filled, `pad` source pixels larger on every side.
    var outline: CGImage?
    var pad: Double = 0
}

/// Where a picture came from and how it fits its frame.
public struct SourceNote: Codable, Equatable, Sendable {
    /// The layer's path and id.
    public var layer: String
    public var id: String?
    /// `file`, `cutout`, `ai`, `gradient`, `color`.
    public var kind: String
    /// The picture's own size before enlarging, in pixels.
    public var sourceWidth: Int
    public var sourceHeight: Int
    /// How many times larger than its own pixels it is drawn, before and after enlarging on this machine.
    public var enlargement: Double
    public var enlargementAfter: Double
    /// Whether it was enlarged on this machine.
    public var upscaled: Bool
}

/// Where each layer went and what was decided about it as it was drawn.
public struct Plan: Sendable {
    /// Frames, pixels, origin top-left.
    public var frames: [String: CGRect]
    /// Each text layer's laid-out lines (CoreGraphics space of the full bitmap).
    public var fits: [String: TextFit]
    /// Each text layer's ink colour and plate colour, as decided.
    public var text: [String: TextDecision]
}

/// What was decided for one text layer.
public struct TextDecision: Codable, Equatable, Sendable {
    public var color: DesignColor
    /// The plate's colour, when one is drawn.
    public var plate: DesignColor?
    /// The anchor used, when `avoid` moved the words from the one declared.
    public var movedTo: Anchor?
    /// Why it moved, or how much of what it avoids it still covers.
    public var note: String?
}
