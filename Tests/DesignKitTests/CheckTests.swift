//
//  CheckTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Every check made to fire on a design built to fail it, and stay quiet on
//  one that passes.
//

import CoreGraphics
import Foundation
import Testing
@testable import DesignKit

struct CheckTests {

    func findings(_ rendered: Rendered, _ check: String) -> [Finding] { rendered.report.findings.filter { $0.check == check } }

    @Test func aCleanDesignPasses() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#101820"}, {"type": "text", "id": "t", "text": "Night Drive", "size": 80, "color": "#FFFFFF"}"##))
        #expect(rendered.report.passed && rendered.report.findings.isEmpty, "\(rendered.report.findings)")
        let measure = try #require(rendered.report.text.first)
        #expect(measure.insideSafe && measure.insideTrim && measure.fits && measure.readBack == 1)
        #expect((measure.contrast ?? 0) > 15)
    }

    @Test func lowContrastFailsAndNamesTheFix() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#F2F2F2"}, {"type": "text", "id": "t", "text": "Faint words", "size": 60, "color": "#FFFFFF"}"##))
        let contrast = try #require(findings(rendered, "contrast").first)
        #expect(contrast.level == .fail && contrast.id == "t")
        #expect(contrast.fix?.contains("plate") == true)
        #expect(!rendered.report.passed)
    }

    @Test func textOffThePageIsClippedAndTextOutsideTheSafeAreaIsWarned() async throws {
        let off = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "Edge", "size": 80, "frame": {"anchor": "left", "width": 0.5, "x": -0.3}}"##))
        #expect(findings(off, "clipped").first?.level == .fail)
        let near = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "Edge", "size": 80, "align": "left", "frame": {"area": "trim", "anchor": "left", "width": 0.5}}"##))
        #expect(findings(near, "safe-area").first?.level == .warn)
        #expect(findings(near, "clipped").isEmpty)
    }

    @Test func wordsTheRecogniserCannotReadAreReported() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "Hidden words", "size": 60, "color": "#000000"}"##))
        #expect(findings(rendered, "read-back").first?.level == .fail)
    }

    @Test func printChecksSizeAndBleed() async throws {
        let small = try await Probe.render(Probe.design(#"""
          {"design": 1, "canvas": {"preset": "a5"}, "layers": [{"type": "background", "fill": "#FFFFFF"},
           {"type": "text", "text": "the small print", "size": 6, "fit": "none", "color": "#000000"}]}
        """#))
        let size = try #require(findings(small, "print-size").first)
        #expect(size.level == .fail, "\(small.report.text)")
        #expect((small.report.text.first?.sizePoints ?? 99) < 6)
        #expect(findings(small, "bleed").isEmpty)
        let noBleed = try await Probe.render(Probe.design(##"{"design": 1, "canvas": {"preset": "a5", "bleed": 0}, "layers": [{"type": "background", "fill": "#FFFFFF"}]}"##))
        #expect(findings(noBleed, "bleed").first?.level == .fail)
        let bare = try await Probe.render(Probe.design(##"{"design": 1, "canvas": {"preset": "a5"}, "layers": [{"type": "shape", "shape": "rect", "fill": "#FF0000"}]}"##))
        #expect(findings(bare, "bleed").first?.message.contains("does not reach") == true)
    }

    @Test func platformRulesAreKept() async throws {
        let small = try await Probe.render(Probe.design(##"{"design": 1, "canvas": {"preset": "cover", "width": 1000, "height": 1000}, "layers": [{"type": "background", "fill": "#000000"}]}"##))
        #expect(findings(small, "platform").first?.message.contains("3000") == true)
        let oblong = try await Probe.render(Probe.design(##"{"design": 1, "canvas": {"preset": "podcast-cover", "width": 3000, "height": 2000}, "layers": [{"type": "background", "fill": "#000000"}]}"##))
        #expect(findings(oblong, "platform").contains { $0.message.contains("square") })
    }

    @Test func anUnfilledSlotFails() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "{title}", "size": 60}"##))
        #expect(findings(rendered, "unfilled").first?.fix?.contains("--var title") == true)
    }

    @Test func wordsOnTheSubjectAreMeasuredAndMovedOff() async throws {
        // A synthetic subject: a red block on grey, down the left of the picture.
        let art = try Probe.pictureFile("subject.png", width: 400, height: 400, color: "#7A828C",
                                        square: ("#E23C28", CGRect(x: 40, y: 60, width: 150, height: 280)))
        let over = ##"{"type": "text", "id": "t", "text": "Night Drive", "size": 44, "max_lines": 2, "color": "#FFFFFF", "align": "left", "frame": {"anchor": "left", "width": 0.5, "height": 0.4}"##
        let plain = try await Probe.render(Probe.square(##"{"type": "background", "fill": "image:\##(art)"}, \##(over)}"##))
        let measured = try #require(plain.report.text.first?.onSubject)
        #expect(measured > Checker.subjectLimit, "the words sit on the block: \(plain.report.text)")
        #expect(findings(plain, "subject").first?.fix?.contains("avoid") == true)

        let avoiding = try await Probe.render(Probe.square(##"{"type": "background", "fill": "image:\##(art)"}, \##(over), "avoid": ["subject"]}"##))
        let moved = try #require(avoiding.report.text.first)
        #expect(moved.movedTo == "right", "\(moved)")
        #expect((moved.onSubject ?? 1) <= Checker.subjectLimit, "\(moved)")
        #expect(findings(avoiding, "subject").isEmpty)

        // Words on a label laid over the subject are on the label, not on it.
        let label = ##"{"type": "shape", "shape": "rect", "fill": "#F5F0E6", "frame": {"anchor": "left", "width": 0.5, "height": 0.4}}"##
        let labelled = try await Probe.render(Probe.square(##"{"type": "background", "fill": "image:\##(art)"}, \##(label), \##(over)}"##))
        #expect(labelled.report.text.first?.onSubject == 0, "\(labelled.report.text)")

        // No art, no subject: measured as nothing on it.
        let flat = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#101820"}, \##(over)}"##))
        #expect(flat.report.text.first?.onSubject == 0)
    }
}
