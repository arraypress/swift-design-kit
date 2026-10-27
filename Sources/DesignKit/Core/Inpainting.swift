//
//  Inpainting.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// Fills in part of a picture.
public protocol Inpainting: Sendable {
    /// The model and its revision, as a recipe records them.
    var pin: String { get }
    /// `image` with what `mask` marks (white) filled from its surroundings.
    func filled(_ image: CGImage, mask: CGImage) async throws(DesignError) -> CGImage
}
