//
//  TextCase.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How the words are cased when drawn.
public enum TextCase: String, DesignChoice {
    /// As written.
    case none
    /// ALL CAPITALS.
    case upper
    /// all lowercase.
    case lower
    /// Each Word Capitalised.
    case title
}
