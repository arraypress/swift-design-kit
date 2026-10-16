//
//  SocialTemplates.swift
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
        "summary": "Video thumbnail: three or four heavy words with a thick keyline down the left, a yellow tag top-right",
        "preset": "youtube-thumbnail",
        "slots": [
          {"name": "headline", "summary": "the hook, a few words", "default": "Built In A Weekend"},
          {"name": "tag", "summary": "a short tag", "default": "New"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=99,palette=voltage,motif=holo"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "darken": 0.1},
          {"type": "text", "id": "headline", "text": "{headline}", "weight": "black", "size": 170, "min_size": 70, "max_lines": 3,
           "line_height": 0.9, "case": "upper", "align": "left", "color": "#FFFFFF",
           "tracking": 10, "stroke": {"color": "#000000", "width": 7}, "shadow": {"color": "#000000", "blur": 0, "x": 7, "y": 7},
           "frame": {"anchor": "left", "width": 0.62, "height": 0.86, "x": 0.01}, "avoid": ["faces", "subject"]},
          {"type": "text", "id": "tag", "text": "{tag}", "weight": "black", "size": 64, "max_lines": 1, "case": "upper",
           "color": "#111111", "plate": {"color": "#FFE600", "padding": 16, "radius": 12}, "rotation": 6,
           "frame": {"anchor": "top-right", "width": 0.26, "height": 0.16}}
        ]
      },
      {
        "name": "quote-card",
        "summary": "Square quote card: a big open-quote mark, the quote in a serif, the name under it",
        "preset": "ig-post",
        "slots": [
          {"name": "quote", "summary": "the quote", "default": "Make the thing you wish someone else had made."},
          {"name": "author", "summary": "who said it", "default": "Ada Brennan"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=17,palette=lilac-hour,motif=classic"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.05},
          {"type": "text", "id": "mark", "text": "“", "font": "source-serif", "weight": "bold", "size": 420, "align": "left",
           "valign": "top", "color": "#FFFFFF8C", "fit": "none", "frame": {"anchor": "top-left", "width": 0.3, "height": 0.28}},
          {"type": "text", "id": "quote", "text": "{quote}", "font": "source-serif", "weight": "semibold", "size": 84, "min_size": 36,
           "max_lines": 6, "line_height": 1.12, "align": "left", "color": "auto", "frame": {"anchor": "left", "height": 0.56}},
          {"type": "text", "id": "author", "text": "— {author}", "font": "inter", "weight": "medium", "size": 36, "tracking": 60,
           "max_lines": 1, "align": "left", "valign": "top", "color": "auto",
           "frame": {"anchor": "left", "height": 0.08, "below": "quote", "gap": 0.04}}
        ]
      },
      {
        "name": "story-announcement",
        "summary": "Story announcement: a white pill label up top, the title huge in the middle, the date under it",
        "preset": "story",
        "slots": [
          {"name": "label", "summary": "what this is", "default": "New single"},
          {"name": "title", "summary": "the title", "default": "Glasshouse"},
          {"name": "date", "summary": "when", "default": "Out Friday"},
          {"name": "background", "summary": "the art", "default": "gradient:seed=23,palette=dawn,motif=aurora"}
        ],
        "layers": [
          {"type": "background", "id": "background", "fill": "{background}", "grain": 0.06, "scrim": {"edge": "auto"}},
          {"type": "text", "id": "label", "text": "{label}", "weight": "bold", "size": 44, "tracking": 200, "case": "upper",
           "max_lines": 1, "color": "#111111", "plate": {"color": "#FFFFFF", "padding": 22, "radius": 60},
           "frame": {"anchor": "top", "height": 0.06, "y": 0.012}},
          {"type": "text", "id": "title", "text": "{title}", "weight": "black", "size": 230, "min_size": 80, "max_lines": 3,
           "line_height": 0.9, "color": "auto", "frame": {"anchor": "center", "height": 0.36}, "avoid": ["faces", "subject"],
           "shadow": {"color": "#00000033", "blur": 24, "y": 6}},
          {"type": "text", "id": "date", "text": "{date}", "weight": "semibold", "size": 64, "max_lines": 1, "color": "auto",
           "frame": {"anchor": "top", "height": 0.07, "below": "title", "gap": 0.03}}
        ]
      }
    ]
    """#
}
