//
//  StrokeStyle.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a text stroke does.
public enum StrokeStyle: String, DesignChoice {
    /// Filled letters with a keyline round them — the legibility treatment.
    case outline
    /// The outline only — the display treatment.
    case hollow
}
