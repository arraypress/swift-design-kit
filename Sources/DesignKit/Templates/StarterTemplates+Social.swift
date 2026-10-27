//
//  StarterTemplates+Social.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Screens: a video thumbnail, a quote card, a story announcement.
//

extension StarterTemplates {

    static let social = #"""
    [
      {
        "name": "youtube-thumbnail",
        "summary": "Video thumbnail: three or four condensed words with a thick keyline down the left, an accent tag top-right",
        "preset": "youtube-thumbnail",
        "pairing": "poster",
        "slots": [
          {"name": "headline", "summary": "the hook, a few words", "default": "Built In A Weekend"},
          {"name": "tag", "summary": "a short tag", "default": "New"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=99,palette=voltage,motif=holo"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "darken": 0.15},
          {"type": "text", "id": "headline", "text": "{headline}", "font": "display", "size": 210, "min_size": 80, "max_lines": 3,
           "line_height": 0.88, "case": "upper", "align": "left", "color": "#FFFFFF",
           "stroke": {"color": "dark", "width": 8}, "shadow": {"color": "#000000", "blur": 0, "x": 8, "y": 8},
           "frame": {"anchor": "left", "width": 0.62, "height": 0.86, "x": 0.01}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "tag", "text": "{tag}", "font": "display", "size": 70, "max_lines": 1, "case": "upper",
           "color": "dark", "plate": {"color": "accent", "padding": 16, "radius": 6}, "rotation": 6,
           "frame": {"anchor": "top-right", "width": 0.26, "height": 0.16, "y": 0.03}}
        ]
      },
      {
        "name": "quote-card",
        "summary": "Square quote card: a big open-quote mark in Didot, the quote in it, the name in spaced capitals under a short rule",
        "preset": "ig-post",
        "pairing": "editorial",
        "palette": {"harmony": "mono"},
        "slots": [
          {"name": "quote", "summary": "the quote", "default": "Make the thing you wish someone else had made."},
          {"name": "author", "summary": "who said it", "default": "Ada Brennan"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=17,palette=lilac-hour,motif=classic"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.05},
          {"type": "text", "id": "mark", "text": "“", "font": "display", "size": 300, "align": "left",
           "valign": "top", "color": "accent", "fit": "none", "frame": {"anchor": "top-left", "width": 0.34, "height": 0.5, "y": -0.07}},
          {"type": "text", "id": "quote", "text": "{quote}", "font": "display", "size": 92, "min_size": 36,
           "max_lines": 6, "line_height": 1.08, "align": "left", "color": "dark", "frame": {"anchor": "left", "height": 0.56}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "accent", "width": 4},
           "frame": {"anchor": "left", "width": 0.08, "height": 0.01, "below": "quote", "gap": 0.045}},
          {"type": "text", "id": "author", "text": "{author}", "font": "text", "weight": "medium", "size": 30, "tracking": 320, "case": "upper",
           "max_lines": 1, "align": "left", "valign": "top", "color": "dark",
           "frame": {"anchor": "left", "height": 0.06, "below": "rule", "gap": 0.03}}
        ]
      },
      {
        "name": "story-announcement",
        "summary": "Story announcement: a pill label up top, the title huge in Bodoni in the middle, the date in Futura capitals under it",
        "preset": "story",
        "pairing": "fashion",
        "slots": [
          {"name": "label", "summary": "what this is", "default": "New single"},
          {"name": "title", "summary": "the title", "default": "Glasshouse"},
          {"name": "date", "summary": "when", "default": "Out Friday"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=23,palette=dawn,motif=aurora"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.05, "scrim": {"edge": "auto"}},
          {"type": "text", "id": "label", "text": "{label}", "font": "text", "size": 34, "tracking": 360, "case": "upper",
           "max_lines": 1, "color": "dark", "plate": {"color": "light", "padding": 22, "radius": 60},
           "frame": {"anchor": "top", "height": 0.05, "y": 0.012}},
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 260, "min_size": 80, "max_lines": 3,
           "line_height": 0.92, "color": "light", "frame": {"anchor": "center", "height": 0.34}, "avoid": ["faces", "subject"],
           "shadow": {"color": "#00000026", "blur": 24, "y": 6}},
          {"type": "text", "id": "date", "text": "{date}", "font": "text", "size": 40, "max_lines": 1, "tracking": 400, "case": "upper",
           "color": "light", "frame": {"anchor": "top", "height": 0.05, "below": "title", "gap": 0.03}}
        ]
      }
    ]
    """#
}
