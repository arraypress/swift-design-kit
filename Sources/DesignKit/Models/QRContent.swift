//
//  QRContent.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A QR code — a link or text — for a flyer.
public struct QRContent: Equatable, Sendable {
    /// What the code holds: a link or text.
    public var text: String
    /// The modules' colour.
    public var color: DesignColor
    /// The colour behind them.
    public var background: DesignColor
    /// How much of the code may be lost and still read.
    public var level: QRLevel

    /// A code for `text`.
    public init(text: String, color: DesignColor = .black, background: DesignColor = .white, level: QRLevel = .medium) {
        self.text = text
        self.color = color
        self.background = background
        self.level = level
    }
}
