//
//  Layer.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One thing drawn, in order: the first layer is at the back.
///
/// Every layer has a frame (by rule), an opacity, a blend mode, a rotation
/// about its frame's centre, and an optional shadow and glow cast by all of
/// it. What it draws is its ``Content``. In a file the kind is `type` and the
/// kind's own keys sit beside the common ones.
public struct Layer: Equatable, Sendable {

    /// A name other layers and `--set` refer to it by (`title`, `background`).
    public var id: String?
    public var frame: Placement
    /// `0…1`.
    public var opacity: Double
    public var blend: BlendMode
    /// Degrees, clockwise.
    public var rotation: Double
    public var shadow: Shadow?
    public var glow: Glow?
    public var content: Content

    /// What a layer draws.
    public enum Content: Equatable, Sendable {
        case background(BackgroundContent)
        case text(TextContent)
        case image(ImageContent)
        case shape(ShapeContent)
        case qr(QRContent)
        /// Layers drawn together — placed inside the group's frame, then
        /// faded, blended and turned as one.
        case group([Layer])
    }

    public init(id: String? = nil, frame: Placement = .full, opacity: Double = 1, blend: BlendMode = .normal,
                rotation: Double = 0, shadow: Shadow? = nil, glow: Glow? = nil, content: Content) {
        self.id = id
        self.frame = frame
        self.opacity = opacity
        self.blend = blend
        self.rotation = rotation
        self.shadow = shadow
        self.glow = glow
        self.content = content
    }
}
