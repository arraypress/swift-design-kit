//
//  LookReference+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension LookReference: Codable {

    /// A path to a look file, or the look itself, read strictly.
    public init(from decoder: any Decoder) throws {
        if let path = try? decoder.singleValueContainer().decode(String.self) {
            self = .file(path)
        } else {
            self = .look(try GradeLookCoding.decode(from: decoder))
        }
    }

    /// Writes the path, or the look inline.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .file(let path): try c.encode(path)
        case .look(let look): try c.encode(look)
        }
    }
}
