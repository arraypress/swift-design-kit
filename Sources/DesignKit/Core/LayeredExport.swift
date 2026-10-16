//
//  LayeredExport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A design as a layered Photoshop file, written by swift-psd-kit: each
//  layer drawn alone at full size — its own pixels, its shadow, glow and
//  fade with it — and handed over with its name (its id), opacity and blend
//  mode; a group becomes a folder of its layers. Words are pixels: an
//  editable type layer needs Photoshop's text-engine data, which PSDKit
//  does not write. A group that casts a shadow or glows, or fades, is one
//  layer: drawn per child, its shadow would fall once per child.
//

import CoreGraphics
import Foundation
import PSDKit

public enum LayeredExport {

    /// What a layered file cannot carry as the design has it, said once per kind.
    public static func notes(_ prepared: PreparedDesign) -> [String] {
        var notes: [String] = []
        let entries = Layouter.entries(prepared.design.layers)
        if entries.contains(where: { if case .text = $0.layer.content { return true }; return false }) {
            notes.append("text layers are pixels in the PSD (PSDKit does not write editable type)")
        }
        if entries.contains(where: { if case .group = $0.layer.content { return flattened($0.layer) }; return false }) {
            notes.append("a group with a shadow, glow or fade is one layer in the PSD")
        }
        let differing = Set(entries.map(\.layer.blend)).intersection(photoshopDiffers).map(\.rawValue).sorted()
        if !differing.isEmpty {
            notes.append("Photoshop draws \(differing.joined(separator: ", ")) with its own arithmetic: those layers will look a little different there")
        }
        return notes
    }

    /// Modes whose arithmetic differs between CoreGraphics and Photoshop
    /// (soft light is Pegtop's curve in CoreGraphics; the dodges and burns
    /// apply opacity before clamping) — measured, see the README.
    static let photoshopDiffers: Set<BlendMode> = [.softLight, .colorDodge, .colorBurn, .linearDodge, .linearBurn]

    static func flattened(_ layer: Layer) -> Bool { layer.shadow != nil || layer.glow != nil || layer.fade != nil }

    /// The PSD's bytes.
    static func psd(_ rendered: Rendered) throws(DesignError) -> Data {
        let prepared = rendered.prepared
        let geometry = prepared.geometry
        let layers = prepared.design.layers.enumerated().compactMap { index, layer in
            psdLayer(layer, path: String(index), rendered: rendered)
        }
        do {
            return try PSDWriter.data(width: geometry.pixelWidth, height: geometry.pixelHeight, layers: layers,
                                      composite: rendered.image, dpi: geometry.dpi)
        } catch {
            throw .failed("the PSD could not be written: \(error.localizedDescription)")
        }
    }

    static func psdLayer(_ layer: Layer, path: String, rendered: Rendered) -> PSDWriteLayer? {
        let name = layer.id ?? "\(kind(layer)) \(path)"
        if case .group(let children) = layer.content, !flattened(layer) {
            let inner = children.enumerated().compactMap { index, child in
                psdLayer(child, path: "\(path).\(index)", rendered: rendered)
            }
            return PSDWriteLayer(name: name, content: .group(inner), opacity: layer.opacity, blendKey: layer.blend.psdKey)
        }
        var filter = Painter.Filter(only: path)
        filter.plain = true
        guard let image = Checker.render(rendered.prepared, plan: rendered.plan, scale: 1, filter: filter) else { return nil }
        return PSDWriteLayer(name: name, content: .pixels(image), opacity: layer.opacity, blendKey: layer.blend.psdKey)
    }

    static func kind(_ layer: Layer) -> String {
        switch layer.content {
        case .background: "background"
        case .text: "text"
        case .image: "image"
        case .shape: "shape"
        case .qr: "qr"
        case .texture: "texture"
        case .group: "group"
        case .list: "list"
        }
    }
}
