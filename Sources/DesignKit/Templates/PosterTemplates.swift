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
        "summary": "A5 event flyer: the event in a big book serif, the date on a tab, details, the venue, and a QR code to the page",
        "preset": "a5",
        "pairing": "literary",
        "slots": [
          {"name": "event", "summary": "what is on", "default": "Riverside Night Market"},
          {"name": "date", "summary": "when", "default": "Saturday 14 June · 5–11 pm"},
          {"name": "details", "summary": "a line about it", "default": "street food · live music · makers"},
          {"name": "venue", "summary": "where", "default": "Old Wharf, Pier 3"},
          {"name": "link", "summary": "the page the QR code opens", "default": "https://example.com/market"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=31,palette=marmalade,motif=flow"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.08, "darken": 0.15, "scrim": {"edge": "both", "strength": 0.5}},
          {"type": "text", "id": "event", "text": "{event}", "font": "display", "size": 165, "min_size": 60,
           "max_lines": 3, "line_height": 0.95, "align": "left", "valign": "top", "color": "light",
           "frame": {"anchor": "top-left", "height": 0.42}},
          {"type": "text", "id": "date", "text": "{date}", "font": "text", "weight": "semibold", "size": 44, "max_lines": 1, "align": "left",
           "valign": "top", "color": "dark", "plate": {"color": "light", "padding": 16, "radius": 2},
           "frame": {"anchor": "top-left", "height": 0.07, "x": 0.022, "below": "event", "gap": 0.04}},
          {"type": "text", "id": "details", "text": "{details}", "font": "text", "size": 40, "max_lines": 2, "align": "left",
           "valign": "top", "color": "light", "frame": {"anchor": "top-left", "height": 0.1, "below": "date", "gap": 0.03}},
          {"type": "text", "id": "venue", "text": "{venue}", "font": "display", "size": 52, "max_lines": 2, "align": "left",
           "valign": "bottom", "color": "light", "frame": {"anchor": "bottom-left", "width": 0.66, "height": 0.12}},
          {"type": "qr", "id": "qr", "text": "{link}", "color": "#111111", "background": "#FFFFFF",
           "frame": {"anchor": "bottom-right", "width": 0.22, "aspect": 1}}
        ]
      },
      {
        "name": "club-night",
        "summary": "A3 club-night poster: the night's name glowing in tall condensed capitals, the line-up spaced under it, date and venue at the foot",
        "preset": "a3",
        "pairing": "condensed",
        "slots": [
          {"name": "night", "summary": "the night's name", "default": "Low Frequency"},
          {"name": "lineup", "summary": "who is playing", "default": "Ines Marrow · Tavi Ko · Hollis Drum"},
          {"name": "date", "summary": "when", "default": "Fri 3 October · 23:00 til late"},
          {"name": "venue", "summary": "where", "default": "The Vault, Dock Street"},
          {"name": "glow", "summary": "the neon colour", "default": "#FF3EA5"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=13,palette=neon-dusk,motif=nebula"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "darken": 0.4, "grain": 0.18, "vignette": 0.5},
          {"type": "text", "id": "night", "text": "{night}", "font": "display", "size": 330, "min_size": 90, "max_lines": 3,
           "line_height": 0.86, "case": "upper", "tracking": 10, "color": "#FFFFFF", "glow": {"color": "{glow}", "radius": 40},
           "frame": {"anchor": "top", "width": 0.92, "height": 0.48}},
          {"type": "text", "id": "lineup", "text": "{lineup}", "font": "text", "weight": "medium", "size": 50, "max_lines": 3, "case": "upper",
           "tracking": 200, "line_height": 1.3, "color": "#FFFFFF", "frame": {"anchor": "top", "height": 0.2, "below": "night", "gap": 0.035}},
          {"type": "text", "id": "venue", "text": "{venue}", "font": "text", "size": 42, "max_lines": 1, "color": "#FFFFFF", "opacity": 0.8,
           "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.05}},
          {"type": "text", "id": "date", "text": "{date}", "font": "display", "size": 90, "max_lines": 1, "case": "upper",
           "tracking": 60, "color": "#FFFFFF", "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.07, "above": "venue", "gap": 0.01}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "{glow}", "width": 4},
           "glow": {"color": "{glow}", "radius": 16}, "frame": {"anchor": "bottom", "width": 0.3, "height": 0.01, "above": "date", "gap": 0.03}}
        ]
      },
      {
        "name": "gig-poster",
        "summary": "A3 gig poster: the band in a big Caslon, support in Baskerville italics, a double rule, date, venue and tickets at the foot",
        "preset": "a3",
        "pairing": "literary",
        "slots": [
          {"name": "artist", "summary": "the headliner", "default": "The Hollow Pines"},
          {"name": "support", "summary": "who opens", "default": "with special guests Ferris & Wren"},
          {"name": "date", "summary": "when", "default": "Thursday 20 November"},
          {"name": "venue", "summary": "where, and doors", "default": "Corn Exchange · doors 7 pm"},
          {"name": "tickets", "summary": "where to buy", "default": "tickets from the box office"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=64,palette=akane,motif=silk"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.1, "scrim": {"edge": "both", "strength": 0.6}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "display", "size": 250, "min_size": 80,
           "max_lines": 2, "line_height": 0.9, "color": "light", "frame": {"anchor": "top", "height": 0.38}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "support", "text": "*{support}*", "font": "text", "size": 56,
           "max_lines": 2, "color": "light", "shadow": {"color": "#00000080", "blur": 14, "y": 3},
           "frame": {"anchor": "top", "height": 0.08, "below": "artist", "gap": 0.02}},
          {"type": "text", "id": "tickets", "text": "{tickets}", "font": "text", "size": 34, "max_lines": 1, "case": "upper",
           "tracking": 260, "color": "light", "opacity": 0.85, "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.04}},
          {"type": "text", "id": "venue", "text": "{venue}", "font": "text", "size": 54, "max_lines": 1, "color": "light",
           "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.06, "above": "tickets", "gap": 0.015}},
          {"type": "text", "id": "date", "text": "{date}", "font": "display", "size": 110, "max_lines": 1,
           "color": "light", "valign": "bottom", "frame": {"anchor": "bottom", "height": 0.09, "above": "venue", "gap": 0.01}},
          {"type": "shape", "id": "rule", "shape": "double-frame", "inset": 0, "gap": 6, "stroke": {"color": "light", "width": 2},
           "frame": {"anchor": "bottom", "width": 0.5, "height": 0.012, "above": "date", "gap": 0.03}}
        ]
      },
      {
        "name": "type-poster",
        "summary": "A4 minimal type poster: one word, huge, bottom-left in Helvetica; the details small, top-right, over a hairline",
        "preset": "a4",
        "pairing": "swiss",
        "slots": [
          {"name": "word", "summary": "the one word", "default": "Hush"},
          {"name": "details", "summary": "what, when, where — short lines", "default": "an evening of quiet music\n12 March · St Anne's Hall"},
          {"name": "ink", "summary": "the type's colour", "default": "#1A1A1A"},
          {"name": "background", "summary": "the paper", "default": "#EDE6D8"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.04},
          {"type": "texture", "id": "paper", "kind": "paper", "color": "#5C5040", "density": 0.3, "seed": 5, "blend": "multiply", "opacity": 0.3},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "{ink}", "width": 2},
           "frame": {"anchor": "top", "height": 0.01, "y": 0.16}},
          {"type": "text", "id": "details", "text": "{details}", "font": "text", "size": 30, "max_lines": 4,
           "line_height": 1.35, "align": "right", "valign": "top", "color": "{ink}", "frame": {"anchor": "top-right", "width": 0.6, "height": 0.14}},
          {"type": "text", "id": "word", "text": "{word}", "font": "display", "size": 600, "min_size": 120,
           "max_lines": 2, "line_height": 0.82, "tracking": -40, "align": "left", "valign": "bottom", "color": "{ink}",
           "frame": {"anchor": "bottom-left", "height": 0.62}}
        ]
      },
      {
        "name": "sale-flyer",
        "summary": "US Letter sale flyer: the headline in condensed capitals across the top, the offer in a burst, dates, shop and a QR code",
        "preset": "letter",
        "pairing": "poster",
        "slots": [
          {"name": "headline", "summary": "the headline", "default": "Spring Sale"},
          {"name": "offer", "summary": "the offer, short", "default": "40% off"},
          {"name": "dates", "summary": "when it runs", "default": "Friday to Sunday only"},
          {"name": "shop", "summary": "the shop and where it is", "default": "Fernway Goods, 12 Mill Lane"},
          {"name": "link", "summary": "the page the QR code opens", "default": "https://example.com/sale"},
          {"name": "background", "summary": "the art", "default": "linear:#FFB4A2,#FFD6A5,angle=160"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.05},
          {"type": "text", "id": "headline", "text": "{headline}", "font": "display", "size": 300, "min_size": 80, "max_lines": 2,
           "line_height": 0.86, "case": "upper", "color": "#1B1B1B", "frame": {"anchor": "top", "height": 0.34}},
          {"type": "shape", "id": "burst", "shape": "burst", "count": 22, "inner": 0.86, "fill": "#D7263D", "rotation": -8,
           "shadow": {"color": "#00000033", "blur": 20, "y": 10}, "frame": {"anchor": "center", "width": 0.62, "aspect": 1, "y": 0.04}},
          {"type": "text", "id": "offer", "text": "{offer}", "font": "display", "size": 210, "min_size": 50, "max_lines": 2,
           "line_height": 0.9, "case": "upper", "color": "#FFFFFF", "rotation": -8,
           "frame": {"anchor": "center", "width": 0.42, "aspect": 1, "y": 0.04}},
          {"type": "text", "id": "shop", "text": "{shop}", "font": "text", "size": 40, "max_lines": 2, "align": "left",
           "valign": "bottom", "color": "#1B1B1B", "frame": {"anchor": "bottom-left", "width": 0.66, "height": 0.08}},
          {"type": "text", "id": "dates", "text": "{dates}", "font": "text", "weight": "bold", "size": 58, "max_lines": 1, "align": "left",
           "valign": "bottom", "color": "#1B1B1B", "frame": {"anchor": "bottom-left", "width": 0.66, "height": 0.07, "above": "shop", "gap": 0.01}},
          {"type": "qr", "id": "qr", "text": "{link}", "color": "#1B1B1B", "background": "#FFFFFF",
           "frame": {"anchor": "bottom-right", "width": 0.2, "aspect": 1}}
        ]
      }
    ]
    """#
}
