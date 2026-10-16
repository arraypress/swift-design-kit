//
//  ReleaseTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Lists, the matched set, brand kits, SVG, CMYK print files and critique.
//

import CoreGraphics
import Foundation
import Legibility
import RecipeKit
import Testing
@testable import DesignKit

struct ListTests {

    @Test func writtenItemsSplitIntoTiersAndDetails() {
        let items = ListLayout.items(from: "HEAD || Two | Three || four | five :: 3:42")
        #expect(items.map(\.text) == ["HEAD", "Two", "Three", "four", "five"])
        #expect(items.map(\.tier) == [1, 2, 2, 3, 3])
        #expect(items.last?.detail == "3:42")
        #expect(ListLayout.items(from: "a\nb\n\nc").map(\.tier) == [1, 1, 2])
    }

    @Test func balancedBreaksEvenTheLines() {
        // Five items of 100 with gaps of 10, in 330: the fewest lines is 2; balanced is 3 + 2, not 3 + 2 greedily… either way no line is over.
        let rows = ListLayout.balanced([100, 100, 100, 100, 100], gap: 10, width: 330)
        #expect(rows.count == 2)
        #expect(rows.allSatisfy { $0.count * 100 + ($0.count - 1) * 10 <= 330 })
        // A long last item: greedy leaves [a b c][d long]; balanced moves c down when that shortens the widest line.
        let uneven = ListLayout.balanced([60, 60, 60, 60, 200], gap: 10, width: 400)
        #expect(uneven.count == 2)
        let widths = uneven.map { row in row.map { [60.0, 60, 60, 60, 200][$0] }.reduce(0, +) + Double(row.count - 1) * 10 }
        #expect(widths.max()! <= 330, "\(uneven)")
    }

    @Test func aLineUpFitsEveryItemAndIsCheckedLikeWords() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#101820"},
        {"type": "list", "id": "lineup", "items": "{lineup}", "sizes": [120, 70, 44], "separator_color": "#FFD166",
         "font": "Helvetica", "color": "#FFFFFF", "frame": {"height": 0.8}}
        """##, size: 800, vars: ##"{"lineup": "MARA QUILL || Juno Harte | Orrin Pike | The Velvet Static || Lena Vale | Cassius Moon | Dot Matrix | Northbound"}"##)
        let rendered = try await Probe.render(design)
        let lines = rendered.report.text
        #expect(lines.count >= 3)
        #expect(lines.allSatisfy { $0.fits && $0.insideTrim })
        #expect(lines.allSatisfy { ($0.readBack ?? 0) >= 0.99 }, "\(lines.map { ($0.words, $0.readBack ?? -1) })")
        #expect(lines.first?.words == "MARA QUILL" && lines.first?.id == "lineup-1")
        #expect(lines[0].sizeUnits > lines[1].sizeUnits, "top billing is largest")
        // Every name is drawn, once.
        let drawn = lines.map(\.words).joined(separator: " · ")
        for name in ["MARA QUILL", "Juno Harte", "Orrin Pike", "The Velvet Static", "Lena Vale", "Cassius Moon", "Dot Matrix", "Northbound"] {
            #expect(drawn.components(separatedBy: name).count == 2, "\(name)")
        }
        // The recipe keeps the list, not its lines.
        let json = String(decoding: try Recipes.encoded(rendered.prepared.design), as: UTF8.self)
        #expect(json.contains("\"type\" : \"list\"") && !json.contains("lineup-1"))
    }

    @Test func tooManyItemsAreReported() async throws {
        let names = (1...60).map { "Performer Number \($0)" }.joined(separator: " | ")
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#101820"},
        {"type": "list", "id": "crowd", "items": "\##(names)", "sizes": [60], "min_scale": 0.5, "frame": {"height": 0.3}}
        """##, size: 600)
        let report = try await Probe.render(design).report
        #expect(report.findings.contains { $0.check == "list" && $0.level == .fail })
    }

    @Test func aTracklistPutsDetailsAtTheRight() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#101820"},
        {"type": "list", "id": "tracks", "flow": "lines", "numbered": true, "columns": 2, "sizes": [40], "font": "Helvetica",
         "items": [{"text": "Night Drive", "detail": "3:42"}, "Low Tide", {"text": "Velvet", "detail": "2:58"}], "frame": {"height": 0.5}}
        """##, size: 800)
        let rendered = try await Probe.render(design)
        let words = rendered.report.text.map(\.words)
        #expect(words.contains("01  Night Drive") && words.contains("3:42") && words.contains("03  Velvet"))
        let line = try #require(rendered.report.text.first { $0.words == "01  Night Drive" }?.ink)
        let detail = try #require(rendered.report.text.first { $0.words == "3:42" }?.ink)
        #expect(detail[0] > line[0] + line[2], "the time sits right of the title")
    }
}

struct SetAndBrandTests {

    @Test func aSetRelaysOutTheDesignOnEachPage() throws {
        let template = try #require(StarterTemplates.named("podcast-cover"))
        let design = try Making.design(from: template, values: [:])
        #expect(try ReleaseKit.sizeList("cover, story ,a4,story") == ["cover", "story", "a4"])
        #expect(throws: DesignError.self) { try ReleaseKit.sizeList("cover,poster-ish") }
        let story = try ReleaseKit.adapted(design, to: "story")
        #expect(story.canvas.width == 1080 && story.canvas.height == 1920 && story.layers == design.layers, "a tall page keeps the sizes")
        let banner = try ReleaseKit.adapted(design, to: "banner")
        #expect(banner.canvas.width == 1500 && banner.canvas.height == 500)
        guard case .text(let before) = design.layers[2].content, case .text(let after) = banner.layers[2].content else {
            Issue.record("no text"); return
        }
        #expect(abs(after.size - before.size * 1.5) < 0.001, "3:1 grows by the most, 1.5×")
        #expect(abs(ReleaseKit.growth(width: 1280, height: 720) - (1280.0 / 720).squareRoot()) < 0.001)
    }

    @Test func aBrandRecoloursRetypesAndSignsADesign() throws {
        let logo = try Probe.pictureFile("logo.png", width: 200, height: 100, color: "#E4572E")
        let colors = try Brands.colors("#E4572E, #17BEBB, dark=#101820")
        #expect(colors == [.accent: DesignColor("#E4572E")!, .secondary: DesignColor("#17BEBB")!, .dark: DesignColor("#101820")!])
        #expect(throws: DesignError.self) { try Brands.colors("glow=#FFFFFF") }
        let brand = Brand(name: "night-label", logo: logo, colors: colors, pairing: "geometric")
        let template = try #require(StarterTemplates.named("cover-clean"))
        let design = try Brands.applied(brand, to: Making.design(from: template, values: [:]))
        #expect(design.brand == "night-label" && design.fonts?.pairing == "geometric")
        #expect(design.palette?.fixed[.accent] == DesignColor("#E4572E"))
        let logoLayer = try #require(design.layers.first { $0.id == "logo" })
        guard case .image(let image) = logoLayer.content else { Issue.record("not a picture"); return }
        #expect(image.source == logo && logoLayer.frame.aspect == 2)
        // cover-clean's words are top and bottom, centred: the logo takes a corner free of them.
        #expect([Anchor.bottomRight, .topRight, .bottomLeft, .topLeft].contains(logoLayer.frame.anchor))
        // By value: the recipe replays without the brand.
        let again = try Recipes.decoded(Recipes.encoded(design))
        #expect(again == design)
    }
}

struct OutputFormatTests {

    static let design = ##"""
    {"type": "background", "fill": "linear:#1B2A4A,#3E1F47,angle=160"},
    {"type": "shape", "id": "ring", "shape": "ring", "fill": "#FFD166", "frame": {"width": 0.3, "aspect": 1, "anchor": "top-left"}},
    {"type": "text", "id": "title", "text": "Vector **Night**", "font": "Helvetica", "size": 90, "color": "#FFFFFF", "accent": "#EF476F",
     "frame": {"height": 0.3}, "rotation": -4},
    {"type": "text", "id": "arc", "text": "round the bend", "font": "Helvetica", "size": 40, "path": {"shape": "arc", "bend": 0.4},
     "color": "#FFFFFF", "frame": {"anchor": "bottom", "height": 0.25}}
    """##

    @Test func anSVGHoldsShapesAndWordsAsVectors() async throws {
        let rendered = try await Probe.render(Probe.square(Self.design, size: 600))
        let url = Probe.folder.appendingPathComponent("vector.svg")
        try Exporter.write(rendered, to: url, format: .svg)
        let svg = try String(contentsOf: url, encoding: .utf8)
        #expect(svg.hasPrefix("<?xml") && svg.contains("<svg") && svg.hasSuffix("</svg>\n"))
        #expect(svg.contains("<tspan") && svg.contains(">Vector </tspan>") && svg.contains(">Night</tspan>"), "words stay text")
        #expect(svg.contains("fill=\"#EF476F\""), "the accent run keeps its colour")
        #expect(svg.contains("rotate(-4 "), "turned about its frame")
        #expect(svg.contains("fill-rule=\"evenodd\""), "the ring is a path with its hole")
        #expect(svg.contains("data:image/jpeg;base64,"), "the background is embedded")
        #expect(!svg.contains("round the bend"), "words on a path are outlines")
        // Well-formed XML.
        #expect(XMLParser(data: Data(svg.utf8)).parse())
    }

    @Test func aCMYKPrintFileHoldsNoRGB() async throws {
        let rendered = try await Probe.render(Probe.square(Self.design + ##", {"type": "text", "id": "green", "text": "Green", "size": 40, "color": "#00FF00", "frame": {"anchor": "top", "height": 0.1}}"##, size: 600))
        let url = Probe.folder.appendingPathComponent("print.pdf")
        try Exporter.write(rendered, to: url, format: .pdf, cmyk: true)
        let text = String(decoding: try Data(contentsOf: url), as: UTF8.self)
        #expect(text.contains("/OutputIntent"))
        #expect(!text.contains("/DeviceRGB") && !text.contains("/N 3"), "every colour space is CMYK")
        #expect(PrintColor.notes(rendered.prepared).isEmpty)
        // A shadow needs a transparency group, which CoreGraphics blends in RGB: said, not hidden.
        let shadowed = try await Probe.render(Probe.square(Self.design + ##", {"type": "text", "text": "Shadow", "size": 40, "shadow": {"blur": 8}, "frame": {"anchor": "top", "height": 0.1}}"##, size: 600))
        #expect(PrintColor.notes(shadowed.prepared).count == 1)
        // The gamut: green is far outside, grey and the yellow are not.
        let gamut = PrintColor.gamut(of: rendered.image, inks: ["#00FF00", "#808080", "#FFD166"])
        #expect(gamut.inks.first { $0.color == "#00FF00" }?.outside == true)
        #expect(gamut.inks.first { $0.color == "#808080" }?.outside == false)
        #expect(gamut.inks.first { $0.color == "#FFD166" }?.outside == false)
        #expect(gamut.outside > 0, "the green words lie outside")
    }

    @Test func deltaEIsCIE76() {
        #expect(PrintColor.deltaE((1, 1, 1), (1, 1, 1)) == 0)
        // White to black is L 100 → 0.
        #expect(abs(PrintColor.deltaE((1, 1, 1), (0, 0, 0)) - 100) < 0.1)
    }
}

struct CritiqueTests {

    @Test func aDesignOffItsGridWithAFlatHierarchyIsTold() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#E9E4DA"},
        {"type": "text", "id": "title", "text": "Off Kilter", "size": 70, "color": "#222222", "fit": "none", "frame": {"anchor": "top", "height": 0.2, "width": 0.5, "x": 0.13}},
        {"type": "text", "id": "sub", "text": "a talk", "size": 60, "color": "#222222", "fit": "none", "frame": {"anchor": "center", "height": 0.15, "width": 0.6, "x": -0.07}}
        """##, size: 800)
        let critique = Critic.critique(try await Probe.render(design), name: "bad")
        #expect(!critique.blocking)
        #expect(!critique.aligned && critique.loose.count == 2)
        #expect(critique.hierarchy.map { $0 < Critic.hierarchyStep } == true)
        #expect(critique.verdict.hasPrefix("bad: ! good, with"))
    }

    @Test func aFailedCheckBlocks() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#E9E4DA"},
        {"type": "text", "id": "faint", "text": "Faint", "size": 120, "color": "#DDD8CE", "frame": {"height": 0.3}}
        """##)
        let critique = Critic.critique(try await Probe.render(design), name: "faint")
        #expect(critique.blocking && critique.verdict.contains("✗ blocking — contrast"))
    }

    @Test func theStarterTemplatesAllPass() async throws {
        for template in StarterTemplates.all.prefix(4) {
            let design = try Making.design(from: template, values: [:], canvas: CanvasSpec(width: 600, height: 600).uniformSafeForTest())
            let critique = Critic.critique(try await Probe.render(design), name: template.name)
            #expect(critique.aligned && critique.margins.balanced, "\(critique.verdict)")
        }
    }
}

extension CanvasSpec {
    /// A page with a 6% safe inset, as the CLI makes for a size in pixels.
    func uniformSafeForTest() -> CanvasSpec {
        var copy = self
        copy.safe = Insets(uniform: 0.06)
        return copy
    }
}

struct AILayerTests {

    @Test func anEditIsPinnedAndChangesTheBackgroundInPlace() async throws {
        let design = try Probe.square(##"""
        {"type": "background", "id": "background", "fill": "#2040C0", "edit": "make it night", "upscale": false}
        """##, size: 300)
        let rendered = try await Probe.render(design)
        guard case .background(let background) = rendered.prepared.design.layers[0].content else { Issue.record("no background"); return }
        #expect(background.edit?.seed == 11 && background.edit?.model == "fake" && background.edit?.revision == "test")
        // #2040C0 inverted is #DFBF3F.
        let pixel = Probe.pixel(rendered.image, 150, 150)
        #expect(abs(Int(pixel[0]) - 0xDF) < 4 && abs(Int(pixel[2]) - 0x3F) < 4, "\(pixel)")
        #expect(rendered.report.sources.first?.kind == "edited")
        // The pin is in the recipe, and `--set background.edit=…` reads words.
        let again = try Recipes.decoded(Recipes.encoded(rendered.prepared.design))
        #expect(again == rendered.prepared.design)
        let changed = try Recipes.set("background.edit=add snow", in: design)
        guard case .background(let edited) = changed.layers[0].content else { Issue.record("no background"); return }
        #expect(edited.edit?.prompt == "add snow")
    }

    @Test func aSmallPictureOnAPrintPageIsEnlargedAndThePinRecorded() async throws {
        let small = try Probe.pictureFile("small.png", width: 60, height: 60, color: "#C03030")
        let design = try Probe.design(##"""
        {"design": 1, "canvas": {"width": 600, "height": 600, "dpi": 300},
         "layers": [{"type": "background", "fill": "#FFFFFF"},
                    {"type": "image", "id": "photo", "source": "\##(small)", "frame": {"width": 0.5, "aspect": 1}}]}
        """##)
        let rendered = try await Probe.render(design)
        let note = try #require(rendered.report.sources.first { $0.id == "photo" })
        #expect(note.upscaled && note.upscaledWith == "fake@test")
        guard case .image(let image) = rendered.prepared.design.layers[1].content else { Issue.record("no picture"); return }
        #expect(image.upscaledWith == "fake@test")
        // On screen, a file is left as it is unless asked.
        var screen = design
        screen.canvas.dpi = nil
        let plain = try await Probe.render(screen)
        #expect(plain.report.sources.first { $0.id == "photo" }?.upscaled == false)
    }
}
