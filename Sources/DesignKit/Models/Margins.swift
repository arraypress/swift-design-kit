//
//  Margins.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The space round all the words, as shares of the page.
public struct Margins: Codable, Equatable, Sendable {
    /// Left of the words, a share of the page's width.
    public var left: Double
    /// Right of the words, a share of the page's width.
    public var right: Double
    /// Above the words, a share of the page's height.
    public var top: Double
    /// Below the words, a share of the page's height.
    public var bottom: Double
    /// Side margins even enough for centred words.
    public var balanced: Bool
}
