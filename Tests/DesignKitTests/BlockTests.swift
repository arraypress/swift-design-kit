//
//  BlockTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  The 0.3 building blocks, each proved on its pixels: every blend mode,
//  frames and borders, arrows, rings, bursts and badges, dashed lines,
//  fades, textures, gradient maps.
//

import CoreGraphics
import Foundation
import Testing
@testable import DesignKit

struct BlockTests {

    func close(_ a: [UInt8], _ b: [UInt8], _ tolerance: Int = 4) -> Bool {
        zip(a, b).allSatisfy { abs(Int($0) - Int($1)) <= tolerance }
    }

    /// A 400² page: grey background, one layer over it.
    func over(_ layer: String, background: String = "#808080") async throws -> CGImage {
        try await Probe.render(Probe.square(##"{"type": "background", "fill": "\##(background)"}, \##(layer)"##)).image
    }

    @Test func everyBlendModeDraws() async throws {
        // A colour over mid grey (#808080): each mode's own arithmetic, per channel.
        let cases: [(String, [UInt8])] = [
            ("multiply", [0x80, 0x40, 0x00]), ("screen", [0xFF, 0xBF, 0x80]), ("darken", [0x80, 0x80, 0x00]),
            ("lighten", [0xFF, 0x80, 0x80]), ("difference", [0x7F, 0x00, 0x80]), ("exclusion", [0x7F, 0x80, 0x80]),
            ("linear-dodge", [0xFF, 0xFF, 0x80]), ("linear-burn", [0x80, 0x00, 0x00]),
        ]
        for (mode, expected) in cases {
            let image = try await over(##"{"type": "shape", "shape": "rect", "fill": "#FF8000", "blend": "\##(mode)", "frame": {"area": "bleed"}}"##)
            let pixel = Probe.pixel(image, 200, 200)
            #expect(close(Array(pixel.prefix(3)), expected, 3), "\(mode): \(pixel)")
        }
        // The rest draw something other than normal would.
        let normal = Probe.pixel(try await over(##"{"type": "shape", "shape": "rect", "fill": "#FF8000", "frame": {"area": "bleed"}}"##), 200, 200)
        for mode in ["color-dodge", "color-burn", "soft-light", "hue", "saturation", "color", "luminosity"] {
            let pixel = Probe.pixel(try await over(##"{"type": "shape", "shape": "rect", "fill": "#FF8000", "blend": "\##(mode)", "frame": {"area": "bleed"}}"##), 200, 200)
            #expect(!close(pixel, normal, 2), "\(mode) drew as normal")
        }
        // Over exactly mid grey, overlay and hard light give the source back; over a darker grey they do not.
        for mode in ["overlay", "hard-light"] {
            let pixel = Probe.pixel(try await over(##"{"type": "shape", "shape": "rect", "fill": "#FF8000", "blend": "\##(mode)", "frame": {"area": "bleed"}}"##,
                                                   background: "#404040"), 200, 200)
            #expect(!close(pixel, normal, 2), "\(mode) drew as normal")
        }
        #expect(BlendMode.allCases.count == 18)
        #expect(Set(BlendMode.allCases.map(\.psdKey)).count == 18, "each mode has its own Photoshop key")
    }

    @Test func framesAndBordersSitInsideTheirBox() async throws {
        let frame = try await over(##"{"type": "shape", "shape": "frame", "inset": 20, "stroke": {"color": "#FFFFFF", "width": 10}, "frame": {"area": "bleed"}}"##)
        // 400 px page: a unit is 0.4 px; inset 20 → 8 px, width 10 → 4 px.
        #expect(Probe.pixel(frame, 200, 10)[0] > 240, "the line, 8–12 px in")
        #expect(Probe.pixel(frame, 200, 4)[0] < 140 && Probe.pixel(frame, 200, 30)[0] < 140, "nothing either side")
        let double = try await over(##"{"type": "shape", "shape": "double-frame", "inset": 10, "gap": 20, "stroke": {"color": "#FFFFFF", "width": 5}, "frame": {"area": "bleed"}}"##)
        #expect(Probe.pixel(double, 200, 5)[0] > 230 && Probe.pixel(double, 200, 15)[0] > 230, "two lines")
        #expect(Probe.pixel(double, 200, 10)[0] < 140, "a gap between them")
        let brackets = try await over(##"{"type": "shape", "shape": "brackets", "length": 0.2, "stroke": {"color": "#FFFFFF", "width": 10}, "frame": {"area": "bleed"}}"##)
        #expect(Probe.pixel(brackets, 30, 2)[0] > 230, "an arm along the top at the corner")
        #expect(Probe.pixel(brackets, 200, 2)[0] < 140, "no line at the middle of the edge")
        let film = try await over(##"{"type": "shape", "shape": "film-strip", "count": 4, "fill": "#000000", "frame": {"area": "bleed"}}"##)
        // Bands 9% of 400 = 36 px top and bottom; a hole at the first quarter's middle.
        #expect(Probe.pixel(film, 5, 18)[0] < 20, "the band")
        #expect(Probe.pixel(film, 50, 18)[0] > 100, "a sprocket hole shows the grey")
        #expect(Probe.pixel(film, 200, 200)[0] > 100, "the frame between the bands is open")
    }

    @Test func ringsBurstsBadgesArrowsAndDividers() async throws {
        let ring = try await over(##"{"type": "shape", "shape": "ring", "inner": 0.6, "fill": "#FFFFFF", "frame": {"width": 0.8, "aspect": 1}}"##)
        #expect(Probe.pixel(ring, 200, 200)[0] < 140, "a ring's middle is open")
        #expect(Probe.pixel(ring, 200, 80)[0] > 230, "its band is filled")
        let burst = try await over(##"{"type": "shape", "shape": "burst", "fill": "#FFFFFF", "frame": {"width": 0.8, "aspect": 1}}"##)
        #expect(Probe.pixel(burst, 200, 200)[0] > 230)
        let badge = try await over(##"{"type": "shape", "shape": "badge", "fill": "#FFFFFF", "frame": {"width": 0.8, "aspect": 1}}"##)
        #expect(Probe.pixel(badge, 200, 200)[0] > 230 && Probe.pixel(badge, 200, 66)[0] > 230, "filled out to the scallops")
        let arrow = try await over(##"{"type": "shape", "shape": "arrow", "stroke": {"color": "#FFFFFF", "width": 6}, "frame": {"width": 1, "height": 0.2}}"##)
        #expect(Probe.pixel(arrow, 100, 200)[0] > 230, "the shaft")
        #expect(Probe.pixel(arrow, 371, 202)[0] > 200, "the head is wider than the shaft")
        let divider = try await over(##"{"type": "shape", "shape": "divider", "stroke": {"color": "#FFFFFF", "width": 10}, "frame": {"width": 1, "height": 0.1}}"##)
        #expect(Probe.pixel(divider, 200, 200)[0] > 230 && Probe.pixel(divider, 60, 200)[0] > 230, "the diamond and the rule")
        let dashed = try await over(##"{"type": "shape", "shape": "line", "stroke": {"color": "#FFFFFF", "width": 8, "dash": [40, 40]}, "frame": {"width": 1, "height": 0.1}}"##)
        let row = (20..<380).map { Probe.pixel(dashed, $0, 200)[0] > 200 }
        #expect(row.contains(true) && row.contains(false), "dashes and gaps")
    }

    @Test func aFadeTakesALayerOutTowardItsEdge() async throws {
        let faded = try await over(##"{"type": "shape", "shape": "rect", "fill": "#FFFFFF", "fade": {"edge": "bottom", "start": 0.3, "end": 0.9}, "frame": {"area": "bleed"}}"##,
                                   background: "#000000")
        #expect(Probe.pixel(faded, 200, 40)[0] > 245, "whole above start")
        let middle = Probe.pixel(faded, 200, 240)[0]
        #expect(middle > 40 && middle < 215, "part way: \(middle)")
        #expect(Probe.pixel(faded, 200, 390)[0] < 10, "gone past end")
        let radial = try await over(##"{"type": "shape", "shape": "rect", "fill": "#FFFFFF", "fade": {"edge": "radial", "start": 0.2, "end": 0.8}, "frame": {"area": "bleed"}}"##,
                                    background: "#000000")
        #expect(Probe.pixel(radial, 200, 200)[0] > 245 && Probe.pixel(radial, 2, 2)[0] < 10)
    }

    @Test func texturesAreTheSameForASeedAndDifferForAnother() async throws {
        for kind in TextureKind.allCases {
            let layer = { (seed: Int) in ##"{"type": "texture", "kind": "\##(kind.rawValue)", "color": "#000000", "density": 0.8, "seed": \##(seed), "frame": {"area": "bleed"}}"## }
            let a = try await over(layer(1), background: "#FFFFFF")
            let b = try await over(layer(1), background: "#FFFFFF")
            #expect(try Exporter.png(a) == Exporter.png(b), "\(kind) is deterministic")
            let ink = (0..<40).map { Probe.pixel(a, 10 + $0 * 9, 10 + $0 * 9)[0] }
            #expect(ink.contains { $0 < 250 }, "\(kind) left marks")
            if kind == .noise || kind == .paper || kind == .dust {
                let c = try await over(layer(2), background: "#FFFFFF")
                #expect(try Exporter.png(a) != Exporter.png(c), "\(kind) follows its seed")
            }
        }
        // Halftone dots grow toward the angle (180°: down).
        let dots = try await over(##"{"type": "texture", "kind": "halftone", "density": 1, "scale": 40, "frame": {"area": "bleed"}}"##, background: "#FFFFFF")
        func ink(_ y0: Int) -> Int { (0..<400).reduce(0) { $0 + (Probe.pixel(dots, $1, y0 + ($1 % 16))[0] < 128 ? 1 : 0) } }
        #expect(ink(360) > ink(30) * 2, "more ink near the bottom: \(ink(30)) → \(ink(360))")
    }

    @Test func aGradientMapSendsTonesThroughItsColours() async throws {
        let image = try await Probe.render(Probe.square(##"{"type": "background", "fill": "linear:#000000,#FFFFFF,angle=90", "gradient_map": ["#1B1464", "#FF5E5B", "#FFF1C1"]}"##)).image
        #expect(close(Array(Probe.pixel(image, 1, 200).prefix(3)), [0x1B, 0x14, 0x64], 8), "black → the first")
        #expect(close(Array(Probe.pixel(image, 398, 200).prefix(3)), [0xFF, 0xF1, 0xC1], 8), "white → the last")
        let middle = Probe.pixel(image, 200, 200)
        #expect(middle[0] > 200 && middle[2] < 140, "mid grey → the middle colour: \(middle)")
    }

    @Test func blocksRoundTripThroughARecipe() throws {
        let design = try Probe.square(##"""
        {"type": "background", "fill": "#222222", "gradient_map": ["#000000", "#FF0000"]},
        {"type": "texture", "kind": "dust", "seed": 9, "blend": "screen", "opacity": 0.4},
        {"type": "shape", "shape": "double-frame", "inset": 12, "gap": 8, "radius": 20, "stroke": {"color": "accent", "width": 3, "dash": [10, 5]}},
        {"type": "shape", "shape": "burst", "count": 30, "fill": "light", "fade": {"edge": "left"}, "blend": "linear-dodge"}
        """##)
        let again = try Recipes.decoded(Recipes.encoded(design))
        #expect(again == design)
    }
}
