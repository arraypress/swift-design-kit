//
//  Decoding.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Numbers as a refusal writes them back: whole numbers without a point.
//

import Foundation

enum Decoding {
    /// `3` for 3.0, `0.25` otherwise.
    static func text(_ value: Double) -> String {
        value == value.rounded() && abs(value) < 1e15 ? String(Int(value)) : String(value)
    }
}
