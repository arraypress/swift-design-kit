//
//  Array+Safe.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
