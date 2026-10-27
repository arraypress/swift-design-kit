//
//  MotionSpec+Codable.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension MotionSpec: Codable {

    enum CodingKeys: String, CodingKey, CaseIterable {
        case kind, seconds, fps, amount, leaks, particles, grain, seed
        case depthModel = "depth_model"
        case fillModel = "fill_model"
        case subjectModel = "subject_model"
    }

    /// An object, or a kind alone (`"motion": "parallax"`).
    public init(from decoder: any Decoder) throws {
        if let word = try? decoder.singleValueContainer().decode(String.self) {
            guard let kind = MotionKind(rawValue: word.lowercased()) else {
                throw RecipeError(Choices.refusal(word, at: RecipeJSON.path(decoder.codingPath), among: MotionKind.allCases.map(\.rawValue)))
            }
            self.init(kind: kind)
            return
        }
        try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fps = try c.value(.fps, or: 30)
        guard [24, 25, 30, 60].contains(fps) else { throw RecipeError("motion.fps is \(fps); it takes 24, 25, 30 or 60") }
        let particles = try c.value(.particles, or: 0)
        guard (0...400).contains(particles) else { throw RecipeError("motion.particles is \(particles); it takes 0…400") }
        self.init(kind: try c.value(.kind, or: .zoom), seconds: try c.number(.seconds, in: 3...8, or: 6), fps: fps,
                  amount: try c.number(.amount, in: 0.01...0.2, or: 0.06), leaks: try c.number(.leaks, in: 0...1, or: 0),
                  particles: particles, grain: try c.number(.grain, in: 0...1, or: 0.04), seed: try c.value(.seed, or: 1),
                  depthModel: try c.decodeIfPresent(String.self, forKey: .depthModel), fillModel: try c.decodeIfPresent(String.self, forKey: .fillModel),
                  subjectModel: try c.decodeIfPresent(String.self, forKey: .subjectModel))
    }

    /// Writes it as a design file holds it.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kind, forKey: .kind)
        try c.encode(seconds, forKey: .seconds)
        try c.encode(fps, forKey: .fps)
        try c.encode(amount, forKey: .amount)
        if leaks > 0 { try c.encode(leaks, forKey: .leaks) }
        if particles > 0 { try c.encode(particles, forKey: .particles) }
        try c.encode(grain, forKey: .grain)
        try c.encode(seed, forKey: .seed)
        try c.encodeIfPresent(depthModel, forKey: .depthModel)
        try c.encodeIfPresent(fillModel, forKey: .fillModel)
        try c.encodeIfPresent(subjectModel, forKey: .subjectModel)
    }
}
