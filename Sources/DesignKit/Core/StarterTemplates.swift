//
//  StarterTemplates.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The built-in templates, compiled in (no resource bundle to lose on the
//  way to a Homebrew install), checked as a catalogue: kebab-case names, no
//  name twice, every `{marker}` a slot and every slot used.
//

import Foundation
import RecipeKit

public enum StarterTemplates {

    /// Every built-in template.
    public static let all: [Template] = catalogue.templates

    /// What is wrong with the catalogue — empty when it is sound. A test holds it empty.
    public static var problems: [String] { catalogue.problems }

    /// The template called `name`.
    public static func named(_ name: String) -> Template? {
        all.first { $0.name == name.lowercased() }
    }

    /// Names close to `name`, for a refusal.
    public static func suggestions(for name: String) -> [String] {
        let names = all.map(\.name)
        return FieldPaths.closest(name, among: names).map { [$0] } ?? StyleCatalogs.suggestions(for: name, among: names)
    }

    static let catalogue: (templates: [Template], problems: [String]) = {
        let (templates, decodeProblems) = StyleCatalogs.decoded([covers, posters, social], as: Template.self, name: \.name)
        var problems = decodeProblems
        for template in templates {
            let markers = Set(markers(in: (try? JSONSerialization.jsonObject(with: template.layers)) ?? []))
            problems += StyleCatalogs.slotProblems(style: template.name, markers: markers, slots: template.slots.map(\.styleSlot))
            if Presets.named(template.preset) == nil { problems.append("\(template.name): no preset \(template.preset)") }
            do { _ = try Making.design(from: template, values: [:]) } catch {
                problems.append("\(template.name): \(error.localizedDescription)")
            }
        }
        return (templates, problems)
    }()

    /// Every `{marker}` in any string under `value`.
    static func markers(in value: Any) -> [String] {
        switch value {
        case let string as String: SlotFilling.markers(in: string)
        case let array as [Any]: array.flatMap(markers(in:))
        case let object as [String: Any]: object.values.flatMap(markers(in:))
        default: []
        }
    }
}
