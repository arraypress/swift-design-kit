//
//  LookReference.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import VideoGradeLook

/// A look: inline (as a recipe holds it) or a file to read when the design is made.
public enum LookReference: Equatable, Sendable {
    /// A look file, by path, read when the design is made.
    case file(String)
    /// The look itself.
    case look(GradeLook)
}
