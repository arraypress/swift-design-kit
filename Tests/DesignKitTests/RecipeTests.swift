//
//  RecipeTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  The design file: strict reading with the close key named, every value's
//  range, the shorthand backgrounds, a round trip, and `--set`.
//

import CoreGraphics
import Foundation
import RecipeKit
import Testing
@testable import DesignKit

struct RecipeTests {

    func refusal(_ json: String) -> String? {
        do { _ = try Recipes.decoded(Data(json.utf8)); return nil } catch { return error.message }
    }

    static let minimal = ##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "background", "fill": "#112233"}]}"##

    @Test func aMinimalDesignReadsAndThePresetFillsTheCanvas() throws {
        let design = try Recipes.decoded(Data(Self.minimal.utf8))
        #expect(design.canvas.width == 3000 && design.canvas.height == 3000)
        #expect(design.canvas.preset == "cover")
        #expect(design.layers.count == 1)
    }

    @Test func unknownKeysAreRefusedWithTheCloseOne() {
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layer": []}"##)?.contains("did you mean layers") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "text", "text": "x", "szie": 40}]}"##)?
            .contains("did you mean layers.0.size") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "text", "text": "x", "frame": {"anchr": "top"}}]}"##)?
            .contains("did you mean") == true)
        // A key that belongs to another kind of layer is refused too.
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "shape", "shape": "rect", "font": "inter"}]}"##) != nil)
    }

    @Test func wordsAndValuesOutsideTheirListsAreRefused() {
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "text", "text": "x", "blend": "darken"}]}"##)?
            .contains("blend") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "covr"}, "layers": []}"##)?.contains("did you mean cover") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "text", "text": "x", "opacity": 2}]}"##)?
            .contains("0…1") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "text", "text": "x", "color": "#GG0000"}]}"##)?
            .contains("not a colour") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "wobble"}]}"##)?.contains("type") == true)
        #expect(refusal(##"{"design": 2, "canvas": {"preset": "cover"}, "layers": []}"##)?.contains("format 2") == true)
        #expect(refusal(##"{"canvas": {"preset": "cover"}, "layers": []}"##)?.contains("\"design\": 1") == true)
        #expect(refusal(##"{"design": 1, "canvas": {"preset": "cover"}, "layers": [{"type": "shape", "shape": "polygon", "points": [[0, 0]]}]}"##) != nil)
    }

    @Test func aDesignRoundTripsExactly() throws {
        let design = try Probe.square(#"""
          {"type": "background", "id": "background", "fill": "gradient:seed=9,palette=lagoon,motif=flow", "blur": 4, "grain": 0.1,
           "scrim": {"edge": "bottom", "strength": 0.4}, "duotone": ["#101820", "#F2AA4C"], "grade": {"contrast": 1.2}},
          {"type": "text", "id": "title", "text": "**Night** {title}", "font": "inter", "size": 90, "max_lines": 2, "color": "auto",
           "stroke": {"color": "#000000", "width": 4}, "plate": {"color": "auto"}, "avoid": ["faces"], "shadow": {}, "glow": {"color": "#FF00FF"}},
          {"type": "image", "source": "x.png", "cutout": true, "mask": {"shape": "circle"}, "frame": {"anchor": "top-left", "width": 0.3, "aspect": 1}},
          {"type": "shape", "shape": "star", "count": 7, "fill": "#FFD166", "rotation": 12, "blend": "multiply", "opacity": 0.5},
          {"type": "qr", "text": "https://example.com", "frame": {"columns": [1, 3], "anchor": "bottom"}},
          {"type": "group", "id": "strip", "layers": [{"type": "shape", "shape": "rect", "fill": "#FFFFFF"}]}
        """#, vars: ##"{"title": "Drive"}"##)
        let again = try Recipes.decoded(Recipes.encoded(design))
        #expect(again == design)
    }

    @Test func shorthandBackgroundsReadAsTheirKinds() throws {
        #expect(try FillShorthand.parse("#1B2A4A", field: "f") == .color(DesignColor("#1B2A4A")!))
        #expect(try FillShorthand.parse("linear:#FF9A8B,#FF6A88,angle=160", field: "f")
                == .linear(colors: [DesignColor("#FF9A8B")!, DesignColor("#FF6A88")!], angle: 160))
        #expect(try FillShorthand.parse("radial:#FFF,#000", field: "f") == .radial(colors: [.white, .black]))
        #expect(try FillShorthand.parse("gradient:seed=42,palette=lagoon,motif=flow", field: "f")
                == .gradient(GradientFill(seed: 42, palette: "lagoon", motif: "flow")))
        #expect(try FillShorthand.parse("imagine:neon city at night, rain", field: "f") == .ai(AIFill(prompt: "neon city at night, rain")))
        #expect(try FillShorthand.parse("image:cover.jpg", field: "f") == .image(path: "cover.jpg"))
        #expect(try FillShorthand.parse("photos/cover.jpg", field: "f") == .image(path: "photos/cover.jpg"))
        #expect(throws: RecipeError.self) { try FillShorthand.parse("linear:#FFF", field: "f") }
        #expect(throws: RecipeError.self) { try FillShorthand.parse("gradient:seed=x", field: "f") }
        #expect(throws: RecipeError.self) { try FillShorthand.parse("gradient:sed=4", field: "f") }
    }

    // MARK: --set

    static func cover() throws -> Design {
        try Making.design(from: StarterTemplates.named("cover-clean")!, values: ["title": "Night Drive"])
    }

    @Test func setChangesASlotsWords() throws {
        let changed = try Recipes.set("title=Night Drive (Remix)", in: Self.cover())
        #expect(changed.vars["title"] == "Night Drive (Remix)")
        #expect(changed.layers == (try Self.cover()).layers, "the words change through the vars; the layers keep their markers")
    }

    @Test func setOnALayerByIdChangesWhatItDraws() throws {
        let changed = try Recipes.set("background=imagine:rain on glass", in: Self.cover())
        guard case .background(let background) = changed.layers[0].content else { Issue.record("no background"); return }
        #expect(background.fill == .ai(AIFill(prompt: "rain on glass")))
    }

    @Test func setFindsAFieldInsideALayerByItsLastName() throws {
        let seeded = try Recipes.set("background.seed=8", in: Self.cover())
        guard case .background(let background) = seeded.layers[0].content, case .gradient(let spec) = background.fill else {
            Issue.record("no gradient"); return
        }
        #expect(spec.seed == 8)
        let palette = try Recipes.set("background.palette=sea-glass", in: seeded)
        guard case .background(let b2) = palette.layers[0].content, case .gradient(let s2) = b2.fill else { Issue.record("no gradient"); return }
        #expect(s2.palette == "sea-glass")
        let sized = try Recipes.set("title.size=120", in: Self.cover())
        guard case .text(let text) = sized.layers[2].content else { Issue.record("no text"); return }
        #expect(text.size == 120)
    }

    @Test func setTakesAFullPathAndRefusesWhatIsNotThere() throws {
        #expect(try Recipes.set("canvas.width=2000", in: Self.cover()).canvas.width == 2000)
        #expect(try Recipes.set("layers.1.opacity=0.5", in: Self.cover()).layers[1].opacity == 0.5)
        #expect(throws: RecipeError.self) { try Recipes.set("titel=x", in: Self.cover()) }
        #expect((try? Recipes.set("titel=x", in: Self.cover())) == nil)
        do { _ = try Recipes.set("titel=x", in: Self.cover()) } catch { #expect(error.localizedDescription.contains("did you mean title")) }
        #expect(throws: RecipeError.self) { try Recipes.set("layers.1.opacity=7", in: Self.cover()) }
        #expect(throws: RecipeError.self) { try Recipes.set("no-equals", in: Self.cover()) }
    }

    @Test func aRecipeFileKeepsPathsRelativeToItself() throws {
        let folder = Probe.folder.appendingPathComponent("recipe-paths")
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("art"), withIntermediateDirectories: true)
        let design = try Probe.square(##"{"type": "image", "source": "art/photo.png"}"##)
        let url = folder.appendingPathComponent("cover.json")
        try Recipes.save(design, to: url, from: folder, overwrites: true)
        #expect(String(decoding: try Data(contentsOf: url), as: UTF8.self).contains("\"source\" : \"art/photo.png\""))
        let back = try Recipes.load(url)
        guard case .image(let image) = back.layers[0].content else { Issue.record("no image"); return }
        #expect(image.source == folder.appendingPathComponent("art/photo.png").path)
        #expect(throws: RecipeFileError.self) { try Recipes.save(design, to: url, from: folder, overwrites: false) }
    }
}
