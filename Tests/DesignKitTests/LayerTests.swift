//
//  LayerTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Every kind of layer drawn, proved on its pixels: backgrounds and their
//  treatments, pictures with masks and strokes, every shape, QR codes that
//  read back, groups, opacity, every blend mode, rotation, shadow and glow.
//

import CoreGraphics
import Foundation
import Legibility
import QRKit
import Testing
import VideoGrade
import VideoGradeLook
@testable import DesignKit

struct LayerTests {

    func close(_ a: [UInt8], _ b: [UInt8], _ tolerance: Int = 3) -> Bool {
        zip(a, b).allSatisfy { abs(Int($0) - Int($1)) <= tolerance }
    }

    @Test func colourAndBlendBackgroundsFillTheBleed() async throws {
        let solid = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#336699"}"##))
        #expect(close(Probe.pixel(solid.image, 0, 0), [0x33, 0x66, 0x99, 255]))
        #expect(close(Probe.pixel(solid.image, 399, 399), [0x33, 0x66, 0x99, 255]))
        let linear = try await Probe.render(Probe.square(##"{"type": "background", "fill": "linear:#FF0000,#0000FF,angle=180"}"##))
        let top = Probe.pixel(linear.image, 200, 2), bottom = Probe.pixel(linear.image, 200, 397)
        #expect(top[0] > 240 && top[2] < 15 && bottom[2] > 240 && bottom[0] < 15, "180° runs top to bottom")
        let radial = try await Probe.render(Probe.square(##"{"type": "background", "fill": "radial:#FFFFFF,#000000"}"##))
        #expect(Probe.pixel(radial.image, 200, 200)[0] > 245 && Probe.pixel(radial.image, 0, 0)[0] < 10)
    }

    @Test func aGradientBackgroundIsGradientKitsPictureForTheSeed() async throws {
        let a = try await Probe.render(Probe.square(##"{"type": "background", "fill": "gradient:seed=42,palette=lagoon,motif=flow"}"##))
        let b = try await Probe.render(Probe.square(##"{"type": "background", "fill": "gradient:seed=42,palette=lagoon,motif=flow"}"##))
        let c = try await Probe.render(Probe.square(##"{"type": "background", "fill": "gradient:seed=43,palette=lagoon,motif=flow"}"##))
        #expect(try Exporter.png(a.image) == Exporter.png(b.image), "the same seed draws the same bytes")
        #expect(try Exporter.png(a.image) != Exporter.png(c.image))
        await #expect(throws: DesignError.self) { try await Probe.render(Probe.square(##"{"type": "background", "fill": "gradient:palette=nope"}"##)) }
    }

    @Test func aMadePictureIsPinnedAndEnlarged() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "imagine:a lighthouse at dusk"}"##, size: 1200))
        guard case .background(let background) = rendered.prepared.design.layers[0].content, case .ai(let fill) = background.fill else {
            Issue.record("no made background"); return
        }
        #expect(fill.seed == 7 && fill.revision == "test" && fill.aspect == "1:1", "pinned when made")
        let note = try #require(rendered.prepared.sources.first)
        #expect(note.kind == "ai" && note.upscaled && note.enlargement > 4 && note.enlargementAfter < 1.25)
    }

    @Test func treatmentsChangeThePlate() async throws {
        let plain = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080"}"##))
        let darkened = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080", "darken": 0.5}"##))
        #expect(Probe.pixel(darkened.image, 200, 200)[0] < Probe.pixel(plain.image, 200, 200)[0] - 40)
        let scrim = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080", "scrim": {"edge": "bottom", "strength": 0.8}}"##))
        #expect(Probe.pixel(scrim.image, 200, 395)[0] < 60 && Probe.pixel(scrim.image, 200, 5)[0] > 120, "dark at the bottom, clear at the top")
        let duo = try await Probe.render(Probe.square(##"{"type": "background", "fill": "linear:#000000,#FFFFFF", "duotone": ["#200040", "#FFD000"]}"##))
        let light = Probe.pixel(duo.image, 200, 397)
        #expect(light[0] > 200 && light[1] > 170 && light[2] < 60, "white maps to the light colour")
        let vignette = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#C0C0C0", "vignette": 1}"##))
        #expect(Probe.pixel(vignette.image, 2, 2)[0] < Probe.pixel(vignette.image, 200, 200)[0] - 20, "corners darker")
        let grain = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080", "grain": 1}"##))
        let row = (0..<40).map { Probe.pixel(grain.image, 100 + $0, 200)[0] }
        #expect(Set(row).count > 5, "grain varies pixel to pixel")
        let blurred = try await Probe.render(Probe.square(##"{"type": "background", "fill": "linear:#000000,#FFFFFF,angle=90", "blur": 40}"##))
        #expect(Probe.pixel(blurred.image, 60, 200)[0] < 60 && Probe.pixel(blurred.image, 340, 200)[0] > 195,
                "a blur keeps the picture where it was (dark left, light right)")
        let graded = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080", "grade": {"exposure": 1}}"##))
        #expect(Probe.pixel(graded.image, 200, 200)[0] > Probe.pixel(plain.image, 200, 200)[0] + 20, "an inline look applies")
    }

    @Test func aLookFileIsReadAndInlined() async throws {
        let url = Probe.folder.appendingPathComponent("warm.json")
        try Data(##"{"img": 1, "grade": {"exposure": 1}}"##.utf8).write(to: url)
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080", "grade": "warm.json"}"##))
        guard case .background(let background) = rendered.prepared.design.layers[0].content, case .look(let look)? = background.grade else {
            Issue.record("the look was not inlined"); return
        }
        #expect(look.grade.exposure == 1)
        await #expect(throws: DesignError.self) {
            try Data(##"{"grade": {"exposur": 1}}"##.utf8).write(to: Probe.folder.appendingPathComponent("typo.json"))
            return try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080", "grade": "typo.json"}"##))
        }
    }

    @Test func picturesFillOrFitAndClipToTheirMask() async throws {
        let file = try Probe.pictureFile("red.png", width: 200, height: 100, color: "#FF0000")
        let fill = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "image", "source": "\##(file)", "frame": {"area": "trim"}}"##))
        #expect(close(Probe.pixel(fill.image, 5, 5), [255, 0, 0, 255]), "fill covers the frame")
        let fit = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "image", "source": "\##(file)", "fit": "fit", "frame": {"area": "trim"}}"##))
        #expect(close(Probe.pixel(fit.image, 200, 20), [255, 255, 255, 255]) && close(Probe.pixel(fit.image, 200, 200), [255, 0, 0, 255]), "fit letterboxes")
        let circle = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "image", "source": "\##(file)", "mask": {"shape": "circle"}, "frame": {"area": "trim"}}"##))
        #expect(close(Probe.pixel(circle.image, 3, 3), [255, 255, 255, 255]) && close(Probe.pixel(circle.image, 200, 200), [255, 0, 0, 255]))
        let polygon = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "image", "source": "\##(file)", "mask": {"shape": "polygon", "points": [[0.5, 0], [1, 1], [0, 1]]}, "frame": {"area": "trim"}}"##))
        #expect(close(Probe.pixel(polygon.image, 20, 20), [255, 255, 255, 255]) && close(Probe.pixel(polygon.image, 200, 390), [255, 0, 0, 255]))
        let rounded = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "image", "source": "\##(file)", "mask": {"shape": "rounded", "radius": 200}, "stroke": {"color": "#0000FF", "width": 10}, "frame": {"area": "trim"}}"##))
        #expect(close(Probe.pixel(rounded.image, 1, 1), [255, 255, 255, 255]))
        #expect(Probe.pixel(rounded.image, 200, 1)[2] > 200, "the stroke follows the mask")
        await #expect(throws: DesignError.self) { try await Probe.render(Probe.square(##"{"type": "image", "source": "missing.png"}"##)) }
    }

    @Test func aSmallPictureIsReportedAndEnlargedWhenAsked() async throws {
        let file = try Probe.pictureFile("tiny.png", width: 50, height: 50, color: "#00FF00")
        let soft = try await Probe.render(Probe.square(##"{"type": "image", "source": "\##(file)", "frame": {"area": "trim"}}"##))
        #expect(soft.report.findings.contains { $0.check == "resolution" })
        let sharp = try await Probe.render(Probe.square(##"{"type": "image", "source": "\##(file)", "upscale": true, "frame": {"area": "trim"}}"##))
        let note = try #require(sharp.prepared.sources.first)
        #expect(note.upscaled && note.enlargementAfter == 2)
    }

    @Test func aCutoutLiftsTheSubjectAndOutlinesIt() async throws {
        // A synthetic subject: a dark disc on a pale ground.
        let image = Bitmaps.image(width: 600, height: 600) { context in
            context.setFillColor(DesignColor("#EDEDED")!.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 600))
            context.setFillColor(DesignColor("#B02020")!.cgColor)
            context.fillEllipse(in: CGRect(x: 180, y: 180, width: 240, height: 240))
        }!
        let url = Probe.folder.appendingPathComponent("disc.png")
        try Exporter.png(image).write(to: url)
        let rendered = try await Probe.render(Probe.square(#"""
          {"type": "background", "fill": "#2040A0"},
          {"type": "image", "source": "\#(url.path)", "cutout": true, "fit": "fit", "stroke": {"color": "#FFFFFF", "width": 20}, "frame": {"area": "trim"}}
        """#))
        #expect(rendered.prepared.sources.first?.kind == "cutout")
        #expect(close(Probe.pixel(rendered.image, 5, 5), [0x20, 0x40, 0xA0, 255]), "the pale ground is gone")
        let centre = Probe.pixel(rendered.image, 200, 200)
        #expect(centre[0] > 150 && centre[1] < 60, "the subject stays")
    }

    @Test func everyShapeDraws() async throws {
        for (shape, inside, outside) in [("rect", (5, 5), nil), ("rounded", (200, 200), (1, 1)), ("ellipse", (200, 200), (2, 2)),
                                         ("star", (200, 200), (2, 2)), ("polygon", (200, 380), (10, 10))] as [(String, (Int, Int), (Int, Int)?)] {
            let points = shape == "polygon" ? ##", "points": [[0.5, 0], [1, 1], [0, 1]]"## : ""
            let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "shape", "shape": "\##(shape)", "fill": "#000000", "radius": 100\##(points), "frame": {"area": "trim"}}"##))
            #expect(Probe.pixel(rendered.image, inside.0, inside.1)[0] < 10, "\(shape) fills")
            if let outside { #expect(Probe.pixel(rendered.image, outside.0, outside.1)[0] > 245, "\(shape) leaves its corner") }
        }
        let line = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "shape", "shape": "line", "stroke": {"color": "#000000", "width": 10}, "frame": {"area": "trim"}}"##))
        #expect(Probe.pixel(line.image, 200, 200)[0] < 10 && Probe.pixel(line.image, 200, 100)[0] > 245)
        let blend = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "shape", "shape": "rect", "gradient": ["#FF0000", "#0000FF"], "angle": 90, "frame": {"area": "trim"}}"##))
        #expect(Probe.pixel(blend.image, 2, 200)[0] > 240 && Probe.pixel(blend.image, 397, 200)[2] > 240, "a gradient fill runs left to right at 90°")
    }

    @Test func aQRCodeReadsBack() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "qr", "text": "{link}", "frame": {"width": 0.6, "aspect": 1}}"##,
                                                           vars: ##"{"link": "https://example.com/market"}"##))
        #expect(try QRReader.codes(in: rendered.image).map(\.payload) == ["https://example.com/market"])
    }

    @Test func opacityBlendRotationShadowAndGlow() async throws {
        let base = ##"{"type": "background", "fill": "#808080"}, "##
        let half = try await Probe.render(Probe.square(base + ##"{"type": "shape", "shape": "rect", "fill": "#FFFFFF", "opacity": 0.5, "frame": {"area": "trim"}}"##))
        #expect(close(Probe.pixel(half.image, 200, 200), [0xC0, 0xC0, 0xC0, 255], 2))
        let expected: [String: UInt8] = ["normal": 0x33, "multiply": 0x1A, "screen": 0x99, "overlay": 0x33, "soft-light": 0x5A]
        for (mode, value) in expected {
            let rendered = try await Probe.render(Probe.square(base + ##"{"type": "shape", "shape": "rect", "fill": "#333333", "blend": "\##(mode)", "frame": {"area": "trim"}}"##))
            #expect(abs(Int(Probe.pixel(rendered.image, 200, 200)[0]) - Int(value)) <= 6, "\(mode): \(Probe.pixel(rendered.image, 200, 200)[0])")
        }
        let turned = try await Probe.render(Probe.square(base + ##"{"type": "shape", "shape": "rect", "fill": "#FFFFFF", "rotation": 45, "frame": {"width": 0.4, "aspect": 1}}"##))
        #expect(Probe.pixel(turned.image, 200, 105)[0] > 245, "a turned square's corner reaches up")
        #expect(Probe.pixel(turned.image, 135, 135)[0] < 140, "and its old corner is empty")
        let shadow = try await Probe.render(Probe.square(base + ##"{"type": "shape", "shape": "rect", "fill": "#FFFFFF", "shadow": {"color": "#000000", "blur": 0, "x": 50, "y": 50}, "frame": {"width": 0.4, "aspect": 1}}"##))
        #expect(Probe.pixel(shadow.image, 285, 285)[0] < 20, "the shadow falls right and down")
        let glow = try await Probe.render(Probe.square(base + ##"{"type": "shape", "shape": "rect", "fill": "#FFFFFF", "glow": {"color": "#FF00FF", "radius": 40}, "frame": {"width": 0.4, "aspect": 1}}"##))
        let halo = Probe.pixel(glow.image, 200, 122)
        #expect(halo[0] > halo[1] + 8, "a magenta glow round it: \(halo)")
    }
}
