//
//  OpenFont+IndexLine.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

extension OpenFont {

    /// One line of the index: name, folder, licence folder, category, axes, files, CoreText's name.
    init?(indexLine line: Substring) {
        let fields = line.trimmingCharacters(in: .whitespaces).split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 6, let category = FontCategory(rawValue: fields[3]) else { return nil }
        let axes = fields[4].split(separator: ",").compactMap { part -> Axis? in
            let bits = part.split(separator: ":")
            guard bits.count == 3, let low = Double(bits[1]), let high = Double(bits[2]) else { return nil }
            return Axis(tag: String(bits[0]), minimum: low, maximum: high)
        }
        let files = fields[5].split(separator: ";").compactMap { part -> File? in
            let bits = part.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            guard bits.count >= 3, let bytes = Int(bits[2]) else { return nil }
            return File(name: bits[0], sha256: bits[1], bytes: bytes,
                        italic: bits.count >= 5 ? bits[3] == "i" : nil, weight: bits.count >= 5 ? Int(bits[4]) : nil)
        }
        guard !files.isEmpty else { return nil }
        let drawn = fields.count >= 7 && !fields[6].isEmpty ? fields[6] : fields[0]
        self.init(family: fields[0], drawnFamily: drawn, folder: fields[1], licenceFolder: fields[2], category: category,
                  axes: axes, files: files)
    }
}
