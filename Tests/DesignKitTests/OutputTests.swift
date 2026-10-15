//
//  OutputTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  The files: the same design writes the same PNG bytes, golden hashes pin
//  the pixels across runs, the PDF keeps vector text and print boxes, and
//  variants and the contact sheet.
//

import CoreGraphics
import CryptoKit
import Foundation
import Testing
@testable import DesignKit

struct OutputTests {

    static let golden = #"""
      {"type": "background", "fill": "linear:#14213D,#FCA311,angle=150", "grain": 0.1, "vignette": 0.4, "duotone": ["#14213D", "#FCA311"]},
      {"type": "shape", "shape": "star", "fill": "#E5E5E5", "rotation": 12, "opacity": 0.8, "blend": "screen", "frame": {"anchor": "top-right", "width": 0.3, "aspect": 1}},
      {"type": "text", "id": "title", "text": "{title}", "font": "inter", "size": 110, "max_lines": 2, "color": "auto",
       "plate": {"color": "auto"}, "shadow": {"blur": 20, "y": 8}, "frame": {"anchor": "bottom", "height": 0.4}},
      {"type": "qr", "text": "https://example.com", "frame": {"anchor": "top-left", "width": 0.2, "aspect": 1}}
    """#

    @Test func theSameDesignWritesTheSameBytes() async throws {
        let design = try Probe.square(Self.golden, size: 800, vars: ##"{"title": "Golden Hour"}"##)
        let first = try Exporter.png(try await Probe.render(design).image)
        let second = try Exporter.png(try await Probe.render(design).image)
        #expect(first == second)
        // Pinned across runs and processes on this build: the hash below was
        // measured, and any change to the engine that moves a pixel moves it.
        let hash = SHA256.hash(data: first).map { String(format: "%02x", $0) }.joined()
        let fixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/golden-hash.txt")
        if ProcessInfo.processInfo.environment["DESIGN_GOLDEN_WRITE"] != nil {
            try FileManager.default.createDirectory(at: fixture.deletingLastPathComponent(), withIntermediateDirectories: true)
            try hash.write(to: fixture, atomically: true, encoding: .utf8)
        }
        let pinned = try String(contentsOf: fixture, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(hash == pinned, "the golden render moved: \(hash)")
    }

    @Test func aPrintPDFHasItsBoxesMarksAndVectorText() async throws {
        let design = try Probe.design(#"""
          {"design": 1, "canvas": {"preset": "a5"}, "layers": [{"type": "background", "fill": "#204060"},
           {"type": "text", "text": "Vector words", "size": 80, "color": "#FFFFFF"}]}
        """#)
        let rendered = try await Probe.render(design)
        let url = Probe.folder.appendingPathComponent("flyer.pdf")
        try Exporter.write(rendered, to: url, format: .pdf)
        let document = try #require(CGPDFDocument(url as CFURL))
        let page = try #require(document.page(at: 1))
        let media = page.getBoxRect(.mediaBox), trim = page.getBoxRect(.trimBox), bleed = page.getBoxRect(.bleedBox)
        #expect(abs(trim.width - 148 / 25.4 * 72) < 0.5 && abs(trim.height - 210 / 25.4 * 72) < 0.5, "the trim is A5")
        #expect(abs((bleed.width - trim.width) / 2 - 3 / 25.4 * 72) < 0.5, "3 mm of bleed")
        #expect(media.width > bleed.width + 40, "a slug for the crop marks")
        var fonts: CGPDFDictionaryRef?
        var resources: CGPDFDictionaryRef?
        if let dictionary = page.dictionary { CGPDFDictionaryGetDictionary(dictionary, "Resources", &resources) }
        if let resources { CGPDFDictionaryGetDictionary(resources, "Font", &fonts) }
        #expect(fonts != nil, "the words are text with a font, not a picture of text")
    }

    @Test func jpegAndPreview() async throws {
        let rendered = try await Probe.render(Probe.square(##"{"type": "background", "fill": "#204060"}"##, size: 1200))
        let url = Probe.folder.appendingPathComponent("cover.jpg")
        try Exporter.write(rendered, to: url, format: .jpeg)
        #expect(try Data(contentsOf: url).prefix(2) == Data([0xFF, 0xD8]))
        let preview = try #require(Exporter.scaled(rendered, longestSide: 300))
        #expect(preview.width == 300)
        #expect(OutputFormat.of(URL(fileURLWithPath: "a.JPG")) == .jpeg && OutputFormat.of(URL(fileURLWithPath: "a.webp")) == nil)
    }

    @Test func variantsChangeOnlyTheSeed() async throws {
        let design = try Making.design(from: StarterTemplates.named("cover-clean")!, values: [:])
        #expect(Variants.seed(of: design) == 42)
        #expect(try Variants.seeds("3", from: 42) == [42, 43, 44])
        #expect(try Variants.seeds("3-5", from: 42) == [3, 4, 5])
        #expect(try Variants.seeds("1,9", from: 42) == [1, 9])
        #expect(throws: DesignError.self) { try Variants.seeds("lots", from: 1) }
        let seeded = try Variants.seeded(design, seeds: [1, 2])
        #expect(seeded.map(Variants.seed(of:)) == [1, 2])
        #expect(seeded[0].layers.dropFirst() == design.layers.dropFirst())
        let colour = try Probe.square(##"{"type": "background", "fill": "#000000"}"##)
        #expect(throws: DesignError.self) { try Variants.seeded(colour, seeds: [1]) }
        let cell = Bitmaps.image(width: 300, height: 300) { $0.setFillColor(DesignColor.white.cgColor); $0.fill(CGRect(x: 0, y: 0, width: 300, height: 300)) }!
        let sheet = try #require(Variants.contactSheet((0..<6).map { (cell, "seed \($0)") }, cell: 200))
        #expect(sheet.width == 3 * 224 + 24, "six in a three-wide grid")
    }
}
