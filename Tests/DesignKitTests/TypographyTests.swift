//
//  TypographyTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Google Fonts by name, faces from --var, variable axes, OpenType
//  features, letter styles, words along a path, extruded and inline letters.
//

import CoreGraphics
import CoreText
import Foundation
import Legibility
import RecipeKit
import Testing
@testable import DesignKit

struct TypographyTests {

    @Test func theGoogleIndexHoldsEveryFamilyPinned() throws {
        #expect(OpenFonts.all.count > 1900, "\(OpenFonts.all.count) families")
        #expect(Set(OpenFonts.all.map(\.licenceFolder)) == ["ofl", "apache", "ufl"])
        #expect(OpenFonts.all.allSatisfy { $0.files.allSatisfy { $0.sha256.count == 64 && $0.bytes > 0 } })
        let mono = try #require(OpenFonts.named("Space Mono"))
        #expect(mono.category == .mono && mono.licence == "OFL-1.1" && mono.styles.contains("Bold Italic"))
        let roboto = try #require(OpenFonts.named("roboto-slab"))
        #expect(roboto.licence == "Apache-2.0" && roboto.licenceFile?.name == "LICENSE.txt")
        #expect(roboto.axes.map(\.tag) == ["wght"] && roboto.styles.first?.hasPrefix("100–900") == true)
        #expect(roboto.url(of: roboto.files[0]).absoluteString
                    == "https://raw.githubusercontent.com/google/fonts/\(OpenFonts.commit)/apache/robotoslab/RobotoSlab%5Bwght%5D.ttf")
        #expect(OpenFonts.named("Ubuntu")?.licence == "UFL-1.0")
        // CoreText's name for a family whose files say otherwise.
        #expect(OpenFonts.named("Fjord One")?.drawnFamily == "Fjord")
        #expect(OpenFonts.search("garamond").contains { $0.family == "EB Garamond" })
        #expect(OpenFonts.search("Space Mono").first?.family == "Space Mono", "the exact name first")
        #expect(FontCatalog.google("space mono").first?.family == "Space Mono")
    }

    @Test func aFontVarSetsTheFacesAndRefusesAnUnknownOne() throws {
        let template = try #require(StarterTemplates.named("cover-clean"))
        let one = try Making.design(from: template, values: ["font": "Space Mono"])
        #expect(one.fonts?.display?.family == "Space Mono" && one.fonts?.text?.family == "Space Mono")
        #expect(one.vars["font"] == nil, "a face, not a slot")
        let display = try Making.design(from: template, values: ["display-font": "Georgia"])
        #expect(display.fonts?.display?.family == "Georgia" && display.fonts?.text == nil)
        #expect(throws: DesignError.self) { try Making.design(from: template, values: ["font": "Spase Mnoo"]) }
        let set = try Recipes.set("text-font=Menlo", in: one)
        #expect(set.fonts?.text?.family == "Menlo" && set.fonts?.display?.family == "Space Mono")
    }

    @Test func featureWordsAndAxisNamesReadAsTags() throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#000000"},
        {"type": "text", "id": "t", "text": "Small 1984", "font": "Avenir Next", "features": ["small-caps", "oldstyle", "-kern", "ss02"],
         "axes": {"weight": 700, "opsz": 30}}
        """##)
        guard case .text(let text) = design.layers[1].content else { Issue.record("no text"); return }
        #expect(text.features == ["smcp": 1, "onum": 1, "kern": 0, "ss02": 1])
        #expect(text.axes == ["wght": 700, "opsz": 30])
        // Written back as tags; read again the same.
        let again = try Recipes.decoded(Recipes.encoded(design))
        #expect(again == design)
        #expect(throws: RecipeError.self) { try Probe.square(##"{"type": "text", "text": "x", "features": ["fancy"]}"##) }
        #expect(throws: RecipeError.self) { try Probe.square(##"{"type": "text", "text": "x", "axes": {"heaviness": 2}}"##) }
        #expect(throws: RecipeError.self) {
            try Probe.square(##"{"type": "text", "text": "x", "letters": [{"word": 1, "match": "x", "color": "#FF0000"}]}"##)
        }
    }

    @Test func aFeatureTheFaceLacksIsFoundByMeasuring() {
        let font = FontResolver_font("Avenir Next", 40)
        #expect(TypeFeatures.ineffective(["smcp": 1], text: "small", font: font).isEmpty)
        #expect(TypeFeatures.ineffective(["ss19": 1], text: "small", font: font) == ["ss19"])
    }

    @Test func letterStylesPickRangesWordsAndMatches() {
        #expect(LetterRanges.spans(LetterStyle(range: [2, 5]), in: "Night Owl").map(\.start) == [2])
        #expect(LetterRanges.spans(LetterStyle(word: -1), in: "Night  Owl Club").first?.start == 11)
        #expect(LetterRanges.spans(LetterStyle(word: 2), in: "Night Owl").first.map { [$0.start, $0.length] } == [6, 3])
        #expect(LetterRanges.spans(LetterStyle(match: "o"), in: "Owl Room").map(\.start) == [0, 5, 6])
        #expect(LetterRanges.spans(LetterStyle(word: 4), in: "Night Owl").isEmpty)
    }

    @Test func coloredLettersAreDrawnInTheirColour() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#000000"},
        {"type": "text", "id": "t", "text": "IIII", "font": "Helvetica", "size": 300, "color": "#FFFFFF",
         "letters": [{"range": [0, 2], "color": "#FF0000"}], "frame": {"height": 0.8}}
        """##)
        let rendered = try await Probe.render(design)
        let ink = try #require(rendered.report.text.first?.ink)
        let y = Int(ink[1] + ink[3] / 2)
        let left = Probe.pixel(rendered.image, Int(ink[0] + 4), y), right = Probe.pixel(rendered.image, Int(ink[0] + ink[2] - 4), y)
        #expect(left[0] > 200 && left[1] < 40, "\(left)")
        #expect(right[0] > 200 && right[1] > 200, "\(right)")
    }

    @Test func wordsAlongAPathFitAndAreChecked() async throws {
        for path in [#""circle""#, #"{"shape": "arc", "bend": 0.4}"#, #"{"shape": "arc", "bend": -0.4}"#, #"{"shape": "wave", "amplitude": 0.4}"#] {
            let design = try Probe.square(##"""
            {"type": "background", "fill": "#101820"},
            {"type": "text", "id": "t", "text": "Round and round", "font": "Avenir Next", "size": 60, "color": "#FFFFFF",
             "path": \##(path), "frame": {"width": 0.9, "aspect": 1}}
            """##, size: 800)
            let rendered = try await Probe.render(design)
            let measure = try #require(rendered.report.text.first)
            #expect(measure.fits && measure.insideTrim, "\(path)")
            #expect((measure.contrast ?? 0) > 10, "\(path): \(measure.contrast ?? -1)")
        }
        // Too long for the circle at the smallest size: reported, not hidden.
        let crowded = try Probe.square(##"""
        {"type": "background", "fill": "#101820"},
        {"type": "text", "id": "t", "text": "Far too many words to go round one small circle without overlapping", "size": 60,
         "min_size": 50, "color": "#FFFFFF", "path": "circle", "frame": {"width": 0.4, "aspect": 1}}
        """##, size: 800)
        let report = try await Probe.render(crowded).report
        #expect(report.findings.contains { $0.check == "fit" })
    }

    @Test func extrusionRunsTheWayItsAngleSays() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#000000"},
        {"type": "text", "id": "t", "text": "H", "font": "Helvetica", "size": 300, "color": "#FFFFFF",
         "extrude": {"depth": 60, "angle": 135, "color": "#FF0000", "shade": 0}, "frame": {"width": 0.5, "height": 0.5}}
        """##)
        let rendered = try await Probe.render(design)
        let ink = try #require(rendered.report.text.first?.ink)
        // The ink's bottom-right corner is the depth (red); its top-right corner is clear —
        // depth running up would put red there.
        let below = Probe.pixel(rendered.image, Int(ink[0] + ink[2]) - 6, Int(ink[1] + ink[3]) - 6)
        #expect(below[0] > 200 && below[1] < 40, "\(below)")
        let above = Probe.pixel(rendered.image, Int(ink[0] + ink[2]) - 3, Int(ink[1]) + 3)
        #expect(above[0] < 30, "\(above)")
    }

    @Test func anInlineIsDrawnInsideTheLetters() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#000000"},
        {"type": "text", "id": "t", "text": "I", "font": "Helvetica", "weight": "black", "size": 600, "color": "#0000FF",
         "inline": {"color": "#FFFF00", "width": 6, "inset": 6}, "frame": {"width": 0.5, "height": 0.8}}
        """##)
        let image = try await Probe.render(design).image
        // Across the stem's middle row: blue, then yellow, then blue in the middle.
        let y = image.height / 2
        let row = (0..<image.width).map { Probe.pixel(image, $0, y) }
        let yellow = row.filter { $0[0] > 200 && $0[1] > 200 && $0[2] < 60 }.count
        let blue = row.filter { $0[2] > 200 && $0[0] < 60 }.count
        #expect(yellow >= 2 && blue > yellow, "yellow \(yellow), blue \(blue)")
    }
}

/// A CoreText face for a test.
func FontResolver_font(_ family: String, _ size: Double) -> CTFont {
    CTFontCreateWithName(family as CFString, size, nil)
}
