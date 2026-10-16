//
//  Moves.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  A text layer moved by `avoid`. Alignment that hugged the declared anchor
//  follows the new one — a title set left at top-left is set right at
//  top-right — because a full-width frame moved to the other side changes
//  nothing unless its lines move with it. Alignment that did not match its
//  anchor was a choice, and is kept.
//

import Foundation

enum Moves {

    /// The move to `anchor` at `width` of the declared frame.
    static func move(_ text: TextContent, declared: Anchor, to anchor: Anchor, width: Double) -> TextMove {
        TextMove(anchor: anchor, width: width,
                 align: align(text.align, from: declared, to: anchor), valign: valign(text.valign, from: declared, to: anchor))
    }

    /// `layer` as moved: its frame on the new anchor and width, its words aligned to it.
    static func applied(_ move: TextMove, to layer: Layer) -> Layer {
        var moved = layer
        moved.frame.anchor = move.anchor
        moved.frame.width *= move.width
        if case .text(let text) = layer.content { moved.content = .text(applied(move, to: text)) }
        return moved
    }

    /// `text` aligned as moved.
    static func applied(_ move: TextMove, to text: TextContent) -> TextContent {
        var moved = text
        moved.align = move.align
        moved.valign = move.valign
        return moved
    }

    // MARK: Alignment

    /// Lines aligned to the declared anchor's side follow the anchor to its new side.
    static func align(_ align: TextAlign, from: Anchor, to anchor: Anchor) -> TextAlign {
        let sides: [TextAlign] = [.left, .center, .right]
        guard align == sides[side(from.horizontal)] else { return align }
        return sides[side(anchor.horizontal)]
    }

    /// The block placed at the declared anchor's edge follows the anchor to its new edge.
    static func valign(_ valign: VerticalAlign, from: Anchor, to anchor: Anchor) -> VerticalAlign {
        let edges: [VerticalAlign] = [.top, .middle, .bottom]
        guard valign == edges[side(from.vertical)] else { return valign }
        return edges[side(anchor.vertical)]
    }

    /// `0`, `0.5` or `1` as an index.
    static func side(_ fraction: Double) -> Int { Int((fraction * 2).rounded()) }
}
