//
//  ListItems.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A list's items: written out, or text to split once its slots are filled.
public enum ListItems: Equatable, Sendable {
    /// Written out, one by one.
    case items([ListItem])
    /// Text split into items once its slots are filled.
    case text(String)
}
