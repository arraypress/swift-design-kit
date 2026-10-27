//
//  MachineDepth.swift
//  DesignKitAI
//
//  Created by David Sherlock on 2026.
//
//  Depth for a parallax loop, on this machine: Depth Anything V2 Small
//  (Apache-2.0, on Core AI, the export `img depth` installs). It loads once
//  and is asked once per loop.
//

import CoreGraphics
import DepthEstimator
import DesignKit
import Foundation

/// Depth Anything V2 Small on this machine, behind the engine's `DepthEstimating`.
public actor MachineDepth: DepthEstimating {

    /// The model, as a parallax loop pins it.
    public nonisolated let pin = "depth-anything-v2-small (arraypress/img-depth-anything)"
    private let modelURL: URL
    private var estimator: DepthEstimator?

    /// The depth model at `modelURL`, loaded on first use.
    public init(modelURL: URL) { self.modelURL = modelURL }

    /// Relative nearness for every pixel of `image`, `0…1` (1 nearest), at the picture's own size.
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
