//
//  AnyJSON.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Any JSON value, as Foundation objects — for handing a section to a strict reader.
struct AnyJSON: Decodable {
    let value: Any

    init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = NSNull() }
        else if let v = try? c.decode(Bool.self) { value = v }
        else if let v = try? c.decode(Double.self) { value = v }
        else if let v = try? c.decode(String.self) { value = v }
        else if let v = try? c.decode([AnyJSON].self) { value = v.map(\.value) }
        else { value = try c.decode([String: AnyJSON].self).mapValues(\.value) }
    }
}
