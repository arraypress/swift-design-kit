//
//  Making.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A template and its slot values to a design. Words keep their `{slot}`
//  markers (the design's vars fill them when drawn, so `--set title=…`
//  changes them on a replay); every other marker — a background, a colour,
//  a link — is filled now, and then the layers are read strictly.
//

import Foundation
import RecipeKit

public enum Making {

    /// The design `template` makes with `values` (slot name → value), on
    /// `canvas` or the template's own preset.
    public static func design(from template: Template, values: [String: String],
                              canvas: CanvasSpec? = nil, pairing: String? = nil, harmony: Harmony? = nil) throws(DesignError) -> Design {
        let vars: [String: String]
        do {
            vars = try SlotFilling.resolved(values, for: template.slots.map(\.styleSlot), style: template.name)
        } catch {
            throw .invalid(error.errorDescription ?? "\(error)")
        }
        let raw: Any
        do { raw = try JSONSerialization.jsonObject(with: template.layers) } catch {
            throw .invalid("template \(template.name) is not JSON: \(error.localizedDescription)")
        }
        let filled = fill(raw, vars: vars, keepWords: false)
        let layers: [Layer]
        do {
            let data = try JSONSerialization.data(withJSONObject: filled, options: [.sortedKeys])
            layers = try JSONDecoder().decode([Layer].self, from: data)
        } catch let error as RecipeError {
            throw .invalid("template \(template.name) with these values: \(error.message.replacingOccurrences(of: "layers.", with: "layer "))")
        } catch {
            throw .invalid("template \(template.name) with these values: \(error.localizedDescription)")
        }
        guard let canvas = canvas ?? Presets.named(template.preset).map(CanvasSpec.init(preset:)) else {
            throw .invalid("template \(template.name) names a preset that does not exist: \(template.preset)")
        }
        if let pairing, Pairings.named(pairing) == nil { throw .invalid(Pairings.refusal(pairing, at: "--pairing")) }
        let chosen = pairing ?? template.pairing
        var palette = template.palette
        if let harmony { palette = PaletteSpec(harmony: harmony, fixed: palette?.fixed ?? [:]) }
        return Design(canvas: canvas, template: template.name, vars: vars, grid: template.grid,
                      fonts: chosen.map { Typesetting(pairing: $0.lowercased()) }, palette: palette, layers: layers)
    }

    /// `value` with every marker in its strings filled — except a text or
    /// QR layer's own `text`, which keeps its markers for the vars.
    static func fill(_ value: Any, vars: [String: String], keepWords: Bool) -> Any {
        switch value {
        case let string as String:
            return keepWords ? string : Words.filled(string, vars: vars)
        case let array as [Any]:
            return array.map { fill($0, vars: vars, keepWords: false) }
        case let object as [String: Any]:
            let type = object["type"] as? String
            var result: [String: Any] = [:]
            for (key, item) in object {
                let words = key == "text" && (type == "text" || type == "qr")
                result[key] = fill(item, vars: vars, keepWords: words)
            }
            return result
        default:
            return value
        }
    }
}

extension TemplateSlot {
    /// The slot as RecipeKit checks and fills it: any value goes.
    var styleSlot: StyleSlot {
        StyleSlot(name: name, defaultValue: defaultValue, known: [StyleSlot.Value(name: defaultValue)])
    }
}
