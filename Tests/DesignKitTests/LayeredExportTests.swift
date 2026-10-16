//
//  LayeredExportTests.swift
//  DesignKitTests
//
//  A design written as a layered PSD and read back by PSDKit: a layer per
//  design layer, names kept, groups as folders, blend modes and opacity
//  mapped, and PSDKit's own flattening of the layers against the design's
//  picture — measured, not assumed.
//

import CoreGraphics
import Foundation
import Legibility
import PSDKit
import Testing
@testable import DesignKit

struct LayeredExportTests {

    /// Mean and 99th-percentile channel difference between two same-size pictures.
    static func difference(_ a: CGImage, _ b: CGImage) -> (mean: Double, p99: Int) {
        let pa = Pixels.rgba(of: a)!, pb = Pixels.rgba(of: b)!
        var histogram = [Int](repeating: 0, count: 256)
        var total = 0
        for i in 0..<min(pa.count, pb.count) where i % 4 != 3 {
            let d = abs(Int(pa[i]) - Int(pb[i]))
            histogram[d] += 1
            total += d
        }
        let count = histogram.reduce(0, +)
        var seen = 0, p99 = 0
        for (value, n) in histogram.enumerated() { seen += n; if Double(seen) >= Double(count) * 0.99 { p99 = value; break } }
        return (Double(total) / Double(count), p99)
    }

    @Test func aDesignBecomesALayeredPSD() async throws {
        let rendered = try await Probe.render(Probe.square(##"""
        {"type": "background", "id": "background", "fill": "linear:#203A5C,#C86B3C,angle=135"},
        {"type": "texture", "id": "grain", "kind": "noise", "color": "#FFFFFF", "density": 0.4, "blend": "screen", "opacity": 0.3},
        {"type": "group", "id": "label", "opacity": 0.9, "frame": {"width": 0.8, "height": 0.3},
         "layers": [{"type": "shape", "id": "strip", "shape": "rect", "fill": "#F2EEE6"},
                    {"type": "text", "id": "title", "text": "Layers", "font": "inter", "color": "#111111", "frame": {"width": 0.8, "height": 0.7}}]},
        {"type": "shape", "id": "sun", "shape": "ellipse", "fill": "#FFC24B", "blend": "multiply", "frame": {"anchor": "top-right", "width": 0.3, "aspect": 1}},
        {"type": "shape", "id": "flare", "shape": "rect", "fill": "#FFFFFF", "blend": "overlay", "opacity": 0.5,
         "fade": {"edge": "bottom"}, "frame": {"area": "bleed"}}
        """##, size: 400))
        let url = Probe.folder.appendingPathComponent("layers.psd")
        try Exporter.write(rendered, to: url, format: .psd)
        let document = try PSDDocument(contentsOf: url)
        let layers = document.layers
        #expect(layers.map(\.name) == ["flare", "sun", "label", "title", "strip", "grain", "background"])
        #expect(layers.first { $0.name == "title" }?.groups == ["label"], "a group is a folder")
        #expect(layers.first { $0.name == "label" }?.kind == .group && layers.first { $0.name == "label" }?.opacity == 90)
        #expect(layers.first { $0.name == "sun" }?.blendMode == "mul ")
        #expect(layers.first { $0.name == "flare" }?.blendMode == "over" && layers.first { $0.name == "flare" }?.opacity == 50)
        #expect(layers.first { $0.name == "grain" }?.blendMode == "scrn")
        #expect(LayeredExport.notes(rendered.prepared).contains { $0.contains("text layers are pixels") })

        // PSDKit's flattening of the layers against the design's own picture.
        let (flat, skipped) = try document.renderedComposite()
        #expect(skipped.isEmpty, "\(skipped)")
        let difference = Self.difference(flat, rendered.image)
        #expect(difference.mean < 0.6 && difference.p99 <= 2, "mean \(difference.mean), p99 \(difference.p99)")
    }
}
