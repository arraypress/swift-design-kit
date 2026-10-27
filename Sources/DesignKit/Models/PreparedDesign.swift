//
//  PreparedDesign.swift
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
    /// The page in pixels.
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
