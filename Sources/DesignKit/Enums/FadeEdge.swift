//
//  FadeEdge.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Where a fade goes.
public enum FadeEdge: String, DesignChoice {
    /// Toward that edge.
    case top, bottom, left, right
    /// From the middle out to the corners.
    case radial
}
