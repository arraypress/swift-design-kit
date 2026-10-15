//
//  LayoutTests.swift
//  DesignKitTests
//
//  Created by David Sherlock on 2026.
//
//  Frames by rule: anchors, sizes, margins, the column grid, below/above,
//  aspect, groups placing their children inside themselves.
//

import CanvasKit
import CoreGraphics
import Foundation
import Testing
@testable import DesignKit

struct LayoutTests {

    let area = CGRect(x: 100, y: 100, width: 800, height: 600)

    @Test func anchorsHoldTheirCorner() {
        let small = Placement(anchor: .topLeft, width: 0.25, height: 0.5)
        #expect(Layout.frame(small, in: area, grid: .standard) == CGRect(x: 100, y: 100, width: 200, height: 300))
        #expect(Layout.frame(Placement(anchor: .bottomRight, width: 0.25, height: 0.5), in: area, grid: .standard)
                == CGRect(x: 700, y: 400, width: 200, height: 300))
        #expect(Layout.frame(Placement(anchor: .center, width: 0.5, height: 0.5), in: area, grid: .standard)
                == CGRect(x: 300, y: 250, width: 400, height: 300))
    }

    @Test func marginsAreAShareOfTheShorterSideOnTheAnchoredEdges() {
        let frame = Layout.frame(Placement(anchor: .topRight, width: 0.25, height: 0.25, margin: 0.1), in: area, grid: .standard)
        #expect(frame == CGRect(x: 640, y: 160, width: 200, height: 150))
    }

    @Test func aspectSetsTheHeightFromTheWidth() {
        let frame = Layout.frame(Placement(anchor: .top, width: 0.5, aspect: 2), in: area, grid: .standard)
        #expect(frame.width == 400 && frame.height == 200)
    }

    @Test func columnsSpanTheGrid() {
        let grid = Grid(columns: 4, gutter: 0)
        let frame = Layout.frame(Placement(anchor: .top, height: 0.1, columns: [2, 2]), in: area, grid: grid)
        #expect(frame.minX == 300 && frame.width == 400)
        let overflow = Layout.column(start: 4, count: 3, in: area, grid: grid)
        #expect(overflow.width == 200, "a span past the last column stops at it")
    }

    @Test func belowPlacesUnderTheEarlierLayersLines() throws {
        let design = try Probe.square(#"""
          {"type": "text", "id": "title", "text": "Title", "size": 60, "fit": "none", "valign": "top", "frame": {"anchor": "top", "height": 0.5}},
          {"type": "shape", "id": "rule", "shape": "rect", "fill": "#000000", "frame": {"anchor": "top", "height": 0.02, "below": "title", "gap": 0.05}}
        """#)
        let placed = Layouter.place(design, geometry: design.canvas.geometry, families: [:])
        let lines = try #require(placed.fits["0"]?.linesBounds)
        let linesBottom = Double(design.canvas.geometry.pixelHeight) - lines.minY
        let rule = try #require(placed.frames["1"])
        #expect(abs(rule.minY - (linesBottom + 0.05 * design.canvas.geometry.safe.height)) < 0.01,
                "the rule sits under the drawn lines, not under the half-canvas text box")
    }

    @Test func aReferenceMustBeAnEarlierLayer() throws {
        let design = try Probe.square(#"""
          {"type": "shape", "shape": "rect", "fill": "#000000", "frame": {"below": "later"}},
          {"type": "shape", "id": "later", "shape": "rect", "fill": "#000000"}
        """#)
        #expect(throws: DesignError.self) { try Validation.check(design) }
    }

    @Test func groupsPlaceTheirChildrenInsideThemselves() throws {
        let design = try Probe.square(#"""
          {"type": "group", "frame": {"anchor": "top-left", "width": 0.5, "height": 0.5},
           "layers": [{"type": "shape", "shape": "rect", "fill": "#000000", "frame": {"anchor": "bottom-right", "width": 0.5, "height": 0.5}}]}
        """#)
        let placed = Layouter.place(design, geometry: design.canvas.geometry, families: [:])
        let group = try #require(placed.frames["0"]), child = try #require(placed.frames["0.0"])
        #expect(child.maxX == group.maxX && child.maxY == group.maxY && child.width == group.width / 2)
    }

    @Test func backgroundsReachTheBleed() throws {
        let design = try Probe.design(##"{"design": 1, "canvas": {"preset": "a5"}, "layers": [{"type": "background", "fill": "#FFFFFF"}, {"type": "shape", "shape": "rect"}]}"##)
        let placed = Layouter.place(design, geometry: design.canvas.geometry, families: [:])
        #expect(placed.frames["0"] == design.canvas.geometry.bleed)
        #expect(placed.frames["1"] == design.canvas.geometry.safe)
    }

    @Test func anAvoidingLayerMovesOffWhatItAvoids() throws {
        let design = try Probe.square(##"{"type": "text", "id": "t", "text": "Over the face", "size": 50, "frame": {"anchor": "top", "height": 0.3}, "avoid": ["faces"]}"##)
        let prepared = PreparedDesign(design: design, geometry: design.canvas.geometry, pictures: [:], families: [:], sources: [])
        let placed = Layouter.place(design, geometry: prepared.geometry, families: [:])
        let plan = Plan(frames: placed.frames, fits: placed.fits, text: [:])
        let face = CGRect(x: 0, y: 0, width: 400, height: 150)   // a face across the top
        let entry = Layouter.entries(design.layers)[0]
        let moved = try #require(Planner.move(entry, obstacles: [face], prepared: prepared, anchors: [:], plan: plan))
        #expect(moved.anchor == .bottom)
        #expect(Planner.move(entry, obstacles: [CGRect(x: 0, y: 300, width: 400, height: 100)], prepared: prepared, anchors: [:], plan: plan) == nil,
                "clear already: stays put")
    }
}
