//
//  TemplateTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//

import CoreGraphics
import Foundation
import RecipeKit
import Testing
@testable import DesignKit

struct TemplateTests {

    @Test func theCatalogueIsSound() {
        #expect(StarterTemplates.problems.isEmpty, "\(StarterTemplates.problems)")
        #expect(StarterTemplates.all.count == 12)
        #expect(Set(StarterTemplates.all.map(\.name)).count == 12)
        for template in StarterTemplates.all {
            #expect(Presets.named(template.preset) != nil, "\(template.name)")
            #expect(template.slots.contains { $0.name == "background" }, "\(template.name) takes a background")
        }
    }

    @Test func valuesFillTheSlotsAndWordsKeepTheirMarkers() throws {
        let template = try #require(StarterTemplates.named("club-night"))
        let design = try Making.design(from: template, values: ["night": "Deep End", "glow": "#00E5FF"])
        #expect(design.vars["night"] == "Deep End")
        #expect(design.vars["venue"] == "The Vault, Dock Street", "a default fills a slot not given")
        #expect(design.template == "club-night")
        guard case .text(let text) = design.layers[1].content else { Issue.record("no text"); return }
        #expect(text.text == "{night}")
        #expect(design.layers[1].glow?.color == DesignColor("#00E5FF"), "a colour slot is filled when made")
    }

    @Test func aBackgroundValueBecomesItsFill() throws {
        let template = try #require(StarterTemplates.named("cover-clean"))
        let design = try Making.design(from: template, values: ["background": "imagine:neon city at night, rain"])
        guard case .background(let background) = design.layers[0].content else { Issue.record("no background"); return }
        #expect(background.fill == .ai(AIFill(prompt: "neon city at night, rain")))
    }

    @Test func anUnknownSlotOrAnEmptyValueIsRefused() throws {
        let template = try #require(StarterTemplates.named("cover-clean"))
        #expect(throws: DesignError.self) { try Making.design(from: template, values: ["titel": "x"]) }
        #expect(throws: DesignError.self) { try Making.design(from: template, values: ["title": "  "]) }
        #expect(throws: DesignError.self) { try Making.design(from: template, values: ["background": "#XYZ"]) }
    }

    @Test func templateNamesAreSuggested() {
        #expect(StarterTemplates.named("Cover-Clean")?.name == "cover-clean")
        #expect(StarterTemplates.suggestions(for: "cover-clen") == ["cover-clean"])
    }

    @Test func everyPresetHasItsSizeAndPrintOnesTheirBleed() throws {
        #expect(Presets.all.count == 15)
        let a4 = try #require(Presets.named("a4"))
        let canvas = CanvasSpec(preset: a4)
        #expect(canvas.width == 2480 && canvas.height == 3508, "210×297 mm at 300 dpi")
        #expect(canvas.bleed == 35, "3 mm at 300 dpi")
        #expect(canvas.cropMarks)
        #expect(canvas.geometry.pixelWidth == 2550)
        #expect(abs(canvas.geometry.safe.minX - (35 + 2480 * 5 / 210.0)) < 0.5, "5 mm inside the trim")
        let story = CanvasSpec(preset: try #require(Presets.named("story")))
        #expect(story.width == 1080 && story.height == 1920 && story.bleed == 0 && !story.cropMarks)
    }
}
