//
//  CarouselTemplates.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

/// The built-in starter carousels.
public enum CarouselTemplates {

    /// Every starter carousel, in catalogue order.
    public static let all: [CarouselTemplate] = catalogue

    /// The starter carousel called `name` (case ignored), or `nil`.
    public static func named(_ name: String) -> CarouselTemplate? { all.first { $0.name == name.lowercased() } }

    static let catalogue: [CarouselTemplate] = {
        do { return try JSONDecoder().decode([CarouselTemplate].self, from: Data(json.utf8)) } catch {
            preconditionFailure("the carousel catalogue does not read: \(error)")
        }
    }()
}
