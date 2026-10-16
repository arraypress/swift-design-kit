//
//  TextTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Words: slots filled, cases, every alignment, shrink to fit and max lines,
//  stroke, gradient letters, plates, fonts, and the auto colour.
//

import CanvasKit
import CoreGraphics
import Foundation
import Legibility
import Testing
@testable import DesignKit

struct TextTests {

    func ink(_ rendered: Rendered, _ path: String) -> CGRect? {
        rendered.report.text.first { $0.layer == path }?.ink.map { CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) }
    }

    @Test func slotsFillTheWordsAndCasesApply() async throws {
        let rendered = try await Probe.render(Probe.square(#"""
          {"type": "background", "fill": "#000000"},
          {"type": "text", "text": "{title} night", "case": "upper", "size": 70}
        """#, vars: ##"{"title": "late"}"##))
        let measure = try #require(rendered.report.text.first)
        #expect(measure.words == "LATE NIGHT")
        #expect(measure.readBack == 1, "the drawn words read back")
        #expect(Words.cased("night drive", .title) == "Night Drive")
        #expect(Words.cased("Night", .lower) == "night")
        #expect(Words.plain("**Night** *Drive* ~soft~") == "Night Drive soft")
    }

    @Test func alignmentsPlaceTheInk() async throws {
        var lefts: [String: Double] = [:]
        for align in ["left", "center", "right"] {
            let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "Hi", "size": 60, "align": "\##(align)", "valign": "top"}"##))
            lefts[align] = try #require(ink(rendered, "1")).minX
        }
        #expect(lefts["left"]! < lefts["center"]! && lefts["center"]! < lefts["right"]!)
        var tops: [String: Double] = [:]
        for valign in ["top", "middle", "bottom"] {
            let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "Hi", "size": 60, "valign": "\##(valign)"}"##))
            tops[valign] = try #require(ink(rendered, "1")).minY
        }
        #expect(tops["top"]! < tops["middle"]! && tops["middle"]! < tops["bottom"]!)
    }

    @Test func textShrinksToFitAndToItsLineLimit() async throws {
        let long = "A much longer title than this narrow frame can hold at its size"
        let free = try await Probe.render(Probe.square(##"{"type": "text", "text": "\##(long)", "size": 120, "fit": "none", "frame": {"height": 0.3}}"##))
        #expect(free.report.text[0].sizeUnits == 120)
        let fitted = try await Probe.render(Probe.square(##"{"type": "text", "text": "\##(long)", "size": 120, "max_lines": 2, "frame": {"height": 0.3}}"##))
        #expect(fitted.report.text[0].sizeUnits < 120 && fitted.report.text[0].lines <= 2 && fitted.report.text[0].fits)
        let stuck = try await Probe.render(Probe.square(##"{"type": "text", "text": "\##(long)", "size": 120, "min_size": 110, "max_lines": 1, "frame": {"height": 0.3}}"##))
        #expect(stuck.report.findings.contains { $0.check == "fit" && $0.level == .fail })
        let whole = try await Probe.render(Probe.square(##"{"type": "text", "text": "Low Frequency", "size": 200, "frame": {"width": 0.5}}"##))
        #expect(whole.report.text[0].lines == 2, "a word is never broken across lines")
    }

    @Test func strokeGradientAndPlateDraw() async throws {
        let stroked = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080"}, {"type": "text", "text": "I", "size": 300, "color": "#FFFFFF", "stroke": {"color": "#000000", "width": 20}}"##))
        let plain = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#808080"}, {"type": "text", "text": "I", "size": 300, "color": "#FFFFFF"}"##))
        #expect(try #require(ink(stroked, "1")).width > (try #require(ink(plain, "1"))).width, "the keyline adds ink round the letter")
        let gradient = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "█", "size": 300, "gradient": ["#FF0000", "#0000FF"]}"##))
        let box = try #require(ink(gradient, "1"))
        let top = Probe.pixel(gradient.image, Int(box.midX), Int(box.minY + 3)), bottom = Probe.pixel(gradient.image, Int(box.midX), Int(box.maxY - 3))
        #expect(top[0] > top[2] && bottom[2] > bottom[0], "red at the top, blue at the bottom")
        let plated = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#FFFFFF"}, {"type": "text", "text": "Hi", "size": 60, "color": "#FFFFFF", "plate": {"color": "#000000", "padding": 40}}"##))
        let lines = try #require(plated.plan.fits["1"]?.linesBounds)
        let above = Int(400 - lines.maxY - 8)
        #expect(Probe.pixel(plated.image, 200, above)[0] < 10, "the plate reaches past the lines")
    }

    @Test func anAutoPlateAppearsOnlyWhenTheWordsNeedIt() async throws {
        let needed = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#F0F0F0"}, {"type": "text", "text": "Read me", "size": 60, "color": "#FFFFFF", "plate": {}}"##))
        let plate = try #require(needed.plan.text["1"]?.plate)
        #expect(plate.hex.hasPrefix("#000000"), "white words on a pale ground get a dark plate")
        #expect(needed.report.findings.filter { $0.check == "contrast" }.isEmpty, "and then they read")
        let notNeeded = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#101010"}, {"type": "text", "text": "Read me", "size": 60, "color": "#FFFFFF", "plate": {}}"##))
        #expect(notNeeded.plan.text["1"]?.plate == nil)
    }

    @Test func autoColourPicksFromTheArtOrFallsBackToBlackOrWhite() async throws {
        let dark = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#101820"}, {"type": "text", "text": "Hello", "size": 60, "color": "auto"}"##))
        #expect((dark.plan.text["1"]?.color.luminance ?? 0) > 0.5)
        let light = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#F4F1EA"}, {"type": "text", "text": "Hello", "size": 60, "color": "auto"}"##))
        #expect((light.plan.text["1"]?.color.luminance ?? 1) < 0.2)
        // Two bands: a deep blue that the words sit on and a pale yellow elsewhere — the yellow is picked from the art.
        let art = try await Probe.render(Probe.square(#"""
          {"type": "background", "fill": "#14213D"},
          {"type": "shape", "shape": "rect", "fill": "#FCE38A", "frame": {"area": "trim", "anchor": "top", "height": 0.3}},
          {"type": "text", "text": "Hello", "size": 60, "color": "auto", "frame": {"anchor": "bottom", "height": 0.3}}
        """#))
        let picked = try #require(art.plan.text["2"]?.color)
        #expect(picked.components.red > 0.8 && picked.components.blue < 0.7, "picked \(picked.hex)")
        #expect(art.plan.text["2"]?.note?.contains("from the art") == true)
    }

    @Test func fontsResolveOrAreRefused() async throws {
        #expect(try await Fonts.family(for: "inter", folder: Probe.folder) == "Inter")
        #expect(try await Fonts.family(for: "source-serif", folder: Probe.folder) == "Source Serif 4")
        #expect(try await Fonts.family(for: nil, folder: Probe.folder) == nil)
        do { _ = try await Fonts.family(for: "Helvetika", folder: Probe.folder); Issue.record("not refused") } catch {
            #expect(error.localizedDescription.contains("did you mean Helvetica"))
        }
        do { _ = try await Fonts.family(for: "missing.ttf", folder: Probe.folder); Issue.record("not refused") } catch {}
        do { _ = try await Fonts.family(for: "Bebas Neue", folder: Probe.folder); Issue.record("fetched with no fetcher") } catch {
            #expect(error.localizedDescription.contains("open font"))
        }
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#000000"}, {"type": "text", "text": "Serif", "font": "source-serif", "size": 80}"##))
        #expect(rendered.report.text[0].readBack == 1)
    }
}
