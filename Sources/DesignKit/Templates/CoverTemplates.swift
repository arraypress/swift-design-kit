//
//  CoverTemplates.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Square covers: records, mixtapes, podcasts. Written as JSON so a template
//  reads like the design file it makes. Each is set in a type pairing
//  (`"font": "display"` / `"text"`) and coloured from palette roles taken
//  from its art (`light`, `dark`, `accent`), so a new background brings its
//  own colours. Names and copy are invented.
//

extension StarterTemplates {

    static let covers = #"""
    [
      {
        "name": "cover-clean",
        "summary": "Record cover: the artist in small spaced capitals up top, the title low in a high-contrast Didone, the art left to speak",
        "preset": "cover",
        "pairing": "editorial",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Night Drive"},
          {"name": "artist", "summary": "who made it", "default": "Lena Vale"},
          {"name": "background", "summary": "the art: gradient:…, imagine:…, image:…, or a colour", "default": "gradient:seed=42,palette=lagoon,motif=flow"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.06, "scrim": {"edge": "auto"}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "weight": "medium", "size": 28, "tracking": 420, "case": "upper",
           "color": "light", "frame": {"anchor": "top", "height": 0.07}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 200, "min_size": 70, "max_lines": 2,
           "line_height": 0.9, "tracking": -10, "color": "light", "frame": {"anchor": "bottom", "height": 0.3},
           "avoid": ["faces", "subject"]}
        ]
      },
      {
        "name": "cover-bold",
        "summary": "Record cover: the title stacked huge and condensed from the top-left, the artist on an accent tab",
        "preset": "cover",
        "pairing": "poster",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Loud Weather"},
          {"name": "artist", "summary": "who made it", "default": "Juno Harte"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=7,palette=reactor,motif=aurora"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "darken": 0.35, "grain": 0.12},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 330, "min_size": 90, "max_lines": 3,
           "line_height": 0.86, "case": "upper", "align": "left", "valign": "top", "color": "light",
           "frame": {"anchor": "top-left", "height": 0.72}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "weight": "bold", "size": 36, "tracking": 260, "case": "upper",
           "align": "left", "valign": "bottom", "color": "dark", "plate": {"color": "accent", "padding": 20, "radius": 0},
           "frame": {"anchor": "bottom-left", "width": 0.7, "height": 0.08, "x": 0.025, "y": -0.025}}
        ]
      },
      {
        "name": "mixtape",
        "summary": "Mixtape cover: the title in a fat seventies face on a tilted paper strip, a burst with the volume, dusty grainy art",
        "preset": "cover",
        "pairing": "retro",
        "slots": [
          {"name": "title", "summary": "the tape's title", "default": "Basement Tapes"},
          {"name": "artist", "summary": "who made it", "default": "Orrin Pike"},
          {"name": "volume", "summary": "the volume or edition", "default": "Vol. 3"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=88,palette=rave,motif=mesh"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.25, "vignette": 0.4},
          {"type": "group", "id": "strip", "rotation": -6, "shadow": {"color": "#00000066", "blur": 24, "y": 10},
           "frame": {"area": "trim", "anchor": "center", "width": 1.2, "height": 0.2},
           "layers": [
             {"type": "shape", "shape": "rect", "fill": "light"},
             {"type": "texture", "id": "paper", "kind": "paper", "color": "#7A6A50", "density": 0.5, "seed": 3, "blend": "multiply", "opacity": 0.5},
             {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 130, "min_size": 50, "max_lines": 1,
              "color": "dark", "frame": {"width": 0.72, "height": 0.7}}
           ]},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "weight": "bold", "size": 40, "tracking": 260, "case": "upper",
           "color": "light", "shadow": {"color": "#00000059", "blur": 16, "y": 4}, "frame": {"anchor": "bottom", "height": 0.09}},
          {"type": "shape", "id": "burst", "shape": "burst", "count": 18, "inner": 0.8, "fill": "accent", "rotation": 10,
           "frame": {"anchor": "top-right", "width": 0.24, "aspect": 1}},
          {"type": "text", "id": "volume", "text": "{volume}", "font": "display", "size": 56, "max_lines": 2,
           "color": "dark", "rotation": 10, "frame": {"anchor": "top-right", "width": 0.24, "aspect": 1}},
          {"type": "texture", "id": "dust", "kind": "dust", "color": "#FFFFFF", "density": 0.35, "seed": 7, "blend": "screen", "opacity": 0.6,
           "frame": {"area": "bleed"}}
        ]
      },
      {
        "name": "podcast-cover",
        "summary": "Podcast show art: the show's name in Futura over the art, host and tagline on a dark band under a hairline",
        "preset": "podcast-cover",
        "pairing": "geometric",
        "slots": [
          {"name": "show", "summary": "the show's name", "default": "Slow Signal"},
          {"name": "host", "summary": "who hosts it", "default": "with Mara Quill"},
          {"name": "tagline", "summary": "what it is about, in a line", "default": "conversations about making things"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=5,palette=sea-glass,motif=smesh"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.05},
          {"type": "shape", "id": "band", "shape": "rect", "fill": "dark", "opacity": 0.92, "frame": {"area": "trim", "anchor": "bottom", "height": 0.3}},
          {"type": "text", "id": "show", "text": "{show}", "font": "display", "size": 170, "min_size": 60,
           "max_lines": 2, "line_height": 0.92, "tracking": -10, "align": "left", "valign": "top", "color": "auto",
           "frame": {"anchor": "top-left", "height": 0.55}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "tagline", "text": "{tagline}", "font": "text", "size": 36, "max_lines": 2,
           "align": "left", "valign": "bottom", "color": "light", "opacity": 0.78, "frame": {"anchor": "bottom-left", "height": 0.09}},
          {"type": "text", "id": "host", "text": "{host}", "font": "text", "weight": "medium", "size": 60, "max_lines": 1,
           "align": "left", "valign": "bottom", "color": "light", "frame": {"anchor": "bottom-left", "height": 0.1, "above": "tagline", "gap": 0.012}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "accent", "width": 6},
           "frame": {"anchor": "bottom-left", "width": 0.12, "height": 0.01, "above": "host", "gap": 0.03}}
        ]
      },
      {
        "name": "minimal-serif",
        "summary": "Quiet cover: a thin inset frame, the title small and centred in a fine serif, the artist in spaced capitals under a hairline",
        "preset": "cover",
        "pairing": "fashion",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Still Water"},
          {"name": "artist", "summary": "who made it", "default": "Elin Marsh"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=12,palette=sea-glass,motif=classic"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.04, "darken": 0.08},
          {"type": "texture", "id": "paper", "kind": "paper", "color": "#6B5E4A", "density": 0.35, "seed": 11, "blend": "multiply", "opacity": 0.35},
          {"type": "shape", "id": "border", "shape": "frame", "inset": 30, "stroke": {"color": "light", "width": 3},
           "frame": {"area": "trim"}},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 120, "min_size": 50, "max_lines": 2,
           "line_height": 1.0, "color": "light", "frame": {"anchor": "center", "width": 0.8, "height": 0.22, "y": -0.03}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "light", "width": 2},
           "frame": {"anchor": "center", "width": 0.1, "height": 0.01, "below": "title", "gap": 0.035}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "size": 26, "tracking": 520, "case": "upper",
           "color": "light", "frame": {"anchor": "center", "height": 0.06, "below": "rule", "gap": 0.03}}
        ]
      },
      {
        "name": "brutalist-grid",
        "summary": "Brutalist cover: a ruled grid, the title in a black grotesque hard left, catalogue details in monospace, one accent block",
        "preset": "cover",
        "pairing": "brutalist",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Concrete Hours"},
          {"name": "artist", "summary": "who made it", "default": "Unit Nine"},
          {"name": "catalogue", "summary": "a catalogue number", "default": "UN-009"},
          {"name": "year", "summary": "the year", "default": "2026"},
          {"name": "background", "summary": "the ground", "default": "#E8E4DA"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.08},
          {"type": "shape", "id": "block", "shape": "rect", "fill": "accent", "frame": {"anchor": "bottom-right", "width": 0.33, "height": 0.33}},
          {"type": "shape", "id": "rule-top", "shape": "line", "stroke": {"color": "dark", "width": 5}, "frame": {"anchor": "top", "height": 0.01, "y": 0.1}},
          {"type": "shape", "id": "rule-mid", "shape": "line", "stroke": {"color": "dark", "width": 5}, "frame": {"anchor": "center", "height": 0.01, "y": 0.1}},
          {"type": "shape", "id": "rule-side", "shape": "line", "points": [[0.5, 0], [0.5, 1]], "stroke": {"color": "dark", "width": 5},
           "frame": {"anchor": "center", "width": 0.01, "height": 1, "x": 0.17}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "weight": "bold", "size": 34, "case": "upper", "tracking": 60,
           "align": "left", "valign": "top", "color": "dark", "frame": {"anchor": "top-left", "width": 0.6, "height": 0.08}},
          {"type": "text", "id": "catalogue", "text": "{catalogue}\n{year}", "font": "text", "size": 30, "line_height": 1.2,
           "align": "right", "valign": "top", "color": "dark", "frame": {"anchor": "top-right", "width": 0.3, "height": 0.09}},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 210, "min_size": 70, "max_lines": 3,
           "line_height": 0.88, "tracking": -20, "case": "upper", "align": "left", "valign": "top", "color": "dark",
           "frame": {"anchor": "top-left", "width": 0.66, "height": 0.42, "y": 0.13}}
        ]
      },
      {
        "name": "retro-poster",
        "summary": "Seventies cover: the art through a warm three-colour map, a halftone fade, the title fat with a hard offset shadow, a seal",
        "preset": "cover",
        "pairing": "retro",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Sunset Club"},
          {"name": "artist", "summary": "who made it", "default": "The Velvet Hours"},
          {"name": "badge", "summary": "a word or two on the seal", "default": "Side A"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=21,palette=marmalade,motif=flow"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "gradient_map": ["#2B1B3D", "#8E3B46", "#C8553D", "#E9A23B"], "grain": 0.15},
          {"type": "texture", "id": "halftone", "kind": "halftone", "color": "#2B1B3D", "scale": 18, "density": 0.9, "angle": 180, "opacity": 0.35, "blend": "multiply",
           "frame": {"area": "bleed"}, "fade": {"edge": "top", "start": 0.1, "end": 0.7}},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 240, "min_size": 80, "max_lines": 2,
           "line_height": 0.92, "color": "#FBF2DC", "shadow": {"color": "#2B1B3D", "blur": 0, "x": 10, "y": 10},
           "frame": {"anchor": "top", "width": 0.92, "height": 0.42, "y": 0.04}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "weight": "bold", "size": 40, "tracking": 160, "case": "upper",
           "color": "#FBF2DC", "frame": {"anchor": "bottom", "height": 0.08}},
          {"type": "shape", "id": "seal", "shape": "badge", "count": 22, "fill": "#C8553D", "rotation": -12,
           "frame": {"anchor": "bottom-right", "width": 0.2, "aspect": 1, "y": -0.09}},
          {"type": "text", "id": "badge", "text": "{badge}", "font": "display", "size": 44, "max_lines": 2, "color": "#FBF2DC", "rotation": -12,
           "frame": {"anchor": "bottom-right", "width": 0.2, "aspect": 1, "y": -0.09}}
        ]
      },
      {
        "name": "film-still",
        "summary": "A cover like a frame from a film: letterbox bars, the title in widely spaced capitals on the lower bar, a credit above it, dust",
        "preset": "cover",
        "pairing": "cinema",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Last Train North"},
          {"name": "artist", "summary": "who made it, as a credit", "default": "a record by Mira Okafor"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=33,palette=dark,motif=aurora"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.18, "vignette": 0.35},
          {"type": "shape", "id": "bar-top", "shape": "rect", "fill": "#000000", "frame": {"area": "bleed", "anchor": "top", "height": 0.18}},
          {"type": "shape", "id": "bar-bottom", "shape": "rect", "fill": "#000000", "frame": {"area": "bleed", "anchor": "bottom", "height": 0.18}},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 58, "min_size": 30, "max_lines": 1, "tracking": 380,
           "case": "upper", "color": "#F2EEE6", "frame": {"area": "trim", "anchor": "bottom", "height": 0.18, "width": 0.86}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "size": 30, "max_lines": 1,
           "color": "#F2EEE6", "opacity": 0.8, "frame": {"area": "trim", "anchor": "top", "height": 0.18, "width": 0.86}},
          {"type": "texture", "id": "dust", "kind": "dust", "color": "#FFFFFF", "density": 0.12, "seed": 4, "blend": "screen", "opacity": 0.5,
           "frame": {"area": "bleed"}}
        ]
      },
      {
        "name": "swiss",
        "summary": "International Style cover: flat ground, the title tight and heavy flush left, a black circle, details small on the grid",
        "preset": "cover",
        "pairing": "swiss",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Form & Signal"},
          {"name": "artist", "summary": "who made it", "default": "Kasimir Lenz"},
          {"name": "details", "summary": "a few short lines", "default": "eight pieces for\nsynthesiser and voice\n2026"},
          {"name": "background", "summary": "the ground", "default": "#E2412E"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}"},
          {"type": "shape", "id": "circle", "shape": "ellipse", "fill": "#111111",
           "frame": {"area": "trim", "anchor": "bottom-right", "width": 0.62, "aspect": 1, "x": 0.12, "y": 0.1}},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 190, "min_size": 70, "max_lines": 3,
           "line_height": 0.9, "tracking": -30, "align": "left", "valign": "top", "color": "#111111",
           "frame": {"anchor": "top-left", "width": 0.85, "height": 0.42}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "#111111", "width": 8},
           "frame": {"columns": [1, 4], "anchor": "top-left", "height": 0.01, "below": "title", "gap": 0.04}},
          {"type": "text", "id": "artist", "text": "{artist}", "font": "text", "weight": "bold", "size": 40, "align": "left", "valign": "top",
           "color": "#111111", "frame": {"columns": [1, 6], "anchor": "top-left", "height": 0.07, "below": "rule", "gap": 0.025}},
          {"type": "text", "id": "details", "text": "{details}", "font": "text", "size": 30, "line_height": 1.25, "align": "left", "valign": "top",
           "color": "#111111", "frame": {"columns": [1, 5], "anchor": "top-left", "height": 0.14, "below": "artist", "gap": 0.005}}
        ]
      }
    ]
    """#
}
