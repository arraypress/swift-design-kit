//
//  ArtLook.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation

/// The art under a text layer, looked at once: faces (measuring pixels,
/// top-left) and the lifted subject — kept so the checks measure against
/// what placement avoided.
struct ArtLook: Sendable {
    var faces: [CGRect]?
    var subject: Subjects.Search?
}
