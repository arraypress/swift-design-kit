//
//  FillShorthand.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A background said in one string — what `--var background=…` and a
//  template's `"fill": "{background}"` carry:
//
//      #1B2A4A                                 a colour
//      linear:#FF9A8B,#FF6A88,angle=160        a straight blend
//      radial:#FDE68A,#B45309                  a blend from the centre
//      gradient:seed=42,palette=lagoon,motif=flow   a GradientKit wallpaper
//      imagine:neon city at night, rain        a picture made from words
//      image:cover.jpg  (or just cover.jpg)    a picture file
//

import Foundation
import RecipeKit

enum FillShorthand {

    static let example = "#1B2A4A, linear:#FF9A8B,#FF6A88, gradient:seed=42, imagine:neon city at night, image:photo.jpg"

    /// The fill a string says, or a refusal naming the forms.
    static func parse(_ text: String, field: String) throws(RecipeError) -> Fill {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RecipeError("\(field) is empty; it takes \(example)") }
        if let color = DesignColor(trimmed), trimmed.hasPrefix("#") || ColorParsing.named[trimmed.lowercased()] != nil {
            return .color(color)
        }
        if trimmed.hasPrefix("#") { throw RecipeError("\(field) is \"\(trimmed)\", not a colour (#RRGGBB) — or one of \(example)") }
        let (kind, rest) = split(trimmed)
        switch kind {
        case "linear", "radial":
            var colors: [DesignColor] = []
            var angle = 180.0
            for part in rest.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
                if let value = part.lowercased().split(separator: "=", maxSplits: 1).last, part.lowercased().hasPrefix("angle=") {
                    guard let number = Double(value), number.isFinite else { throw RecipeError("\(field): angle is \(value), not a number") }
                    angle = number
                } else if let color = DesignColor(part) {
                    colors.append(color)
                } else {
                    throw RecipeError("\(field): \"\(part)\" is not a colour")
                }
            }
            guard colors.count >= 2 else { throw RecipeError("\(field): a \(kind) blend takes two colours or more") }
            return kind == "linear" ? .linear(colors: colors, angle: angle) : .radial(colors: colors)
        case "gradient", "gradients":
            var spec = GradientFill(seed: 1)
            for part in rest.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) where !part.isEmpty {
                guard let pair = VarParsing.pair(part) else { throw RecipeError("\(field): \"\(part)\" is not name=value (seed, palette, motif)") }
                let name = pair.name.trimmingCharacters(in: .whitespaces).lowercased()
                let value = pair.value.trimmingCharacters(in: .whitespaces)
                switch name {
                case "seed":
                    guard let seed = UInt64(value) else { throw RecipeError("\(field): seed is \(value), not a whole number") }
                    spec.seed = seed
                case "palette": spec.palette = value.isEmpty ? nil : value
                case "motif": spec.motif = value.isEmpty ? nil : value
                default: throw RecipeError(Choices.refusal(name, at: "\(field) gradient", among: ["seed", "palette", "motif"]))
                }
            }
            return .gradient(spec)
        case "imagine", "ai":
            guard !rest.trimmingCharacters(in: .whitespaces).isEmpty else { throw RecipeError("\(field): imagine: takes the words to draw") }
            return .ai(AIFill(prompt: rest.trimmingCharacters(in: .whitespaces)))
        case "image", "file":
            return .image(path: rest.trimmingCharacters(in: .whitespaces))
        default:
            // A bare path is a picture file.
            return .image(path: trimmed)
        }
    }

    /// `imagine:words` → (`imagine`, `words`); no known kind → ("", text).
    static func split(_ text: String) -> (String, String) {
        guard let colon = text.firstIndex(of: ":") else { return ("", text) }
        let kind = text[..<colon].lowercased()
        guard ["linear", "radial", "gradient", "gradients", "imagine", "ai", "image", "file"].contains(kind) else { return ("", text) }
        return (kind, String(text[text.index(after: colon)...]))
    }
}
