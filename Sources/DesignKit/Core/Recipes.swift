//
//  Recipes.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A design as a recipe file — `"design": 1` — read strictly (an unknown key
//  is refused with the one it was likely meant to be), written pretty and
//  key-sorted, its paths kept relative to the file. And `--set`: one change
//  by a short name, the change checked by reading the whole design again.
//

import Foundation
import RecipeKit
import VideoGradeLook

public enum Recipes {

    /// The recipe format.
    public static let format = RecipeFormat(versionKey: "design", version: Design.formatVersion,
                                            rootKeys: Design.CodingKeys.allCases.map(\.rawValue), sections: [], suggests: true)

    /// A design from recipe JSON.
    public static func decoded(_ data: Data) throws(RecipeError) -> Design {
        try RecipeJSON.decoded(data, as: Design.self, format: format)
    }

    /// Recipe JSON for a design.
    public static func encoded(_ design: Design) throws(RecipeError) -> Data {
        try RecipeJSON.encoded(design)
    }

    /// The design in the recipe at `url`, its relative paths made absolute.
    public static func load(_ url: URL) throws(RecipeFileError) -> Design {
        let design = try RecipeFiles.load(url) { data in try decoded(data) }
        return relocated(design, from: url.deletingLastPathComponent(), to: nil)
    }

    /// Writes `design` to `url`, paths relative to its folder where they sit under it.
    /// `folder` is where the design's own relative paths are found.
    public static func save(_ design: Design, to url: URL, from folder: URL, overwrites: Bool) throws(RecipeFileError) {
        let absolute = relocated(design, from: folder, to: nil)
        try RecipeFiles.save(relocated(absolute, from: nil, to: url.deletingLastPathComponent()), to: url, overwrites: overwrites)
    }

    /// `design` with its absolute paths written relative to `folder` where they sit under it.
    public static func relative(_ design: Design, to folder: URL) -> Design {
        relocated(design, from: nil, to: folder)
    }

    /// Every file path in `design` (pictures, fonts, LUTs, look files) made
    /// absolute from `from`, then — with `to` — stored relative to it.
    static func relocated(_ design: Design, from: URL?, to: URL?) -> Design {
        func move(_ path: String) -> String {
            var full = path
            if let from { full = RecipePaths.usable(path, from: from) }
            if let to { full = RecipePaths.stored(full, from: to) }
            return full
        }
        func fix(_ layers: [Layer]) -> [Layer] {
            layers.map { layer in
                var layer = layer
                switch layer.content {
                case .background(var background):
                    if case .image(let path) = background.fill { background.fill = .image(path: move(path)) }
                    switch background.grade {
                    case .file(let path)?: background.grade = .file(move(path))
                    case .look(var look)?:
                        if let lut = look.lut { look.lut = move(lut) }
                        background.grade = .look(look)
                    case nil: break
                    }
                    layer.content = .background(background)
                case .image(var image):
                    image.source = move(image.source)
                    layer.content = .image(image)
                case .text(var text):
                    if let font = text.font, ["ttf", "otf", "ttc"].contains((font as NSString).pathExtension.lowercased()) {
                        text.font = move(font)
                    }
                    layer.content = .text(text)
                case .group(let children):
                    layer.content = .group(fix(children))
                case .shape, .qr, .texture:
                    break
                }
                return layer
            }
        }
        var design = design
        design.layers = fix(design.layers)
        return design
    }

    // MARK: --set

    /// `design` with one field changed: `title=Night Drive` (a slot's value),
    /// `background=imagine:rain on glass` (a layer by id: its fill, words or
    /// picture), `background.seed=8` (a field inside that layer, found by its
    /// last name), or a full dotted path (`canvas.width=2000`,
    /// `layers.2.opacity=0.8`). An empty value clears the field.
    public static func set(_ assignment: String, in design: Design) throws(RecipeError) -> Design {
        guard let pair = VarParsing.pair(assignment), !pair.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw RecipeError("--set takes field=value: title=\"Night Drive\", background.seed=8, canvas.width=2000")
        }
        let name = pair.name.trimmingCharacters(in: .whitespaces)
        // `pairing=swiss` changes the type: the faces pinned from the old pairing go.
        if ["pairing", "fonts.pairing"].contains(name.lowercased()) {
            let wanted = pair.value.trimmingCharacters(in: .whitespaces).lowercased()
            guard Pairings.named(wanted) != nil else { throw RecipeError(Pairings.refusal(wanted, at: name)) }
            var changed = design
            changed.fonts = Typesetting(pairing: wanted)
            return changed
        }
        let (path, kind) = try SetPaths.resolve(name, value: pair.value, in: design)
        return try FieldSetter.set(path, to: pair.value, kind: kind, in: design) { error in
            (error as? RecipeError) ?? RecipeError("\(name): \(error.localizedDescription)")
        }
    }
}
