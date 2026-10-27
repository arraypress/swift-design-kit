//
//  Avoid.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a text layer keeps clear of.
public enum Avoid: String, DesignChoice {
    /// Faces found in what lies under the text.
    case faces
    /// Cut-out subjects (image layers with `cutout`).
    case subject
}
