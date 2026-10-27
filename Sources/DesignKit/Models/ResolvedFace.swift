//
//  ResolvedFace.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a text layer is set in, resolved: roles through the pairing, named
/// sizes through the type scale.
struct ResolvedFace: Sendable, Equatable {
    /// `nil`: the system face.
    let family: String?
    let weight: String
    /// Design units.
    let size: Double
}
