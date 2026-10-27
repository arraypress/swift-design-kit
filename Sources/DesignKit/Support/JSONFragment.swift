//
//  JSONFragment.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// JSON carried through an encoder unchanged.
struct JSONFragment: Codable {
    let value: Any

    init(from decoder: any Decoder) throws { value = try AnyJSON(from: decoder).value }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as NSNull: _ = v; try c.encodeNil()
        case let v as Bool: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [Any]: try c.encode(v.map { JSONFragment(raw: $0) })
        case let v as [String: Any]: try c.encode(v.mapValues { JSONFragment(raw: $0) })
        default: try c.encodeNil()
        }
    }

    init(raw: Any) { value = raw }
}
