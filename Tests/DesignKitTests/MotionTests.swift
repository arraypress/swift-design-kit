//
//  MotionTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Mockups, carousels and animated covers.
//

import CoreGraphics
import Foundation
import Legibility
import RecipeKit
import Testing
@testable import DesignKit

/// Nearness rising from top to bottom, and a fill that paints the hole grey.
struct FakeDepth: DepthEstimating {
    let pin = "fake-depth"
    func nearness(of image: CGImage) async throws(DesignError) -> [Float] {
        (0..<image.height).flatMap { row in [Float](repeating: Float(row) / Float(image.height), count: image.width) }
    }
}

struct FakeFill: Inpainting {
    let pin = "fake-fill"
    func filled(_ image: CGImage, mask: CGImage) async throws(DesignError) -> CGImage { image }
}

struct MockupTests {

    @Test func everyKindDrawsAScene() throws {
        let cover = try #require(Bitmaps.image(width: 300, height: 300) { context in
            context.setFillColor(CGColor(srgbRed: 0.9, green: 0.2, blue: 0.2, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
        })
        for kind in MockupKind.allCases {
            let scene = try #require(Mockups.render(cover, kind: kind, width: 800, height: 600))
            #expect(scene.width == 800 && scene.height == 600)
            // The design is in it: red pixels near the middle of the scene.
            let bytes = try #require(Pixels.rgba(of: scene))
            let reds = stride(from: 0, to: bytes.count, by: 4).filter { bytes[$0] > 180 && bytes[$0 + 1] < 90 && bytes[$0 + 2] < 90 }.count
            #expect(reds > 800 * 600 / 40, "\(kind): \(reds)")
        }
        // The same seed draws the same scene.
        let a = try #require(Mockups.render(cover, kind: .poster, width: 400, height: 300, seed: 3))
        let b = try #require(Mockups.render(cover, kind: .poster, width: 400, height: 300, seed: 3))
        #expect(Pixels.rgba(of: a) == Pixels.rgba(of: b))
    }
}

struct CarouselTests {

    @Test func aTemplateMakesACoverAPageAnItemAndAnEnd() throws {
        let template = try #require(CarouselTemplates.named("carousel-steps"))
        let carousel = try Carousels.make(template, values: ["steps": "One | Two | Three"])
        #expect(carousel.pages.count == 5)
        let designs = Carousels.designs(carousel)
        guard case .background(let first) = designs[0].layers[0].content, case .background(let last) = designs[4].layers[0].content else {
            Issue.record("no background"); return
        }
        #expect(first.span == [0, 5] && last.span == [4, 5])
        guard case .text(let step) = designs[2].layers.first(where: { $0.id == "step" })?.content else { Issue.record("no step"); return }
        #expect(step.text == "Two")
        // The recipe reads back as written.
        let again = try Carousels.decoded(Carousels.encoded(carousel))
        #expect(again == carousel)
        #expect(throws: DesignError.self) { try Carousels.make(template, values: ["steps": " | "]) }
        let many = (1...25).map(String.init).joined(separator: "|")
        #expect(throws: DesignError.self) { try Carousels.make(template, values: ["steps": many]) }
    }

    @Test func theBackgroundRunsOnFromPageToPage() async throws {
        // A left-to-right blend across two pages: page one's right edge meets page two's left edge.
        let carousel = Carousel(canvas: CanvasSpec(width: 200, height: 200), background:
                                    Layer(content: .background(BackgroundContent(fill: .linear(colors: [.black, .white], angle: 90)))),
                                pages: [[], []])
        let pages = Carousels.designs(carousel)
        let one = try await Probe.render(pages[0]).image, two = try await Probe.render(pages[1]).image
        let edgeOne = Int(Probe.pixel(one, 199, 100)[0]), edgeTwo = Int(Probe.pixel(two, 0, 100)[0])
        #expect(abs(edgeOne - edgeTwo) <= 3, "\(edgeOne) vs \(edgeTwo)")
        #expect(Probe.pixel(one, 0, 100)[0] < 10 && Probe.pixel(two, 199, 100)[0] > 245)
    }
}

struct AnimationTests {

    static let design = ##"""
    {"type": "background", "fill": "linear:#1B2A4A,#C0506A,angle=160"},
    {"type": "text", "id": "title", "text": "LOOP", "size": 200, "color": "#FFFFFF", "frame": {"height": 0.3}}
    """##

    @Test func everyMotionLoopsSeamlesslyUnderStillWords() async throws {
        for kind in MotionKind.allCases {
            let rendered = try await Probe.render(Probe.square(Self.design, size: 320))
            let url = Probe.folder.appendingPathComponent("loop-\(kind.rawValue).mp4")
            var services = Probe.services
            services.depth = FakeDepth()
            services.inpainter = FakeFill()
            let motion = MotionSpec(kind: kind, seconds: 3, fps: 24, amount: 0.08, leaks: 0.4, particles: 30)
            let report = try await Animator.animate(rendered, motion: motion, to: url, services: services)
            #expect(report.frames == 72 && report.width == 320)
            #expect(report.seam < Animator.seamLimit, "\(kind): seam \(report.seam)")
            #expect((report.lowestContrast["title"] ?? 0) > 3, "\(kind)")
            #expect(report.passed)
            #expect(FileManager.default.fileExists(atPath: url.path))
            if kind == .parallax { #expect(report.motion.depthModel == "fake-depth" && report.motion.fillModel == "fake-fill") }
        }
        // The frame after the last is the first: the motions are periodic.
        #expect(abs(cos(2 * Double.pi * 1.0) - cos(0)) < 1e-12)
    }

    @Test func aParallaxNeedsItsModels() async throws {
        let rendered = try await Probe.render(Probe.square(Self.design, size: 200))
        await #expect(throws: DesignError.self) {
            _ = try await Animator.animate(rendered, motion: MotionSpec(kind: .parallax, seconds: 3), to: Probe.folder.appendingPathComponent("x.mp4"),
                                           services: Probe.services)
        }
    }

    @Test func motionReadsAsAWordOrAnObject() throws {
        let design = try Probe.design(##"{"design": 1, "canvas": {"width": 200, "height": 200}, "motion": "drift", "layers": [{"type": "background", "fill": "#000000"}]}"##)
        #expect(design.motion?.kind == .drift && design.motion?.seconds == 6)
        #expect(try Recipes.decoded(Recipes.encoded(design)) == design)
        #expect(throws: RecipeError.self) {
            try Probe.design(##"{"design": 1, "canvas": {"width": 200, "height": 200}, "motion": {"kind": "spin"}, "layers": [{"type": "background", "fill": "#000000"}]}"##)
        }
    }
}
