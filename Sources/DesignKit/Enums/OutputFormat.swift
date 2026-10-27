//
//  OutputFormat.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import UniformTypeIdentifiers

/// The file a finished design is written as.
public enum OutputFormat: String, DesignChoice {
    /// PNG, lossless; no metadata, so the same design writes the same bytes.
    case png
    /// JPEG; no metadata.
    case jpeg
    /// PDF, words kept as vector text; for print, with bleed and crop marks.
    case pdf
    /// Layered Photoshop: one layer per design layer.
    case psd
    /// Vector: shapes and words as SVG, pictures embedded.
    case svg

    /// The format a file name asks for.
    public static func of(_ url: URL) -> OutputFormat? {
        switch url.pathExtension.lowercased() {
        case "png": .png
        case "jpg", "jpeg": .jpeg
        case "pdf": .pdf
        case "psd": .psd
        case "svg": .svg
        default: nil
        }
    }
}
