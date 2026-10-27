//
//  Critic.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A verdict on a finished design in one line, for an agent choosing
//  between drafts: the blind checks summarised (contrast, read-back, fit,
//  words on the subject, faces and colours counted) and three layout
//  measures taken from where the ink of the words landed — whether each
//  block lines up with another or with the page, whether the margins round
//  the words are even, and whether the title is a clear step above the
//  rest. Accents — words turned on their own, words on a small shape (a
//  burst, a tag), one- or two-character ornaments — are left out of the
//  layout measures: they are their own unit. A failed check blocks; the
//  layout measures only warn. Thresholds were set on the 17 starter
//  templates, each reviewed by eye: all 17 pass every measure.
//

import CoreGraphics
import Foundation

/// A one-line verdict on a finished design, for choosing between drafts.
public enum Critic {

    /// Edges within this share of the page's width count as lined up.
    public static let alignTolerance = 0.015

    /// A centred design whose side margins differ by more than this ratio (smaller over larger) reads off-centre.
    public static let marginBalance = 0.5

    /// The title should be at least this many times the next size down.
    public static let hierarchyStep = 1.5

    /// `rendered` judged: the checks summarised and the layout measured, under `name`.
    public static func critique(_ rendered: Rendered, name: String) -> Critique {
        let report = rendered.report
        let geometry = rendered.prepared.geometry
        let trim = geometry.trim
        var notes: [String] = []
        var findings = report.findings

        // The checks, summarised.
        let blocking = !report.passed
        let failures = report.findings.filter { $0.level == .fail }
        let contrasts = report.text.compactMap { measure in measure.contrast.map { ($0, measure) } }
        let weakest = contrasts.min { $0.0 / $0.1.contrastNeeded < $1.0 / $1.1.contrastNeeded }
        let reads = report.text.compactMap(\.readBack)
        let onSubject = report.text.compactMap(\.onSubject).max() ?? 0

        // The words' ink, top-level text and list lines alike. Accents are set apart: words turned on
        // their own (a tilted badge), words sitting on a small shape (a burst, a tag) and one- or
        // two-character ornaments (a quotation mark) belong to their own unit, not the page's grid.
        let entries = Layouter.entries(rendered.prepared.design.layers)
        let frames = rendered.plan.frames
        let page = trim.width * trim.height
        let small = entries.compactMap { entry -> (path: String, frame: CGRect)? in
            guard case .shape = entry.layer.content, let frame = frames[entry.path], frame.width * frame.height < 0.15 * page else { return nil }
            return (entry.path, frame)
        }
        var blocks: [(id: String, ink: CGRect, size: Double, align: TextAlign, set: CGRect)] = []
        var accents: [(id: String, size: Double)] = []
        for measure in report.text {
            guard let ink = measure.ink, ink.count == 4, ink[2] > 0 else { continue }
            let rect = CGRect(x: ink[0], y: ink[1], width: ink[2], height: ink[3])
            let id = measure.id ?? measure.layer
            let turned = turned(measure.layer, entries: entries)
            let onShape = small.contains { shape in
                Painter.drawn(shape.path, before: measure.layer) && {
                    let shared = shape.frame.intersection(rect)
                    return !shared.isNull && shared.width * shared.height >= 0.9 * rect.width * rect.height
                }()
            }
            let ornament = measure.words.filter { !$0.isWhitespace }.count <= 2
            if turned || onShape || ornament {
                accents.append((id, measure.sizeUnits))
            } else {
                // Where the words are set: the frame (moved where `avoid` put it), whose edge the alignment holds —
                // large type's side bearings keep its ink off that edge.
                let set = rendered.plan.text[measure.layer]?.move == nil ? frames[measure.layer] ?? rect : rect
                blocks.append((id, rect, measure.sizeUnits, alignment(of: measure.layer, in: rendered.prepared.design), set))
            }
        }
        _ = accents

        // Alignment: each block shares an edge (left, centre, right) with another block, the page's centre, or the safe area's sides.
        let tolerance = alignTolerance * trim.width
        var loose: [String] = []
        for (index, block) in blocks.enumerated() {
            let others = blocks.enumerated().filter { $0.offset != index }.map(\.element.ink)
            let lefts = others.map(\.minX) + [geometry.safe.minX, trim.minX]
            let rights = others.map(\.maxX) + [geometry.safe.maxX, trim.maxX]
            let centres = others.map(\.midX) + [trim.midX]
            let near = { (value: CGFloat, targets: [CGFloat]) in targets.contains { abs($0 - value) <= tolerance } }
            let setLefts = blocks.enumerated().filter { $0.offset != index }.map(\.element.set.minX) + lefts
            let setRights = blocks.enumerated().filter { $0.offset != index }.map(\.element.set.maxX) + rights
            let setCentres = blocks.enumerated().filter { $0.offset != index }.map(\.element.set.midX) + centres
            let byInk = near(block.ink.minX, lefts) || near(block.ink.midX, centres) || near(block.ink.maxX, rights)
            let bySetting = switch block.align {
            case .left: near(block.set.minX, setLefts)
            case .right: near(block.set.maxX, setRights)
            case .center: near(block.set.midX, setCentres)
            }
            if !(byInk || bySetting) { loose.append(block.id) }
        }
        let aligned = loose.isEmpty
        if !aligned {
            findings.append(Finding(check: "alignment", level: .warn,
                                    message: "\(loose.joined(separator: ", ")) line\(loose.count == 1 ? "s" : "") up with nothing: no edge or centre shared with another block or the page",
                                    fix: "the same anchor and align as a neighbour, or a column span"))
        }

        // Margins: the space round all the words, side to side when the words are centred.
        var margins = Margins(left: 0, right: 0, top: 0, bottom: 0, balanced: true)
        if let all = blocks.map(\.ink).reduce(nil, { ($0 ?? $1).union($1) }) as CGRect? {
            margins = Margins(left: round3((all.minX - trim.minX) / trim.width), right: round3((trim.maxX - all.maxX) / trim.width),
                              top: round3((all.minY - trim.minY) / trim.height), bottom: round3((trim.maxY - all.maxY) / trim.height),
                              balanced: true)
            let centred = blocks.filter { $0.align == .center }.count * 2 > blocks.count
            if centred, max(margins.left, margins.right) > 0 {
                let ratio = min(margins.left, margins.right) / max(margins.left, margins.right)
                margins.balanced = ratio >= marginBalance
                if !margins.balanced {
                    findings.append(Finding(check: "margins", level: .warn,
                                            message: "the centred words sit off-centre: \(percent(margins.left)) of the page on the left, \(percent(margins.right)) on the right",
                                            fix: "anchor the blocks to the centre, or set them left on purpose (\"align\": \"left\")"))
                }
            }
        }

        // Hierarchy: the title against the next size down (sizes within 5% are one size).
        var sizes: [Double] = []
        for size in blocks.map(\.size).sorted(by: >) where !sizes.contains(where: { abs($0 - size) / $0 < 0.05 }) { sizes.append(size) }
        let step = sizes.count >= 2 ? sizes[0] / sizes[1] : nil
        let hierarchy = step.map { $0 >= hierarchyStep } ?? true
        if let step, !hierarchy {
            findings.append(Finding(check: "hierarchy", level: .warn,
                                    message: "the largest words are only \(String(format: "%.2f", step))× the next size: no clear title",
                                    fix: "the title at least \(hierarchyStep)× the next size, or the rest smaller"))
        }

        // The line.
        var parts: [String] = []
        if let failure = failures.first {
            parts.append("\(failure.check): \(failure.message)" + (failures.count > 1 ? " (+\(failures.count - 1) more)" : ""))
        }
        if let weakest { parts.append("contrast ≥ \(String(format: "%.1f", weakest.0)):1") }
        if !reads.isEmpty { parts.append("read-back \(Int(((reads.min() ?? 1) * 100).rounded()))%") }
        if onSubject > 0.02 { parts.append("\(Int((onSubject * 100).rounded()))% on the subject") }
        parts.append(step.map { "hierarchy \(String(format: "%.1f", $0))×\(hierarchy ? "" : " (flat)")" } ?? "one size")
        parts.append(aligned ? "aligned" : "\(loose.count) loose")
        parts.append(margins.balanced ? "margins even" : "off-centre")
        parts.append("\(report.fonts.count) face\(report.fonts.count == 1 ? "" : "s"), \(report.colors.count) colour\(report.colors.count == 1 ? "" : "s")")
        let warnings = findings.filter { $0.level == .warn }.count
        let mark = blocking ? "✗ blocking" : warnings > 0 ? "! good, with \(warnings) warning\(warnings == 1 ? "" : "s")" : "✓ good"
        notes = parts
        return Critique(design: name, verdict: "\(name): \(mark) — " + notes.joined(separator: "; "), blocking: blocking,
                        contrast: weakest.map { round3($0.0) }, readBack: reads.min(), onSubject: round3(onSubject),
                        fits: report.text.allSatisfy(\.fits), faces: report.fonts.count, colors: report.colors.count,
                        aligned: aligned, loose: loose, margins: margins, hierarchy: step.map(round3), findings: findings)
    }

    /// Whether the layer at `path`, or a group it is in, is turned.
    static func turned(_ path: String, entries: [Layouter.Entry]) -> Bool {
        entries.contains { entry in
            entry.layer.rotation != 0 && (entry.path == path || path.hasPrefix(entry.path + "."))
        }
    }

    /// The `align` of the text layer at `path`.
    static func alignment(of path: String, in design: Design) -> TextAlign {
        for entry in Layouter.entries(design.layers) where entry.path == path {
            if case .text(let text) = entry.layer.content { return text.align }
        }
        return .center
    }

    static func round3(_ value: Double) -> Double { (value * 1000).rounded() / 1000 }

    static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
}
