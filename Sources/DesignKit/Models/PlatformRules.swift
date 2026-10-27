//
//  PlatformRules.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a destination requires of a picture, checked on every make.
public struct PlatformRules: Equatable, Sendable, Codable {
    /// The smallest it takes, in pixels.
    public var minimumWidth: Int?
    /// The shortest it takes, in pixels.
    public var minimumHeight: Int?
    /// The largest it takes, in pixels.
    public var maximumWidth: Int?
    /// The tallest it takes, in pixels.
    public var maximumHeight: Int?
    /// Must be exactly square.
    public var square: Bool
    /// Must carry bleed (print).
    public var needsBleed: Bool

    /// Rules; none are set unless given.
    public init(minimumWidth: Int? = nil, minimumHeight: Int? = nil, maximumWidth: Int? = nil,
                maximumHeight: Int? = nil, square: Bool = false, needsBleed: Bool = false) {
        self.minimumWidth = minimumWidth
        self.minimumHeight = minimumHeight
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
        self.square = square
        self.needsBleed = needsBleed
    }
}
