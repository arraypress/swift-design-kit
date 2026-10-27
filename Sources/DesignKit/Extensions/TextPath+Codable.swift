//
//  TextPath+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension TextPath: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable { case shape, bend, start, waves, amplitude }

    /// An object, or a shape's name alone (`"path": "circle"`).
    public init(from decoder: any Decoder) throws {
        if let word = try? decoder.singleValueContainer().decode(String.self) {
            guard let shape = TextPathShape(rawValue: word.lowercased()) else {
                throw RecipeError(Choices.refusal(word, at: RecipeJSON.path(decoder.codingPath), among: TextPathShape.allCases.map(\.rawValue)))
            }
            self.init(shape: shape)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(shape: try c.decode(TextPathShape.self, forKey: .shape), bend: try c.number(.bend, in: -1...1, or: 0.5),
                  start: try c.number(.start, in: -360...360, or: 0), waves: try c.number(.waves, in: 0.25...12, or: 1.5),
                  amplitude: try c.number(.amplitude, in: 0...1, or: 0.25))
        if shape == .arc, bend == 0 { throw RecipeError("\(RecipeJSON.path(decoder.codingPath)).bend is 0, a straight line; leave out path, or bend it") }
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(shape, forKey: .shape)
        switch shape {
        case .arc: try c.encode(bend, forKey: .bend)
        case .circle: try c.encode(start, forKey: .start)
        case .wave:
            try c.encode(waves, forKey: .waves)
            try c.encode(amplitude, forKey: .amplitude)
        }
    }
}
