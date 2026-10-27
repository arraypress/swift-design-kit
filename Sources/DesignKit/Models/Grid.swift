//
//  Grid.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The column grid `columns` spans count over.
public struct Grid: Equatable, Sendable {

    /// How many columns across the safe area.
    public var columns: Int

    /// The space between columns, as a fraction of the area's width.
    public var gutter: Double

    /// A grid of `columns` with `gutter` between them.
    public init(columns: Int = 12, gutter: Double = 0.02) {
        self.columns = columns
        self.gutter = gutter
    }

    /// Twelve columns, a 2% gutter.
    public static let standard = Grid()
}
