//
//  PosterTemplates.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Print: flyers and posters, 300 dpi with bleed and crop marks. Names,
//  places and links are invented; example.com links stand in for real ones.
//

extension StarterTemplates {

    static let posters = #"""
    [
      {
        "name": "event-flyer",
        "summary": "A5 event flyer: the event in a big serif, date on a tab, details, venue, and a QR code to the page",
        "preset": "a5",
        "slots": [
          {"name": "event", "summary": "what is on", "default": "Riverside Night Market"},
          {"name": "date", "summary": "when", "default": "Saturday 14 June · 5–11 pm"},
          {"name": "details", "summary": "a line about it", "default": "street food · live music · makers"},
          {"name": "venue", "summary": "where", "default": "Old Wharf, Pier 3"},
          {"name": "link", "summary": "the page the QR code opens", "default": "https://example.com/market"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=31,palette=marmalade,motif=flow"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.1},
          {"type": "text", "id": "event", "text": "{event}", "font": "source-serif", "weight": "bold", "size": 150, "min_size": 60,
           "max_lines": 3, "line_height": 0.95, "align": "left", "valign": "top", "color": "auto",
           "frame": {"anchor": "top-left", "height": 0.42}},
          {"type": "text", "id": "date", "text": "{date}", "weight": "semibold", "size": 46, "max_lines": 1, "align": "left",
           "valign": "top", "color": "#111111", "plate": {"color": "#FFFFFF", "padding": 16, "radius": 6},
           "frame": {"anchor": "top-left", "height": 0.07, "x": 0.022, "below": "event", "gap": 0.04}},
          {"type": "text", "id": "details", "text": "{details}", "weight": "medium", "size": 40, "max_lines": 2, "align": "left",
           "valign": "top", "color": "auto", "frame": {"anchor": "top-left", "height": 0.1, "below": "date", "gap": 0.03}},
          {"type": "text", "id": "venue", "text": "{venue}", "weight": "bold", "size": 46, "max_lines": 2, "align": "left",
           "valign": "bottom", "color": "auto", "frame": {"anchor": "bottom-left", "width": 0.68, "height": 0.12}},
          {"type": "qr", "id": "qr", "text": "{link}", "color": "#111111", "background": "#FFFFFF",
           "frame": {"anchor": "bottom-right", "width": 0.24, "aspect": 1}}
        ]
      },
      {
        "name": "club-night",
        "summary": "A3 club-night poster: the night's name glowing in caps, the line-up under it, date and venue at the foot",
        "preset": "a3",
        "slots": [
          {"name": "night", "summary": "the night's name", "default": "Low Frequency"},
          {"name": "lineup", "summary": "who is playing", "default": "Ines Marrow · Tavi Ko · Hollis Drum"},
          {"name": "date", "summary": "when", "default": "Fri 3 October · 23:00 til late"},
          {"name": "venue", "summary": "where", "default": "The Vault, Dock Street"},
          {"name": "glow", "summary": "the neon colour", "default": "#FF3EA5"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=13,palette=neon-dusk,motif=nebula"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "darken": 0.35, "grain": 0.2, "vignette": 0.5},
          {"type": "text", "id": "night", "text": "{night}", "weight": "black", "size": 230, "min_size": 80, "max_lines": 3,
           "line_height": 0.9, "case": "upper", "color": "#FFFFFF", "glow": {"color": "{glow}", "radius": 40},
           "frame": {"anchor": "top", "width": 0.9, "height": 0.45}},
          {"type": "text", "id": "lineup", "text": "{lineup}", "weight": "semibold", "size": 58, "max_lines": 3, "case": "upper",
           "tracking": 120, "line_height": 1.15, "color": "#FFFFFF", "frame": {"anchor": "top", "height": 0.2, "below": "night", "gap": 0.04}},
          {"type": "text", "id": "venue", "text": "{venue}", "weight": "medium", "size": 44, "max_lines": 1, "color": "#FFFFFFD9",
           "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.05}},
          {"type": "text", "id": "date", "text": "{date}", "weight": "bold", "size": 52, "max_lines": 1, "case": "upper",
           "tracking": 80, "color": "#FFFFFF", "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.06, "above": "venue", "gap": 0.01}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "{glow}", "width": 4},
           "glow": {"color": "{glow}", "radius": 16}, "frame": {"anchor": "bottom", "width": 0.4, "height": 0.01, "above": "date", "gap": 0.03}}
        ]
      },
      {
        "name": "gig-poster",
        "summary": "A3 gig poster: the band in a big serif, support in italics, date, venue and tickets at the foot",
        "preset": "a3",
        "slots": [
          {"name": "artist", "summary": "the headliner", "default": "The Hollow Pines"},
          {"name": "support", "summary": "who opens", "default": "with special guests Ferris & Wren"},
          {"name": "date", "summary": "when", "default": "Thursday 20 November"},
          {"name": "venue", "summary": "where, and doors", "default": "Corn Exchange · doors 7 pm"},
          {"name": "tickets", "summary": "where to buy", "default": "tickets from the box office"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=64,palette=akane,motif=silk"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.12, "scrim": {"edge": "both", "strength": 0.55}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "source-serif", "weight": "bold", "size": 230, "min_size": 80,
           "max_lines": 2, "line_height": 0.9, "color": "#FFFFFF", "frame": {"anchor": "top", "height": 0.4}, "avoid": ["faces"]},
          {"type": "text", "id": "support", "text": "*{support}*", "font": "source-serif", "weight": "regular", "size": 56,
           "max_lines": 2, "color": "#FFFFFF", "shadow": {"color": "#000000A6", "blur": 14, "y": 3},
           "frame": {"anchor": "top", "height": 0.1, "below": "artist", "gap": 0.02}},
          {"type": "text", "id": "tickets", "text": "{tickets}", "weight": "medium", "size": 36, "max_lines": 1, "case": "upper",
           "tracking": 140, "color": "#FFFFFFCC", "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.04}},
          {"type": "text", "id": "venue", "text": "{venue}", "weight": "semibold", "size": 54, "max_lines": 1, "color": "#FFFFFF",
           "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.06, "above": "tickets", "gap": 0.015}},
          {"type": "text", "id": "date", "text": "{date}", "weight": "black", "size": 100, "max_lines": 1, "case": "upper",
           "color": "#FFFFFF", "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.09, "above": "venue", "gap": 0.01}}
        ]
      },
      {
        "name": "type-poster",
        "summary": "A4 minimal type poster: one word, huge, bottom-left; the details small, top-right, over a hairline",
        "preset": "a4",
        "slots": [
          {"name": "word", "summary": "the one word", "default": "Hush"},
          {"name": "details", "summary": "what, when, where — short lines", "default": "an evening of quiet music\n12 March · St Anne's Hall"},
          {"name": "ink", "summary": "the type's colour", "default": "#1A1A1A"},
          {"name": "background", "summary": "the paper", "default": "#EDE6D8"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.05},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "{ink}", "width": 3},
           "frame": {"anchor": "top", "height": 0.01, "y": 0.16}},
          {"type": "text", "id": "details", "text": "{details}", "font": "inter", "weight": "medium", "size": 32, "max_lines": 4,
           "line_height": 1.3, "align": "right", "valign": "top", "color": "{ink}", "frame": {"anchor": "top-right", "width": 0.6, "height": 0.14}},
          {"type": "text", "id": "word", "text": "{word}", "font": "source-serif", "weight": "bold", "size": 560, "min_size": 120,
           "max_lines": 2, "line_height": 0.82, "align": "left", "valign": "bottom", "color": "{ink}",
           "frame": {"anchor": "bottom-left", "height": 0.62}}
        ]
      },
      {
        "name": "sale-flyer",
        "summary": "US Letter sale flyer: the headline across the top, the offer in a starburst, dates, shop and a QR code",
        "preset": "letter",
        "slots": [
          {"name": "headline", "summary": "the headline", "default": "Spring Sale"},
          {"name": "offer", "summary": "the offer, short", "default": "40% off"},
          {"name": "dates", "summary": "when it runs", "default": "Friday to Sunday only"},
          {"name": "shop", "summary": "the shop and where it is", "default": "Fernway Goods, 12 Mill Lane"},
          {"name": "link", "summary": "the page the QR code opens", "default": "https://example.com/sale"},
          {"name": "background", "summary": "the art", "default": "linear:#FFB4A2,#FFD6A5,angle=160"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.06},
          {"type": "text", "id": "headline", "text": "{headline}", "weight": "black", "size": 230, "min_size": 80, "max_lines": 2,
           "line_height": 0.88, "case": "upper", "color": "#1B1B1B", "frame": {"anchor": "top", "height": 0.34}},
          {"type": "shape", "id": "burst", "shape": "star", "count": 16, "inner": 0.82, "fill": "#E63946", "rotation": -8,
           "shadow": {"color": "#00000040", "blur": 20, "y": 10}, "frame": {"anchor": "center", "width": 0.62, "aspect": 1, "y": 0.04}},
          {"type": "text", "id": "offer", "text": "{offer}", "weight": "black", "size": 170, "min_size": 50, "max_lines": 2,
           "line_height": 0.9, "case": "upper", "color": "#FFFFFF", "rotation": -8,
           "frame": {"anchor": "center", "width": 0.42, "aspect": 1, "y": 0.04}},
          {"type": "text", "id": "shop", "text": "{shop}", "weight": "medium", "size": 40, "max_lines": 2, "align": "left",
           "valign": "bottom", "color": "#1B1B1B", "frame": {"anchor": "bottom-left", "width": 0.66, "height": 0.08}},
          {"type": "text", "id": "dates", "text": "{dates}", "weight": "bold", "size": 58, "max_lines": 1, "align": "left",
           "valign": "bottom", "color": "#1B1B1B", "frame": {"anchor": "bottom-left", "width": 0.66, "height": 0.07, "above": "shop", "gap": 0.01}},
          {"type": "qr", "id": "qr", "text": "{link}", "color": "#1B1B1B", "background": "#FFFFFF",
           "frame": {"anchor": "bottom-right", "width": 0.2, "aspect": 1}}
        ]
      }
    ]
    """#
}
