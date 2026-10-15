//
//  Validation.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  What a type cannot say about a whole design: ids are unique, `below` and
//  `above` name an earlier layer, backgrounds are not inside groups.
//

import Foundation

enum Validation {

    static func check(_ design: Design) throws(DesignError) {
        var seen = Set<String>()
        for entry in Layouter.entries(design.layers) {
            let layer = entry.layer
            if let reference = layer.frame.below ?? layer.frame.above, !seen.contains(reference) {
                let word = layer.frame.below != nil ? "below" : "above"
                throw .invalid("layers.\(entry.path).frame.\(word) is \"\(reference)\", which is not an earlier layer's id"
                               + (seen.isEmpty ? "" : " (earlier: \(seen.sorted().joined(separator: ", ")))"))
            }
            if let id = layer.id {
                guard seen.insert(id).inserted else { throw .invalid("two layers have the id \"\(id)\"; ids are unique") }
            }
            if case .background = layer.content, entry.parent != nil {
                throw .invalid("layers.\(entry.path) is a background inside a group; backgrounds go at the top level")
            }
        }
        guard !design.layers.isEmpty else { throw .invalid("the design has no layers") }
    }
}
