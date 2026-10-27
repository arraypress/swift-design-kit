//
//  ListItem.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One name, title or credit.
public struct ListItem: Equatable, Sendable {
    /// The name, title or credit.
    public var text: String
    /// Billing, from 1 (the top).
    public var tier: Int
    /// What sits beside it on its line (a running time), for `lines`.
    public var detail: String?

    /// An item at `tier`.
    public init(text: String, tier: Int = 1, detail: String? = nil) {
        self.text = text
        self.tier = tier
        self.detail = detail
    }
}
