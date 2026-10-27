//
//  MachineInpainter.swift
//  DesignKitAI
//
//  Created by David Sherlock on 2026.
//
//  Fill for a parallax loop, on this machine: LaMa (big-lama, Apache-2.0,
//  the package `img erase` installs). It loads once and is asked once per
//  loop.
//

import CoreGraphics
import DesignKit
import Foundation
import Inpaint

/// LaMa on this machine, behind the engine's `Inpainting`.
public actor MachineInpainter: Inpainting {

    /// The model and its commit, as a parallax loop pins them.
    public nonisolated let pin = "big-lama@ef3cdb380b3978f25ec5371b42c0dbbb2f4e5fed (arraypress/erase-lama)"
    private let modelURL: URL
    private var inpainter: LaMaInpainter?

    /// The fill model at `modelURL`, loaded on first use.
    public init(modelURL: URL) { self.modelURL = modelURL }

    /// `image` with what `mask` marks (white) filled from its surroundings.
    public func filled(_ image: CGImage, mask: CGImage) async throws(DesignError) -> CGImage {
        do {
            let model: LaMaInpainter
            if let inpainter { model = inpainter } else {
                model = try LaMaInpainter(modelURL: modelURL)
                inpainter = model
            }
            return try model.erase(image, mask: mask, feather: 4)
        } catch {
            throw .failed("the uncovered part could not be filled: \(error)")
        }
    }
}
