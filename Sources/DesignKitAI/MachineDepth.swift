//
//  MachineDepth.swift
//  DesignKitAI
//
//  Created by David Sherlock on 2026.
//
//  Depth and fill for a parallax loop, on this machine: Depth Anything V2
//  Small (Apache-2.0, on Core AI, the export `img depth` installs) and LaMa
//  (big-lama, Apache-2.0, the package `img erase` installs). Both load once
//  and are asked once per loop.
//

import CoreGraphics
import DepthEstimator
import DesignKit
import Foundation
import Inpaint

public actor MachineDepth: DepthEstimating {

    public nonisolated let pin = "depth-anything-v2-small (arraypress/img-depth-anything)"
    private let modelURL: URL
    private var estimator: DepthEstimator?

    public init(modelURL: URL) { self.modelURL = modelURL }

    public func nearness(of image: CGImage) async throws(DesignError) -> [Float] {
        do {
            let model: DepthEstimator
            if let estimator { model = estimator } else {
                model = try await DepthEstimator(contentsOf: modelURL)
                estimator = model
            }
            let (map, _) = try await model.depth(of: image)
            let values = map.normalised()
            // The map at the model's size, resampled to the picture's.
            if map.width == image.width, map.height == image.height { return values }
            return Resample.bilinearAlignCorners(values, width: map.width, height: map.height, toWidth: image.width, toHeight: image.height)
        } catch let error as DesignError {
            throw error
        } catch {
            throw .failed("the depth could not be found: \(error)")
        }
    }
}

public actor MachineInpainter: Inpainting {

    public nonisolated let pin = "big-lama@ef3cdb380b3978f25ec5371b42c0dbbb2f4e5fed (arraypress/erase-lama)"
    private let modelURL: URL
    private var inpainter: LaMaInpainter?

    public init(modelURL: URL) { self.modelURL = modelURL }

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
