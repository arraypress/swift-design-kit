//
//  ListFlow.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How a list's items run: on together in lines, or one a line.
public enum ListFlow: String, DesignChoice {
    /// Items run on with separators, lines balanced: a line-up.
    case inline
    /// One item a line, in columns: a tracklist, credits.
    case lines
}
