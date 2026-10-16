//
//  Fonts.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A text layer's `font` to a family CoreText can draw: a role (`display`,
//  `text`) through the design's pairing, any family installed on this Mac,
//  one of the faces bundled with DocumentTheme (`inter`, `source-serif`,
//  `jetbrains-mono`), an open font fetched on first use (`Playfair
//  Display`), or a font file — registered for this process. An unknown name
//  is refused: CoreText would quietly substitute a default face, and a cover
//  set in the wrong typeface looks deliberate.
//

import CanvasKit
import CoreText
import DocumentTheme
import Foundation
import RecipeKit
import Synchronization

public enum Fonts {

    /// The bundled families: the name a design uses and the files that make it.
    public static let bundled: [(name: String, family: String, files: [String])] = [
        ("inter", "Inter", ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold", "Inter-Italic"]),
        ("source-serif", "Source Serif 4", ["SourceSerif4-Regular", "SourceSerif4-Semibold", "SourceSerif4-Bold", "SourceSerif4-It"]),
        ("jetbrains-mono", "JetBrains Mono", ["JetBrainsMono-Regular", "JetBrainsMono-Medium", "JetBrainsMono-Bold"]),
    ]

    /// The words a text layer's `font` uses for the design's two faces.
    public static let roles = ["display", "text"]

    /// The weights a text layer may name, lightest first.
    public static let weights = ["thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"]

    /// Fonts already resolved this process, by what the design named.
    private static let registered = Mutex<[String: String]>([:])

    /// Families drawn from Google Fonts files fetched this process, and their font files.
    private static let fetchedFamilies = Mutex<[String: [URL]]>([:])

    /// Whether `family` (as CoreText reads it) was drawn from fetched Google Fonts files.
    static func isFetched(_ family: String) -> Bool { fetchedFamilies.withLock { $0[family] != nil } }

    /// The font files a fetched Google family was drawn from.
    static func fetchedFiles(_ family: String) -> [URL] { fetchedFamilies.withLock { $0[family] ?? [] } }

    /// Whether `name` can be drawn without fetching anything: bundled, or
    /// installed on this Mac.
    static func isLocal(_ name: String) -> Bool {
        bundled.contains { $0.name == name.lowercased() } || FontResolver.isAvailable(name)
    }

    /// The family to draw `font` with (`nil` for the system face), files
    /// taken from `folder` when relative, open fonts fetched with `fetcher`.
    public static func family(for font: String?, folder: URL, fetcher: (any FontFetching)? = nil) async throws(DesignError) -> String? {
        guard let font, !font.isEmpty, font.lowercased() != "system" else { return nil }
        if let known = registered.withLock({ $0[font] }) { return known }
        let family: String
        if let entry = bundled.first(where: { $0.name == font.lowercased() }) {
            for file in entry.files {
                guard let url = Typography.bundledFile(file) else {
                    throw .missing("the bundled font \(file).ttf is missing from this build")
                }
                register(url)
            }
            family = entry.family
        } else if ["ttf", "otf", "ttc"].contains((font as NSString).pathExtension.lowercased()) {
            let url = URL(fileURLWithPath: RecipePaths.usable(font, from: folder))
            guard FileManager.default.fileExists(atPath: url.path) else { throw .missing("no font file at \(url.path)") }
            guard let name = familyName(of: url) else { throw .invalid("\(url.lastPathComponent) is not a font CoreText can read") }
            register(url)
            family = name
        } else if FontResolver.isAvailable(font) {
            family = font
        } else if let open = OpenFonts.named(font) {
            let files: [URL]
            if let fetched = fetcher?.fetched(open) {
                files = fetched
            } else if let fetcher {
                files = try await fetcher.files(for: open)
            } else {
                throw .missing("\(open.family) is a Google font (\(open.licence)) fetched on first use, and nothing here can fetch it"
                               + " — `design` fetches it; or install it")
            }
            for url in files where ["ttf", "otf"].contains(url.pathExtension.lowercased()) { register(url) }
            // The name CoreText reads can differ from the Google Fonts name (`Fjord One` is `Fjord`).
            let drawn = files.lazy.filter { ["ttf", "otf"].contains($0.pathExtension.lowercased()) }.compactMap(familyName(of:)).first
                ?? open.drawnFamily
            guard FontResolver.isAvailable(drawn) else { throw .invalid("\(open.family) was fetched but CoreText cannot read it") }
            family = drawn
            let fonts = files.filter { ["ttf", "otf"].contains($0.pathExtension.lowercased()) }
            fetchedFamilies.withLock { $0[drawn] = fonts }
        } else {
            let close = FieldPaths.closest(font, among: installedFamilies() + OpenFonts.all.map(\.family))
            throw .missing("no font family \"\(font)\" on this machine or in Google Fonts" + (close.map { " — did you mean \($0)?" } ?? "")
                           + "; `design fonts` lists them (`--google NAME` searches all of Google Fonts), and a .ttf/.otf path works too")
        }
        registered.withLock { $0[font] = family }
        return family
    }

    /// Every family installed, sorted.
    public static func installedFamilies() -> [String] {
        (CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []).filter { !$0.hasPrefix(".") }.sorted()
    }

    /// The family a font file holds.
    static func familyName(of url: URL) -> String? {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let first = descriptors.first else { return nil }
        return CTFontDescriptorCopyAttribute(first, kCTFontFamilyNameAttribute) as? String
    }

    private static func register(_ url: URL) {
        var error: Unmanaged<CFError>?
        _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }

    /// Whether the face `family` draws at `weight` may be embedded in a PDF
    /// (its OS/2 embedding bits). The system face may.
    public static func embeddable(family: String?, weight: String) -> Bool {
        guard let family else { return true }
        return FontTraits.embeddable(FontResolver.font(family: family, weight: weight, size: 12))
    }

    // MARK: Roles and sizes

    /// The type a design is set in, with its faces chosen: the pairing's
    /// first candidate for each role that is here or can be fetched. Faces
    /// already pinned are kept.
    static func pinned(_ typesetting: Typesetting?, usesRoles: Bool, fetcher: (any FontFetching)?) throws(DesignError) -> Typesetting? {
        guard typesetting != nil || usesRoles else { return nil }
        var type = typesetting ?? Typesetting(pairing: Pairings.fallback)
        if type.display != nil && type.text != nil { return type }
        let name = type.pairing ?? Pairings.fallback
        guard let pairing = Pairings.named(name) else { throw .invalid(Pairings.refusal(name, at: "fonts.pairing")) }
        let fetched: (OpenFont) -> Bool = { fetcher?.fetched($0) != nil }
        if type.display == nil {
            guard let face = Pairings.pick(pairing.display, fetchable: fetcher != nil, fetched: fetched) else {
                throw .missing("no display face of the \(pairing.name) pairing is here: \(pairing.display.map(\.family).joined(separator: ", "))")
            }
            type.display = face
        }
        if type.text == nil {
            guard let face = Pairings.pick(pairing.text, fetchable: fetcher != nil, fetched: fetched) else {
                throw .missing("no text face of the \(pairing.name) pairing is here: \(pairing.text.map(\.family).joined(separator: ", "))")
            }
            type.text = face
        }
        type.pairing = pairing.name
        if type.scale == nil { type.scale = pairing.scale }
        if type.base == nil { type.base = pairing.base }
        return type
    }

    /// The faces a pairing resolves to here: the first candidate for each
    /// role that is installed, bundled, fetched — or, with a fetcher, can be.
    public static func resolve(_ typesetting: Typesetting, fetcher: (any FontFetching)?) throws(DesignError) -> Typesetting {
        try pinned(typesetting, usesRoles: true, fetcher: fetcher) ?? typesetting
    }

    /// The face, weight and size a text layer is drawn in.
    static func face(for text: TextContent, typesetting: Typesetting?, folder: URL,
                     fetcher: (any FontFetching)?) async throws(DesignError) -> ResolvedFace {
        var font = text.font
        var weight = text.weight
        if let role = font.map({ $0.lowercased() }), roles.contains(role) {
            guard let face = role == "display" ? typesetting?.display : typesetting?.text else {
                throw .invalid("a text layer names the \(role) face, and the design has no fonts section to say which it is")
            }
            font = face.family
            weight = weight ?? face.weight
        }
        let family = try await self.family(for: font, folder: folder, fetcher: fetcher)
        return ResolvedFace(family: family, weight: weight ?? "bold", size: size(of: text, typesetting: typesetting))
    }

    /// A text layer's size in design units: its number, or its named step on the design's scale.
    static func size(of text: TextContent, typesetting: Typesetting?) -> Double {
        guard let step = text.step else { return text.size }
        return step.size(scale: typesetting?.scale ?? 1.5, base: typesetting?.base ?? 30)
    }
}
