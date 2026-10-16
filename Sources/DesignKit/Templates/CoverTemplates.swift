//
//  CoverTemplates.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Square covers: records, mixtapes, podcasts. Written as JSON so a template
//  reads like the design file it makes. Names and copy are invented.
//

extension StarterTemplates {

    static let covers = #"""
    [
      {
        "name": "cover-clean",
        "summary": "Record cover: a quiet artist line up top, the title low and large, the art left to speak",
        "preset": "cover",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Night Drive"},
          {"name": "artist", "summary": "who made it", "default": "Lena Vale"},
          {"name": "background", "summary": "the art: gradient:…, imagine:…, image:…, or a colour", "default": "gradient:seed=42,palette=lagoon,motif=flow"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.08, "scrim": {"edge": "auto"}},
          {"type": "text", "id": "artist", "text": "{artist}", "weight": "medium", "size": 34, "tracking": 320, "case": "upper",
           "color": "auto", "frame": {"anchor": "top", "height": 0.08}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "title", "text": "{title}", "weight": "bold", "size": 150, "min_size": 60, "max_lines": 2,
           "line_height": 0.95, "color": "auto", "frame": {"anchor": "bottom", "height": 0.3},
           "shadow": {"color": "#00000040", "blur": 30, "y": 6}, "avoid": ["faces", "subject"]}
        ]
      },
      {
        "name": "cover-bold",
        "summary": "Record cover: the title stacked huge from the top-left, the artist on a white tab below",
        "preset": "cover",
        "slots": [
          {"name": "title", "summary": "the record's title", "default": "Loud Weather"},
          {"name": "artist", "summary": "who made it", "default": "Juno Harte"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=7,palette=reactor,motif=aurora"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "darken": 0.4, "grain": 0.15},
          {"type": "text", "id": "title", "text": "{title}", "weight": "black", "size": 300, "min_size": 90, "max_lines": 3,
           "line_height": 0.86, "tracking": -15, "case": "upper", "align": "left", "valign": "top", "color": "#FFFFFF",
           "frame": {"anchor": "top-left", "height": 0.75}},
          {"type": "text", "id": "artist", "text": "{artist}", "weight": "bold", "size": 40, "tracking": 200, "case": "upper",
           "align": "left", "valign": "bottom", "color": "#000000", "plate": {"color": "#FFFFFF", "padding": 18, "radius": 0},
           "frame": {"anchor": "bottom-left", "width": 0.7, "height": 0.08, "x": 0.02, "y": -0.025}}
        ]
      },
      {
        "name": "mixtape",
        "summary": "Mixtape cover: the title on a tilted label strip, a starburst with the volume, grainy art",
        "preset": "cover",
        "slots": [
          {"name": "title", "summary": "the tape's title", "default": "Basement Tapes"},
          {"name": "artist", "summary": "who made it", "default": "Orrin Pike"},
          {"name": "volume", "summary": "the volume or edition", "default": "Vol. 3"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=88,palette=rave,motif=mesh"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.3, "vignette": 0.4},
          {"type": "group", "id": "strip", "rotation": -6, "shadow": {"color": "#00000066", "blur": 24, "y": 10},
           "frame": {"area": "trim", "anchor": "center", "width": 1.2, "height": 0.2},
           "layers": [
             {"type": "shape", "shape": "rect", "fill": "#F5F0E6"},
             {"type": "text", "id": "title", "text": "{title}", "weight": "black", "size": 130, "min_size": 50, "max_lines": 1,
              "case": "upper", "tracking": 20, "color": "#111111", "frame": {"width": 0.72, "height": 0.7}}
           ]},
          {"type": "text", "id": "artist", "text": "{artist}", "weight": "semibold", "size": 46, "tracking": 160, "case": "upper",
           "color": "auto", "shadow": {"color": "#00000059", "blur": 16, "y": 4}, "frame": {"anchor": "bottom", "height": 0.1}},
          {"type": "shape", "id": "burst", "shape": "star", "count": 14, "inner": 0.78, "fill": "#FFD23F", "rotation": 10,
           "frame": {"anchor": "top-right", "width": 0.24, "aspect": 1}},
          {"type": "text", "id": "volume", "text": "{volume}", "weight": "black", "size": 52, "max_lines": 2, "case": "upper",
           "color": "#111111", "rotation": 10, "frame": {"anchor": "top-right", "width": 0.24, "aspect": 1}}
        ]
      },
      {
        "name": "podcast-cover",
        "summary": "Podcast show art: the show's name over the art, host and tagline on a dark band",
        "preset": "podcast-cover",
        "slots": [
          {"name": "show", "summary": "the show's name", "default": "Slow Signal"},
          {"name": "host", "summary": "who hosts it", "default": "with Mara Quill"},
          {"name": "tagline", "summary": "what it is about, in a line", "default": "conversations about making things"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=5,palette=sea-glass,motif=smesh"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.06},
          {"type": "shape", "id": "band", "shape": "rect", "fill": "#101418E6", "frame": {"area": "trim", "anchor": "bottom", "height": 0.3}},
          {"type": "text", "id": "show", "text": "{show}", "font": "inter", "weight": "bold", "size": 160, "min_size": 60,
           "max_lines": 2, "line_height": 0.92, "align": "left", "valign": "top", "color": "auto",
           "frame": {"anchor": "top-left", "height": 0.55}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "tagline", "text": "{tagline}", "font": "inter", "weight": "regular", "size": 38, "max_lines": 2,
           "align": "left", "valign": "bottom", "color": "#FFFFFFB8", "frame": {"anchor": "bottom-left", "height": 0.09}},
          {"type": "text", "id": "host", "text": "{host}", "font": "inter", "weight": "semibold", "size": 62, "max_lines": 1,
           "align": "left", "valign": "bottom", "color": "#FFFFFF", "frame": {"anchor": "bottom-left", "height": 0.1, "above": "tagline", "gap": 0.015}}
        ]
      }
    ]
    """#
}
