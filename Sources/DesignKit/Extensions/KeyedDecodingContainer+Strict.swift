//
//  KeyedDecodingContainer+Strict.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The strict reading every design type shares: unknown keys refused with
//  the close one, a value out of its range refused with the range, and a
//  default for a key left out.
//

import Foundation
import RecipeKit

extension KeyedDecodingContainer {

    /// The value at `key`, or `fallback` when the key is absent or null.
    func value<T: Decodable>(_ key: Key, or fallback: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? fallback
    }

    /// A number at `key` that must lie in `range`, or `fallback`.
    func number(_ key: Key, in range: ClosedRange<Double>, or fallback: Double) throws -> Double {
        guard let value = try decodeIfPresent(Double.self, forKey: key) else { return fallback }
        guard value.isFinite, range.contains(value) else {
            throw RecipeError("\(RecipeJSON.path(codingPath + [key])) is \(Decoding.text(value)); it takes \(Decoding.text(range.lowerBound))…\(Decoding.text(range.upperBound))")
        }
        return value
    }

    /// An optional number at `key` that must lie in `range`.
    func number(_ key: Key, in range: ClosedRange<Double>) throws -> Double? {
        guard try decodeIfPresent(Double.self, forKey: key) != nil else { return nil }
        return try number(key, in: range, or: 0)
    }
}
