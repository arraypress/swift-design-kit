//
//  PreparedPicture.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// One prepared picture.
struct PreparedPicture: Sendable {
    var image: CGImage
    /// A sticker outline behind a cut-out: the lifted subject grown by the
    /// stroke and filled, `pad` source pixels larger on every side.
    var outline: CGImage?
    var pad: Double = 0
}
