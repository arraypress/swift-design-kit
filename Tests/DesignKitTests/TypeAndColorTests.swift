//
//  TypeAndColorTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Fonts by role through a pairing, named sizes on its scale, the installed
//  catalogue and its categories, licence bits in a PDF; palette roles from
//  the art, readable role colours, and the two-families / three-colours
//  warnings.
//

import CoreGraphics
import Foundation
import Legibility
import RecipeKit
import Testing
@testable import DesignKit

/// A fetcher that has nothing and cannot fetch.
struct EmptyFetcher: FontFetching {
    func files(for font: OpenFont) async throws(DesignError) -> [URL] { throw .missing("offline: \(font.family)") }
    func fetched(_ font: OpenFont) -> [URL]? { nil }
}

struct TypeAndColorTests {

    @Test func theCatalogueOfPairingsIsSound() {
        let names = Pairings.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(Pairings.named(Pairings.fallback) != nil)
        for pairing in Pairings.all {
            for face in pairing.display + pairing.text {
                #expect(Fonts.weights.contains(face.weight), "\(pairing.name): \(face.weight)")
                let known = Fonts.bundled.contains { $0.name == face.family } || OpenFonts.named(face.family) != nil
                    || ["Didot", "Avenir Next", "Big Caslon", "Baskerville", "Helvetica Neue", "Futura", "DIN Condensed",
                        "American Typewriter", "Menlo", "Gill Sans", "Cochin", "Bodoni 72", "Cooper Black"].contains(face.family)
                #expect(known, "\(pairing.name): \(face.family) is neither macOS's, bundled nor open")
            }
            // Every role can be set with nothing fetched: a local face is among the candidates.
            #expect(Pairings.pick(pairing.display, fetchable: false, fetched: { _ in false }) != nil, "\(pairing.name) display")
            #expect(Pairings.pick(pairing.text, fetchable: false, fetched: { _ in false }) != nil, "\(pairing.name) text")
        }
        #expect(OpenFonts.all.allSatisfy { $0.licenceFile != nil && !$0.fontFiles.isEmpty })
        #expect(OpenFonts.all.filter(\.isCurated).count == OpenFonts.curated.count, "every curated family is in the index")
        #expect(OpenFonts.named("playfair-display")?.family == "Playfair Display")
        #expect(OpenFonts.named("Bebas Neue")?.url(of: OpenFonts.named("Bebas Neue")!.files[0]).absoluteString
                    == "https://raw.githubusercontent.com/google/fonts/\(OpenFonts.commit)/ofl/bebasneue/BebasNeue-Regular.ttf")
    }

    @Test func rolesAreSetInThePairingsFacesAndNamedSizesFollowItsScale() async throws {
        let design = try Probe.design(##"""
        {"design": 1, "canvas": {"width": 400, "height": 400}, "fonts": {"pairing": "swiss"},
         "layers": [{"type": "background", "fill": "#000000"},
                    {"type": "text", "id": "title", "text": "Title", "font": "display", "size": "title"},
                    {"type": "text", "id": "body", "text": "body copy", "font": "text", "size": "body", "weight": "medium"}]}
        """##)
        let rendered = try await Probe.render(design)
        let fonts = try #require(rendered.prepared.design.fonts)
        #expect(fonts.display?.family == "Helvetica Neue" && fonts.text?.family == "Helvetica Neue", "pinned when made")
        #expect(fonts.scale == 1.414 && fonts.base == 30)
        let title = try #require(rendered.prepared.faces["1"]), body = try #require(rendered.prepared.faces["2"])
        #expect(title.weight == "bold" && body.weight == "medium", "the role's weight unless the layer says")
        #expect(abs(title.size - 30 * pow(1.414, 3)) < 0.1 && body.size == 30)
        #expect(rendered.report.pairing == "swiss" && rendered.report.fonts == ["Helvetica Neue bold", "Helvetica Neue medium"])
        // The recipe keeps the step and the pinned faces.
        let again = try Recipes.decoded(Recipes.encoded(rendered.prepared.design))
        #expect(again.fonts == fonts)
        guard case .text(let text) = again.layers[1].content else { Issue.record("no text"); return }
        #expect(text.step == .title)
        // Changing the pairing drops the old pair's faces.
        let changed = try Recipes.set("pairing=editorial", in: rendered.prepared.design)
        #expect(changed.fonts == Typesetting(pairing: "editorial"))
        #expect(throws: RecipeError.self) { try Recipes.set("pairing=fancy", in: design) }
    }

    @Test func anOpenFontIsTakenOnlyWhenItCanBeFetched() throws {
        // `condensed` lists Bebas Neue (open) before DIN Condensed (macOS).
        let local = try Fonts.pinned(Typesetting(pairing: "condensed"), usesRoles: true, fetcher: nil)
        #expect(local?.display?.family == "DIN Condensed", "nothing can fetch: the installed face")
        let online = try Fonts.pinned(Typesetting(pairing: "condensed"), usesRoles: true, fetcher: EmptyFetcher())
        #expect(online?.display?.family == "Bebas Neue", "a fetcher: the open face first")
        #expect(try Fonts.pinned(nil, usesRoles: true, fetcher: nil)?.pairing == Pairings.fallback)
        #expect(try Fonts.pinned(nil, usesRoles: false, fetcher: nil) == nil)
    }

    @Test func theInstalledCatalogueSortsFamiliesIntoKinds() {
        let rows = FontCatalog.families()
        func row(_ family: String) -> FontFamily? { rows.first { $0.family == family } }
        #expect(row("Menlo")?.category == .mono)
        #expect(row("Didot")?.category == .serif)
        #expect(row("Helvetica Neue")?.category == .sans)
        #expect(row("Helvetica Neue")?.styles.contains("Bold") == true)
        #expect(row("Inter")?.source == "bundled")
        #expect(row("Playfair Display")?.source == "open" && row("Playfair Display")?.licence == "OFL-1.1")
        #expect(FontTraits.embeddable(fsType: 0) && FontTraits.embeddable(fsType: 0x0004) && FontTraits.embeddable(fsType: 0x0008))
        #expect(!FontTraits.embeddable(fsType: 0x0002) && !FontTraits.embeddable(fsType: 0x0200))
    }

    @Test func aFaceThatMayNotBeEmbeddedIsAPictureInThePDF() async throws {
        guard FontResolver_isAvailable("Ayuthaya"), !Fonts.embeddable(family: "Ayuthaya", weight: "regular") else { return }
        let rendered = try await Probe.render(Probe.square(##"""
        {"type": "background", "fill": "#FFFFFF"},
        {"type": "text", "text": "Restricted", "font": "Ayuthaya", "color": "#000000", "frame": {"height": 0.3, "anchor": "top"}},
        {"type": "text", "text": "Open", "font": "inter", "color": "#000000", "frame": {"height": 0.3, "anchor": "bottom"}}
        """##))
        #expect(rendered.report.findings.contains { $0.check == "embedding" })
        let url = Probe.folder.appendingPathComponent("embedding.pdf")
        try Exporter.write(rendered, to: url, format: .pdf)
        let pdf = String(decoding: try Data(contentsOf: url), as: UTF8.self)
        #expect(!pdf.contains("Ayuthaya"), "the restricted face is not in the file")
        #expect(pdf.contains("Inter"), "an open face stays text")
    }

    @Test func paletteRolesComeFromTheArtAndHarmony() {
        // An orange picture with a little teal.
        let orange = ColorRoles.lch(hex: "#E8742A"), teal = ColorRoles.lch(hex: "#1F8A8A")
        let found = ColorRoles.roles(swatches: [(orange, 0.8), (teal, 0.2)], spec: .standard)
        #expect(found.dominant.hex == "#E8742A")
        #expect(found.accentFrom == "art" && found.accent.hex == "#1F8A8A", "the art's own far colour is the accent")
        let complement = ColorRoles.roles(swatches: [(orange, 1)], spec: PaletteSpec(harmony: .complementary))
        let turned = ColorRoles.lch(hex: complement.accent.hex)
        #expect(ColorRoles.hueDistance(turned.h, orange.h) > 160, "complementary sits across the wheel")
        let split = ColorRoles.roles(swatches: [(orange, 1)], spec: PaletteSpec(harmony: .split))
        #expect(abs(ColorRoles.hueDistance(ColorRoles.lch(hex: split.accent.hex).h, orange.h) - 150) < 12)
        let analogous = ColorRoles.roles(swatches: [(orange, 1)], spec: PaletteSpec(harmony: .analogous))
        #expect(ColorRoles.hueDistance(ColorRoles.lch(hex: analogous.accent.hex).h, orange.h) < 45)
        #expect(ColorRoles.lch(hex: found.light.hex).l > 0.9 && ColorRoles.lch(hex: found.dark.hex).l < 0.3)
        let fixed = ColorRoles.roles(swatches: [(orange, 1)], spec: PaletteSpec(fixed: [.accent: DesignColor("#FF3366")!]))
        #expect(fixed.accent.hex == "#FF3366" && fixed.accentFrom == "fixed")
        // A role made readable keeps its hue and reaches the contrast.
        let dim = DesignColor("#3A5BA0")!
        let readable = ColorRoles.readable(dim, over: (0.01, 0.02), target: 4.5)
        #expect(Contrast.ratio(readable.luminance, 0.02) >= 4.5)
        #expect(ColorRoles.hueDistance(ColorRoles.lch(hex: readable.hex).h, ColorRoles.lch(hex: dim.hex).h) < 8)
    }

    @Test func roleColoursAreDrawnAndCheckedAgainstTwoFamiliesAndThreeColours() async throws {
        let rendered = try await Probe.render(Probe.square(##"""
        {"type": "background", "fill": "linear:#123456,#0A1A2A,angle=180"},
        {"type": "text", "id": "a", "text": "Accent words", "color": "accent", "size": 60, "frame": {"height": 0.25, "anchor": "top"}},
        {"type": "shape", "shape": "rect", "fill": "#FF0000", "frame": {"height": 0.05, "anchor": "center"}},
        {"type": "shape", "shape": "rect", "fill": "#00FF00", "frame": {"height": 0.05, "anchor": "bottom"}},
        {"type": "text", "id": "b", "text": "one", "font": "Menlo", "color": "#FFFF00", "frame": {"height": 0.1, "anchor": "left"}},
        {"type": "text", "id": "c", "text": "two", "font": "Didot", "color": "#FFFFFF", "frame": {"height": 0.1, "anchor": "right"}}
        """##))
        let palette = try #require(rendered.report.palette)
        let measure = try #require(rendered.report.text.first { $0.id == "a" })
        #expect(measure.contrast.map { $0 >= 3 } == true, "a role colour is made to read: \(measure.contrast ?? 0)")
        #expect(ColorRoles.hueDistance(ColorRoles.lch(hex: measure.color).h, ColorRoles.lch(hex: palette.accent.hex).h) < 10)
        #expect(rendered.report.findings.contains { $0.check == "families" }, "system, Menlo, Didot: three families")
        #expect(rendered.report.findings.contains { $0.check == "colors" }, "\(rendered.report.colors)")
    }
}

/// CanvasKit's check, without importing it into every test.
func FontResolver_isAvailable(_ family: String) -> Bool { Fonts.isLocal(family) }
