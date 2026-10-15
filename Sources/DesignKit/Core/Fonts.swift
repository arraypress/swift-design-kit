//
//  Fonts.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A text layer's `font` to a family CoreText can draw: an installed family
//  by name, one of the faces bundled with DocumentTheme (`inter`,
//  `source-serif`, `jetbrains-mono`), or a font file, registered for this
//  process. An unknown name is refused: CoreText would quietly substitute a
//  default face, and a cover set in the wrong typeface looks deliberate.
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

    /// Fonts already resolved this process, by what the design named.
    private static let registered = Mutex<[String: String]>([:])

    /// The family to draw `font` with (`nil` for the system face), files
    /// taken from `folder` when relative.
    public static func family(for font: String?, folder: URL) throws(DesignError) -> String? {
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
        } else {
            guard FontResolver.isAvailable(font) else {
                let close = FieldPaths.closest(font, among: installedFamilies())
                throw .missing("no font family \"\(font)\" on this machine" + (close.map { " — did you mean \($0)?" } ?? "")
                               + "; `design fonts` lists them, and a .ttf/.otf path works too")
            }
            family = font
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
}
