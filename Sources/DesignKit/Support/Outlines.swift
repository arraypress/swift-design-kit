//
//  Outlines.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The sticker outline behind a cut-out: its alpha grown by the stroke's
//  width and filled with the stroke's colour, drawn under the subject.
//

import CoreGraphics
import CoreImage
import Foundation

enum Outlines {

    /// `image`'s silhouette grown by `radius` pixels and filled with `color`,
    /// on a canvas `radius` larger on every side.
    static func outline(of image: CGImage, radius: Double, color: DesignColor) -> CGImage? {
        let pad = radius.rounded(.up)
        guard pad >= 1 else { return nil }
        let input = CIImage(cgImage: image)
        let extent = input.extent.insetBy(dx: -pad, dy: -pad)
        let alpha = input.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0), "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
        ])
        let grown = alpha.clampedToExtent().cropped(to: input.extent)
            .composited(over: CIImage(color: .clear).cropped(to: extent))
            .applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: radius])
            .cropped(to: extent)
        let parts = color.components
        let filled = CIImage(color: CIColor(red: parts.red, green: parts.green, blue: parts.blue, alpha: 1))
            .cropped(to: extent)
            .applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: extent),
                kCIInputMaskImageKey: grown,
            ])
        return Bitmaps.render(filled, extent: extent)
    }
}
