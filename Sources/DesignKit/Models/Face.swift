//
//  Face.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A face: a family and the weight it is set in.
public struct Face: Codable, Equatable, Sendable {
    /// An installed family, a bundled one (`inter`), or an open font by name
    /// (`Playfair Display`, fetched on first use).
    public var family: String
    /// One of the text weights (`regular` … `black`).
    public var weight: String

    /// `family` at `weight`.
    public init(family: String, weight: String = "regular") {
        self.family = family
        self.weight = weight
    }
}
