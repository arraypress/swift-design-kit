//
//  DepthEstimating.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// Finds how near each part of a picture is.
public protocol DepthEstimating: Sendable {
    /// The model and its revision, as a recipe records them.
    var pin: String { get }
    /// Relative nearness for every pixel of `image`, `0…1` (1 nearest), row by row from the top.
    func nearness(of image: CGImage) async throws(DesignError) -> [Float]
}
