//
//  SetPaths.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A `--set` name to the JSON path it changes, and how its value is read.
//

import Foundation
import RecipeKit

enum SetPaths {

    /// The JSON path `name` stands for in `design`, and the kind of value it takes.
    static func resolve(_ name: String, value: String, in design: Design) throws(RecipeError) -> (String, FieldKind) {
        let object = try json(design)
        let parts = name.split(separator: ".", maxSplits: 1).map(String.init)

        // A slot whose value the words still read (a background's slot was
        // spent when the design was made: setting it means the layer).
        let slot = name.lowercased()
        if parts.count == 1, design.vars[slot] != nil,
           wordMarkers(design.layers).contains(slot) || layerPath(id: name, in: design.layers) == nil {
            return ("vars.\(slot)", .text)
        }
        // A layer by its id.
        if let layer = layerPath(id: parts[0], in: design.layers) {
            guard parts.count == 2 else { return try whole(layer, object: object) }
            let rest = parts[1]
            let leaves = leafPaths(at: layer, in: object)
            if let exact = leaves.first(where: { $0 == "\(layer).\(rest)" }) { return (exact, kind(at: exact, in: object, value: value)) }
            let suffixed = leaves.filter { $0.hasSuffix(".\(rest)") }
            if suffixed.count == 1 { return (suffixed[0], kind(at: suffixed[0], in: object, value: value)) }
            if suffixed.count > 1 {
                throw RecipeError("\(name) could be \(suffixed.map { $0.replacingOccurrences(of: layer, with: parts[0]) }.joined(separator: " or ")); say which")
            }
            // Not written yet: a fill's field for a background, else the layer's own key.
            let type = (lookup(at: layer, in: object) as? [String: Any])?["type"] as? String
            let target = type == "background" && fillKeys.contains(rest) ? "\(layer).fill.\(rest)" : "\(layer).\(rest)"
            return (target, .custom(loose))
        }
        // A full dotted path.
        let leaves = leafPaths(at: "", in: object)
        if leaves.contains(name) || lookup(at: name, in: object) != nil { return (name, kind(at: name, in: object, value: value)) }
        if parts.count == 1, !name.contains(".") {
            let known = design.vars.keys.sorted() + ids(design.layers)
            let close = FieldPaths.closest(name, among: known)
            throw RecipeError("\(name) is not a slot or a layer id" + (close.map { " — did you mean \($0)?" }
                              ?? (known.isEmpty ? "" : " (\(known.joined(separator: ", ")))")))
        }
        return (name, .custom(loose))
    }

    /// Every `{marker}` a text or QR layer's words hold.
    static func wordMarkers(_ layers: [Layer]) -> Set<String> {
        Set(layers.flatMap { layer -> [String] in
            switch layer.content {
            case .text(let text): SlotFilling.markers(in: text.text)
            case .qr(let qr): SlotFilling.markers(in: qr.text)
            case .group(let children): Array(wordMarkers(children))
            case .list(let list): if case .text(let words) = list.items { SlotFilling.markers(in: words) } else { [] }
            default: []
            }
        })
    }

    static let fillKeys = ["seed", "prompt", "model", "revision", "aspect", "steps", "style", "palette", "motif",
                           "colors", "angle", "color", "path", "kind"]

    /// Setting a layer by id alone: a background's fill (shorthand), a text's
    /// words, a picture's file, a QR code's text.
    static func whole(_ layer: String, object: [String: Any]) throws(RecipeError) -> (String, FieldKind) {
        switch (lookup(at: layer, in: object) as? [String: Any])?["type"] as? String {
        case "background":
            return ("\(layer).fill", .custom { text, name throws(RecipeError) in
                let data = try RecipeJSON.encoded(FillShorthand.parse(text, field: name))
                do { return try JSONSerialization.jsonObject(with: data) } catch { throw RecipeError("\(name): \(error.localizedDescription)") }
            })
        case "image": return ("\(layer).source", .text)
        case "text", "qr": return ("\(layer).text", .text)
        case "list": return ("\(layer).items", .text)
        default: throw RecipeError("that layer is a group or a shape; set one of its fields (\(layer).opacity=0.5)")
        }
    }

    /// The JSON path of the layer with `id`, searching groups.
    static func layerPath(id: String, in layers: [Layer], prefix: String = "layers") -> String? {
        for (index, layer) in layers.enumerated() {
            let path = "\(prefix).\(index)"
            if layer.id == id { return path }
            if case .group(let children) = layer.content, let found = layerPath(id: id, in: children, prefix: "\(path).layers") {
                return found
            }
        }
        return nil
    }

    static func ids(_ layers: [Layer]) -> [String] {
        layers.flatMap { layer -> [String] in
            var found = layer.id.map { [$0] } ?? []
            if case .group(let children) = layer.content { found += ids(children) }
            return found
        }
    }

    static func json(_ design: Design) throws(RecipeError) -> [String: Any] {
        do {
            return try JSONSerialization.jsonObject(with: JSONEncoder().encode(design)) as? [String: Any] ?? [:]
        } catch { throw RecipeError("cannot read the design: \(error.localizedDescription)") }
    }

    /// The value at a dotted path (array items by index).
    static func lookup(at path: String, in root: Any) -> Any? {
        var current: Any? = root
        for key in path.split(separator: ".").map(String.init) where !key.isEmpty {
            if let array = current as? [Any], let index = Int(key) { current = array.indices.contains(index) ? array[index] : nil }
            else { current = (current as? [String: Any])?[key] }
        }
        return current
    }

    /// Every leaf (non-object) path under `path`.
    static func leafPaths(at path: String, in root: [String: Any]) -> [String] {
        func walk(_ value: Any, _ prefix: String) -> [String] {
            if let object = value as? [String: Any] {
                return object.keys.sorted().flatMap { walk(object[$0]!, prefix.isEmpty ? $0 : "\(prefix).\($0)") }
            }
            if let array = value as? [Any], array.contains(where: { $0 is [String: Any] }) {
                return array.enumerated().flatMap { walk($0.element, "\(prefix).\($0.offset)") }
            }
            return [prefix]
        }
        guard let start = path.isEmpty ? root : lookup(at: path, in: root) else { return [] }
        return walk(start, path)
    }

    /// How to read a value for the field at `path`: as text where the field holds text, else as JSON.
    static func kind(at path: String, in root: [String: Any], value: String) -> FieldKind {
        lookup(at: path, in: root) is String ? .text : .custom(loose)
    }

    /// JSON when the text is JSON (`8`, `true`, `[0.5, 0.3]`), else the text itself.
    @Sendable static func loose(_ text: String, _ name: String) throws(RecipeError) -> Any {
        if let parsed = try? JSONSerialization.jsonObject(with: Data(text.utf8), options: .fragmentsAllowed) { return parsed }
        return text
    }
}
