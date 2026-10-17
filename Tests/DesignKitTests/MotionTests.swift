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

/// A thin, spoked wheel cut from the middle of the picture: the kind of
/// subject a per-pixel warp tears.
struct FakeSubject: SubjectMatting {
    let pin = "fake-subject"
    func subject(of image: CGImage) async throws(DesignError) -> CGImage? {
        Wheel.cut(image)
    }
}

enum Wheel {
    static func path(width: Int, height: Int) -> CGPath {
        let path = CGMutablePath()
        let side = Double(min(width, height)), centre = CGPoint(x: Double(width) * 0.5, y: Double(height) * 0.45)
        let radius = side * 0.18
        path.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
        path.addEllipse(in: CGRect(x: centre.x - radius + 4, y: centre.y - radius + 4, width: radius * 2 - 8, height: radius * 2 - 8))
        for spoke in 0..<8 {
            let angle = Double(spoke) * .pi / 4
            let end = CGPoint(x: centre.x + cos(angle) * radius, y: centre.y + sin(angle) * radius)
            path.addPath(CGPath(rect: CGRect(x: -1, y: 0, width: 2, height: radius), transform: nil),
                         transform: CGAffineTransform(translationX: centre.x, y: centre.y).rotated(by: atan2(end.y - centre.y, end.x - centre.x) - .pi / 2))
        }
        return path
    }

    /// `image` kept only inside the wheel (spokes 2 px wide, a 4 px rim).
    static func cut(_ image: CGImage) -> CGImage? {
        Bitmaps.image(width: image.width, height: image.height) { context in
            context.addPath(path(width: image.width, height: image.height))
            context.clip(using: .evenOdd)
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            // The spokes, drawn again (the even-odd rim clip leaves them out).
            context.resetClip()
        }.flatMap { rim in
            Bitmaps.image(width: image.width, height: image.height) { context in
                context.draw(rim, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
                let side = Double(min(image.width, image.height))
                let centre = CGPoint(x: Double(image.width) * 0.5, y: Double(image.height) * 0.45)
                context.saveGState()
                for spoke in 0..<8 {
                    let angle = Double(spoke) * .pi / 8
                    let dx = cos(angle) * side * 0.18, dy = sin(angle) * side * 0.18
                    context.move(to: CGPoint(x: centre.x - dx, y: centre.y - dy))
                    context.addLine(to: CGPoint(x: centre.x + dx, y: centre.y + dy))
                }
                context.setLineWidth(2)
                context.replacePathWithStrokedPath()
                context.clip()
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
                context.restoreGState()
            }
        }
    }
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
            services.subject = FakeSubject()
            let motion = MotionSpec(kind: kind, seconds: 3, fps: 24, amount: 0.08, leaks: 0.4, particles: 30)
            let report = try await Animator.animate(rendered, motion: motion, to: url, services: services)
            #expect(report.frames == 72 && report.width == 320)
            #expect(report.seam < Animator.seamLimit, "\(kind): seam \(report.seam)")
            #expect((report.lowestContrast["title"] ?? 0) > 3, "\(kind)")
            #expect(report.passed)
            #expect(FileManager.default.fileExists(atPath: url.path))
            if kind == .parallax {
                #expect(report.motion.depthModel == "fake-depth" && report.motion.fillModel == "fake-fill" && report.motion.subjectModel == "fake-subject")
                let parallax = try #require(report.parallax)
                // The spoked wheel moves whole on every frame: nothing of the background inside it.
                #expect(parallax.subject && parallax.planes == 3)
                #expect((parallax.integrity ?? 0) >= Animator.integrityLimit, "integrity \(String(describing: parallax.integrity))")
                #expect(parallax.leaked == 0)
                #expect(!report.findings.contains { $0.check == "subject" && $0.level == .fail })
            } else {
                #expect(report.parallax == nil)
            }
        }
        // The frame after the last is the first: the motions are periodic.
        #expect(abs(cos(2 * Double.pi * 1.0) - cos(0)) < 1e-12)
    }

    @Test func aBigMoveIsHeldSoTheFillStaysSmall() async throws {
        let rendered = try await Probe.render(Probe.square(Self.design, size: 240))
        var services = Probe.services
        services.depth = FakeDepth()
        services.inpainter = FakeFill()
        services.subject = FakeSubject()
        let report = try await Animator.animate(rendered, motion: MotionSpec(kind: .parallax, seconds: 3, fps: 24, amount: 0.2),
                                                to: Probe.folder.appendingPathComponent("held.mp4"), services: services)
        let parallax = try #require(report.parallax)
        #expect(parallax.limited && parallax.reveal <= LayeredParallax.revealLimit * 240 + 0.1, "\(parallax.reveal)")
        #expect(report.findings.contains { $0.check == "motion" && $0.level == .warn })
        #expect((parallax.integrity ?? 0) >= Animator.integrityLimit && parallax.leaked == 0)
    }

    @Test func withNoSubjectTheBackgroundPlanesMoveAlone() async throws {
        let rendered = try await Probe.render(Probe.square(Self.design, size: 200))
        var services = Probe.services
        services.depth = FakeDepth()
        services.inpainter = FakeFill()
        let report = try await Animator.animate(rendered, motion: MotionSpec(kind: .parallax, seconds: 3, fps: 24),
                                                to: Probe.folder.appendingPathComponent("planes.mp4"), services: services)
        #expect(report.parallax?.subject == false && report.motion.subjectModel == nil)
        #expect(report.findings.contains { $0.check == "subject" && $0.level == .warn })
        #expect(report.seam < Animator.seamLimit)
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
        var pinned = try #require(design)
        pinned.motion = MotionSpec(kind: .parallax, depthModel: "d", fillModel: "f", subjectModel: "s")
        #expect(try Recipes.decoded(Recipes.encoded(pinned)).motion?.subjectModel == "s")
        #expect(try Recipes.decoded(Recipes.encoded(design)) == design)
        #expect(throws: RecipeError.self) {
            try Probe.design(##"{"design": 1, "canvas": {"width": 200, "height": 200}, "motion": {"kind": "spin"}, "layers": [{"type": "background", "fill": "#000000"}]}"##)
        }
    }
}

/// The layered parallax's arithmetic and its subject check.
struct ParallaxMathTests {

    @Test func everyLayerCoversTheFrameOnEveryFrameAndTheLoopCloses() {
        let size = CGSize(width: 1080, height: 1920), centre = CGPoint(x: 400, y: 700)
        let radius = 1080 * 0.06 * 0.5, dolly = 0.03
        let base = LayerMotion.baseScale(size: size, centre: centre, dolly: dolly, radius: radius, weights: LayerMotion.allPlaneWeights, frames: 180)
        for index in 0...180 {
            for weight in LayerMotion.allPlaneWeights {
                let r = LayerMotion.rect(size: size, centre: centre, base: base, dolly: dolly, radius: radius, weight: weight, phase: Double(index) / 180)
                #expect(r.minX <= 0.01 && r.minY <= 0.01 && r.maxX >= size.width - 0.01 && r.maxY >= size.height - 0.01, "\(index) \(weight) \(r)")
            }
        }
        let start = LayerMotion.rect(size: size, centre: centre, base: base, dolly: dolly, radius: radius, weight: 1, phase: 0)
        let end = LayerMotion.rect(size: size, centre: centre, base: base, dolly: dolly, radius: radius, weight: 1, phase: 1)
        #expect(abs(start.minX - end.minX) < 1e-6 && abs(start.width - end.width) < 1e-6)
        // At rest every layer lines up: the still, enlarged once.
        let far = LayerMotion.rect(size: size, centre: centre, base: base, dolly: dolly, radius: radius, weight: 0.15, phase: 0)
        #expect(far == start)
        // The subject slides against the far plane by at most radius × (1 − 0.15) plus the dolly's share.
        let slide = LayerMotion.slide(between: 1, and: 0.15, region: CGRect(x: 300, y: 500, width: 200, height: 400), size: size, centre: centre,
                                      base: base, dolly: dolly, radius: radius, frames: 180)
        #expect(slide >= radius * 0.85 && slide < radius * 0.85 * 1.15 + 400 * dolly, "\(slide)")
    }

    @Test func depthFallsIntoBands() {
        let flat = [Float](repeating: 0.5, count: 400)
        #expect(DepthBands.centres(flat, count: 3).count == 1)
        let two = (0..<400).map { Float($0 < 200 ? 0.1 : 0.9) }
        #expect(DepthBands.centres(two, count: 3).count == 2)
        let three = (0..<600).map { Float($0 < 200 ? 0.1 : $0 < 400 ? 0.5 : 0.9) }
        let centres = DepthBands.centres(three, count: 3)
        #expect(centres.count == 3)
        let thresholds = DepthBands.thresholds(centres)
        #expect(thresholds.count == 2 && thresholds[0] > 0.1 && thresholds[0] < 0.5 && thresholds[1] > 0.5 && thresholds[1] < 0.9)
        // A speck smaller than the cleaning radius is closed away.
        var values = [Float](repeating: 0, count: 40 * 40)
        values[20 * 40 + 20] = 1
        for y in 0..<40 { for x in 30..<40 { values[y * 40 + x] = 1 } }
        let masks = DepthBands.cumulativeMasks(values, width: 40, height: 40, thresholds: [0.5])
        #expect(masks[0][20 * 40 + 20] == false && masks[0][20 * 40 + 35] == true)
    }

    /// A thin-spoked subject drawn whole passes; the same subject torn — its
    /// top half moved one way and its bottom half another, as a depth warp
    /// does — fails both the share and the leak, the check the 0.5 loop lacked.
    @Test func theSubjectCheckCatchesATear() throws {
        let width = 200, height = 200
        let backdrop = try #require(Bitmaps.image(width: width, height: height) { context in
            context.setFillColor(CGColor(srgbRed: 0.1, green: 0.4, blue: 0.2, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        })
        let art = try #require(Bitmaps.image(width: width, height: height) { context in
            context.setFillColor(CGColor(srgbRed: 0.9, green: 0.85, blue: 0.8, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        })
        let subject = try #require(Wheel.cut(art))
        let moved = CGRect(x: 6, y: 3, width: width, height: height)
        let alone = try #require(Bitmaps.bytes(width: width, height: height) { $0.draw(subject, in: moved) })
        let whole = try #require(Bitmaps.bytes(width: width, height: height) { context in
            context.draw(backdrop, in: CGRect(x: 0, y: 0, width: width, height: height))
            context.draw(subject, in: moved)
        })
        let good = try #require(SubjectIntegrity.measure(scene: whole, subject: alone, width: width, height: height))
        #expect(good.iou >= 0.999 && good.leaked == 0, "\(good)")
        let torn = try #require(Bitmaps.bytes(width: width, height: height) { context in
            context.draw(backdrop, in: CGRect(x: 0, y: 0, width: width, height: height))
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: 90, width: width, height: 110))
            context.draw(subject, in: moved)
            context.restoreGState()
            context.clip(to: CGRect(x: 0, y: 0, width: width, height: 90))
            context.draw(subject, in: moved.offsetBy(dx: -4, dy: 0))
        })
        let bad = try #require(SubjectIntegrity.measure(scene: torn, subject: alone, width: width, height: height))
        #expect(bad.iou < Animator.integrityLimit && bad.leaked > 0, "\(bad)")
        #expect(SubjectIntegrity.iou(alone, alone) == 1)
    }
}
