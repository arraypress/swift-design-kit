//
//  GradeLookCoding.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A look inline in a design, read with the same strict rules a look file
//  is (VideoGradeLook): the shape img and vid write.
//

import Foundation
import RecipeKit
import VideoGradeLook

enum GradeLookCoding {

    /// The look at the decoder's position, strictly.
    static func decode(from decoder: any Decoder) throws -> GradeLook {
        let path = RecipeJSON.path(decoder.codingPath)
        let object = try decoder.singleValueContainer().decode(AnyJSON.self).value
        let data: Data
        do { data = try JSONSerialization.data(withJSONObject: object) } catch {
            throw RecipeError("\(path) is not a look: \(error.localizedDescription)")
        }
        do {
            // Relative LUT paths stay as written here; the design's folder resolves them later.
            var look = try LookFile.decoded(data, folder: URL(fileURLWithPath: "/"))
            if let original = (object as? [String: Any])?["lut"] as? String { look.lut = original }
            return look
        } catch {
            throw RecipeError("\(path): \(error.message.replacingOccurrences(of: "grade.", with: path + "."))")
        }
    }
}
