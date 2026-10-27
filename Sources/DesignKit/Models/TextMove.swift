//
//  TextMove.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Where `avoid` put a text layer instead of where it was declared: another
/// anchor (the alignment that hugged the old one follows it), and a frame
/// narrowed to a share of its width when only that clears.
public struct TextMove: Codable, Equatable, Sendable {
    /// The anchor it moved to.
    public var anchor: Anchor
    /// The share of the declared frame's width (`1`: unchanged).
    public var width: Double
    /// The alignment it takes there.
    public var align: TextAlign
    /// The vertical alignment it takes there.
    public var valign: VerticalAlign
}
