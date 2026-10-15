//
//  DesignError.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why a design could not be made. The CLI maps each case to an exit code.
public enum DesignError: Error, Equatable, Sendable, LocalizedError {

    /// The design file or a value in it is wrong — the caller's to fix (usage).
    case invalid(String)

    /// A file, font, template or preset that is not there (not found).
    case missing(String)

    /// A model the design needs is not installed (not found), with how to get it.
    case modelMissing(String)

    /// Something underneath failed: a renderer, a model, a write (upstream).
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .invalid(let message), .missing(let message), .modelMissing(let message), .failed(let message): message
        }
    }
}
