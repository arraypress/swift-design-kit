//
//  MaskShape.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The outline a picture is clipped to.
public enum MaskShape: String, DesignChoice {
    /// The frame's own rectangle.
    case rect
    /// The frame with round corners (`radius`).
    case rounded
    /// The ellipse inscribed in the frame.
    case circle
    /// The corners given in `points`.
    case polygon
}
