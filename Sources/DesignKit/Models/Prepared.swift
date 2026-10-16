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
    var pictures: [String: PreparedPicture]
    /// The face, weight and size each text layer draws in.
    let faces: [String: ResolvedFace]
    /// Where each picture came from and how far it is enlarged.
    public let sources: [SourceNote]
    /// The google/fonts commit the recipe was made at, when this build fetches from another.
    public var fontCommitWas: String? = nil
}

extension PreparedDesign {
    /// The same design with every prepared picture (and sticker outline) passed through `transform`.
    func withPictures(_ transform: (CGImage) -> CGImage?) -> PreparedDesign {
        var copy = self
        copy.pictures = pictures.mapValues { picture in
            var changed = picture
            changed.image = transform(picture.image) ?? picture.image
            changed.outline = picture.outline.map { transform($0) ?? $0 }
            return changed
        }
        return copy
    }
}

/// What a text layer is set in, resolved: roles through the pairing, named
/// sizes through the type scale.
struct ResolvedFace: Sendable, Equatable {
    /// `nil`: the system face.
    let family: String?
    let weight: String
    /// Design units.
    let size: Double
}

/// One prepared picture.
struct PreparedPicture: Sendable {
    var image: CGImage
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
    /// The upscaler that did it (`swinir@<revision>`).
    public var upscaledWith: String? = nil
    /// The upscaler the recipe was made with, when another enlarged it this time.
    public var upscaledWithWas: String? = nil
}

/// Where each layer went and what was decided about it as it was drawn.
public struct Plan: Sendable {
    /// Frames, pixels, origin top-left.
    public var frames: [String: CGRect]
    /// Each text layer's laid-out lines (CoreGraphics space of the full bitmap).
    public var fits: [String: TextFit]
    /// Each text layer's ink colour and plate colour, as decided.
    public var text: [String: TextDecision]
    /// The art under text layers, keyed by which art layers it is.
    var art: [String: ArtLook] = [:]
    /// The palette roles, from the art.
    public var palette: PaletteRoles?

    /// The colour `paint` stands for: a colour, a role from the palette;
    /// `nil` for `auto` (decided per layer) or a role with no palette.
    func color(_ paint: Paint?) -> DesignColor? {
        switch paint {
        case .color(let color)?: color
        case .role(let role)?: palette?[role]
        case .auto?, nil: nil
        }
    }
}

/// What was decided for one text layer.
public struct TextDecision: Codable, Equatable, Sendable {
    public var color: DesignColor
    /// The plate's colour, when one is drawn.
    public var plate: DesignColor?
    /// Where `avoid` moved the words, when it did.
    public var move: TextMove?
    /// Why it moved, or how much of what it avoids it still covers.
    public var note: String?
}

/// Where `avoid` put a text layer instead of where it was declared: another
/// anchor (the alignment that hugged the old one follows it), and a frame
/// narrowed to a share of its width when only that clears.
public struct TextMove: Codable, Equatable, Sendable {
    public var anchor: Anchor
    /// The share of the declared frame's width (`1`: unchanged).
    public var width: Double
    public var align: TextAlign
    public var valign: VerticalAlign
}

/// The art under a text layer, looked at once: faces (measuring pixels,
/// top-left) and the lifted subject — kept so the checks measure against
/// what placement avoided.
struct ArtLook: Sendable {
    var faces: [CGRect]?
    var subject: Subjects.Search?
}
