//
//  Pairings.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Type pairings as data: a display face and a text face that belong
//  together, and the scale they are set at. Each role lists candidates —
//  faces macOS ships first, then the bundled ones, then open fonts fetched
//  on first use — so a pairing is set in what this Mac has before anything
//  is downloaded. A design names a pairing; text layers name the roles.
//

import Foundation
import RecipeKit

/// The catalogue of type pairings: a display face and a text face that belong together.
public enum Pairings {

    /// Every pairing.
    public static let all: [Pairing] = {
        do { return try JSONDecoder().decode([Pairing].self, from: Data(catalogue.utf8)) } catch {
            preconditionFailure("the pairing catalogue does not read: \(error)")
        }
    }()

    /// The pairing a design gets when its words name roles and it names no pairing.
    public static let fallback = "modern"

    /// The pairing called `name`.
    public static func named(_ name: String) -> Pairing? { all.first { $0.name == name.lowercased() } }

    /// The refusal for an unknown pairing.
    static func refusal(_ name: String, at field: String) -> String {
        Choices.refusal(name, at: field, among: all.map(\.name))
    }

    /// The first candidate for a role that is here or can be fetched.
    static func pick(_ candidates: [Face], fetchable: Bool, fetched: (OpenFont) -> Bool) -> Face? {
        candidates.first { face in
            Fonts.isLocal(face.family) || OpenFonts.named(face.family).map { fetchable || fetched($0) } ?? false
        }
    }

    /// Each pairing's display → text candidates, with installed (macOS) faces first.
    static let catalogue = #"""
    [
      {"name": "modern", "summary": "Avenir Next throughout: geometric, friendly, clear at every size",
       "mood": ["clean", "friendly"], "scale": 1.5, "base": 30,
       "display": [{"family": "Avenir Next", "weight": "bold"}, {"family": "inter", "weight": "bold"}],
       "text": [{"family": "Avenir Next", "weight": "medium"}, {"family": "inter", "weight": "medium"}]},
      {"name": "editorial", "summary": "A high-contrast Didone for titles over a quiet geometric sans: the magazine cover",
       "mood": ["elegant", "fashion", "editorial"], "scale": 1.618, "base": 28,
       "display": [{"family": "Didot", "weight": "regular"}, {"family": "Playfair Display", "weight": "regular"}, {"family": "Bodoni Moda", "weight": "regular"}],
       "text": [{"family": "Avenir Next", "weight": "medium"}, {"family": "DM Sans", "weight": "medium"}, {"family": "inter", "weight": "medium"}]},
      {"name": "literary", "summary": "Book serifs both ways: a Caslon title over Baskerville, warm and bookish",
       "mood": ["classic", "warm", "literary"], "scale": 1.5, "base": 30,
       "display": [{"family": "Big Caslon", "weight": "medium"}, {"family": "Cormorant Garamond", "weight": "semibold"}],
       "text": [{"family": "Baskerville", "weight": "regular"}, {"family": "EB Garamond", "weight": "regular"}, {"family": "source-serif", "weight": "regular"}]},
      {"name": "swiss", "summary": "Helvetica Neue, tight and heavy for titles, plain for the rest: the International Style",
       "mood": ["neutral", "graphic", "modernist"], "scale": 1.414, "base": 30,
       "display": [{"family": "Helvetica Neue", "weight": "bold"}, {"family": "inter", "weight": "bold"}],
       "text": [{"family": "Helvetica Neue", "weight": "regular"}, {"family": "inter", "weight": "regular"}]},
      {"name": "geometric", "summary": "Futura titles over Avenir Next: Bauhaus circles and straight lines",
       "mood": ["modernist", "confident"], "scale": 1.5, "base": 30,
       "display": [{"family": "Futura", "weight": "bold"}, {"family": "Space Grotesk", "weight": "bold"}],
       "text": [{"family": "Avenir Next", "weight": "regular"}, {"family": "Manrope", "weight": "regular"}, {"family": "inter", "weight": "regular"}]},
      {"name": "condensed", "summary": "A tall condensed sans in capitals over a plain sans: posters, sport, gig bills",
       "mood": ["loud", "urgent", "compact"], "scale": 1.618, "base": 30,
       "display": [{"family": "Bebas Neue", "weight": "regular"}, {"family": "DIN Condensed", "weight": "bold"}, {"family": "Oswald", "weight": "bold"}],
       "text": [{"family": "Avenir Next", "weight": "medium"}, {"family": "inter", "weight": "medium"}]},
      {"name": "poster", "summary": "Anton or a heavy grotesque at full width over Helvetica: the loudest bill on the wall",
       "mood": ["loud", "bold"], "scale": 1.75, "base": 30,
       "display": [{"family": "Anton", "weight": "regular"}, {"family": "Archivo Black", "weight": "regular"}, {"family": "Helvetica Neue", "weight": "bold"}],
       "text": [{"family": "Helvetica Neue", "weight": "medium"}, {"family": "inter", "weight": "medium"}]},
      {"name": "retro", "summary": "A fat, friendly seventies display over a typewriter face",
       "mood": ["retro", "warm", "playful"], "scale": 1.5, "base": 30,
       "display": [{"family": "Shrikhand", "weight": "regular"}, {"family": "Cooper Black", "weight": "regular"}, {"family": "American Typewriter", "weight": "bold"}],
       "text": [{"family": "American Typewriter", "weight": "regular"}, {"family": "Space Mono", "weight": "regular"}]},
      {"name": "brutalist", "summary": "A black grotesque over a monospace: raw, gridded, technical",
       "mood": ["raw", "technical", "brutalist"], "scale": 1.618, "base": 28,
       "display": [{"family": "Archivo Black", "weight": "regular"}, {"family": "Helvetica Neue", "weight": "bold"}],
       "text": [{"family": "Space Mono", "weight": "regular"}, {"family": "Menlo", "weight": "regular"}, {"family": "jetbrains-mono", "weight": "regular"}]},
      {"name": "cinema", "summary": "Widely spaced Futura capitals and a light sans: film titles and credits",
       "mood": ["cinematic", "quiet", "spacious"], "scale": 1.414, "base": 26,
       "display": [{"family": "Futura", "weight": "medium"}, {"family": "Gill Sans", "weight": "light"}, {"family": "Syne", "weight": "regular"}],
       "text": [{"family": "Avenir Next", "weight": "regular"}, {"family": "inter", "weight": "regular"}]},
      {"name": "soft-serif", "summary": "A soft, wonky modern serif over a round sans: warm, contemporary, a little playful",
       "mood": ["warm", "contemporary"], "scale": 1.5, "base": 30,
       "display": [{"family": "Fraunces", "weight": "semibold"}, {"family": "Cochin", "weight": "bold"}],
       "text": [{"family": "DM Sans", "weight": "regular"}, {"family": "Avenir Next", "weight": "regular"}]},
      {"name": "fashion", "summary": "Bodoni at a whisper with Futura in wide capitals: luxury, perfume, the gallery",
       "mood": ["luxury", "elegant", "minimal"], "scale": 1.618, "base": 26,
       "display": [{"family": "Bodoni 72", "weight": "regular"}, {"family": "Bodoni Moda", "weight": "regular"}],
       "text": [{"family": "Futura", "weight": "medium"}, {"family": "Avenir Next", "weight": "medium"}]},
      {"name": "technical", "summary": "Monospace throughout: code, data, release notes, the terminal",
       "mood": ["technical", "precise"], "scale": 1.333, "base": 30,
       "display": [{"family": "jetbrains-mono", "weight": "bold"}, {"family": "Menlo", "weight": "bold"}],
       "text": [{"family": "jetbrains-mono", "weight": "regular"}, {"family": "Menlo", "weight": "regular"}]}
    ]
    """#
}
