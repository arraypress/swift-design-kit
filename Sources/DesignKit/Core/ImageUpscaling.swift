//
//  ImageUpscaling.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// Enlarges a picture.
public protocol ImageUpscaling: Sendable {

    /// How many times larger each side comes back.
    var factor: Int { get }

    /// The model and its pinned revision (`swinir@5f65a34…`), recorded in a recipe when it enlarges a picture.
    var pin: String { get }

    /// `image`, `factor` times larger.
    func upscale(_ image: CGImage) async throws(DesignError) -> CGImage
}
