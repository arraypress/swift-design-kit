//
//  VectorExport.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The design as SVG: shapes as paths, words as text a person can still
//  edit (each line and run where CoreText set it, in its face, size, weight
//  and colour), pictures embedded as PNG. What SVG cannot say is said in
//  pixels or approximated: backgrounds, pictures, textures and codes are
//  embedded pictures of the layer as drawn; words on a path, extruded or
//  inlined become outlines; a group with a shadow, glow or fade is one
//  picture; linear dodge and burn have no SVG blend and draw normally.
//  Google faces are embedded (@font-face; their licences allow it); a
//  Mac's own faces are named only, and a viewer without one substitutes.
//

import CanvasKit
import CoreGraphics
import Foundation
import Legibility

/// A finished design written as SVG: shapes as paths, words as text, pictures embedded.
public enum VectorExport {

    /// What an SVG keeps and loses, for the notes `design` prints.
    public static func notes(_ prepared: PreparedDesign) -> [String] {
        var notes = ["Google faces are embedded; this Mac's own faces are named only, and a viewer without one substitutes another"]
        let entries = Layouter.entries(prepared.design.layers)
        if entries.contains(where: { if case .text(let text) = $0.layer.content { return text.path != nil || text.extrude != nil || text.inline != nil }; return false }) {
            notes.append("words on a path, extruded or inlined are outlines in the SVG, not text")
        }
        if entries.contains(where: { [.linearBurn, .linearDodge].contains($0.layer.blend) }) {
            notes.append("linear dodge and linear burn have no SVG blend mode: those layers draw normally")
        }
        if entries.contains(where: { if case .group = $0.layer.content { return LayeredExport.flattened($0.layer) }; return false }) {
            notes.append("a group with a shadow, glow or fade is one picture in the SVG")
        }
        return notes
    }

    /// The SVG's bytes.
    static func svg(_ rendered: Rendered) throws(DesignError) -> Data {
        var writer = SVGWriter(rendered: rendered)
        for (index, layer) in rendered.prepared.design.layers.enumerated() {
            writer.body.append(writer.element(layer, path: String(index), turns: []))
        }
        let geometry = rendered.prepared.geometry
        let width = geometry.pixelWidth, height = geometry.pixelHeight
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)">

        """
        // Google faces travel with the file (their licences allow embedding); a Mac's own faces are only named.
        let embedded = Set(rendered.prepared.faces.values.compactMap(\.family)).filter(Fonts.isFetched).sorted()
        var faces: [String] = []
        for family in embedded {
            for file in Fonts.fetchedFiles(family) {
                guard let data = try? Data(contentsOf: file) else { continue }
                let italic = file.lastPathComponent.lowercased().contains("italic")
                let format = file.pathExtension.lowercased() == "otf" ? "opentype" : "truetype"
                faces.append("@font-face{font-family:'\(SVGWriter.escape(family))';font-style:\(italic ? "italic" : "normal");"
                             + "src:url(data:font/\(file.pathExtension.lowercased());base64,\(data.base64EncodedString())) format('\(format)');}")
            }
        }
        if !faces.isEmpty { writer.defs.insert("<style>\(faces.joined(separator: "\n"))</style>", at: 0) }
        if !writer.defs.isEmpty { svg += "<defs>\n" + writer.defs.joined(separator: "\n") + "\n</defs>\n" }
        svg += writer.body.filter { !$0.isEmpty }.joined(separator: "\n") + "\n</svg>\n"
        return Data(svg.utf8)
    }
}
