//
//  TemplateSlot+Recipe.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation
import RecipeKit

extension TemplateSlot {
    /// The slot as RecipeKit checks and fills it: any value goes.
    var styleSlot: StyleSlot {
        StyleSlot(name: name, defaultValue: defaultValue, known: [StyleSlot.Value(name: defaultValue)])
    }
}
