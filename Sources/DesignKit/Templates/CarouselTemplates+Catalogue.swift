//
//  CarouselTemplates+Catalogue.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  Starter carousels: a cover, a page per item, an end page, over one
//  background that runs across every page. Copy is invented.
//

extension CarouselTemplates {

    static let json = #"""
    [
      {
        "name": "carousel-steps",
        "summary": "How-to carousel: a big title, one numbered step a page in a heavy grotesque, a closing call — over one gradient that flows across all the pages",
        "preset": "ig-portrait",
        "pairing": "modern",
        "repeat": "steps",
        "slots": [
          {"name": "title", "summary": "what the carousel teaches", "default": "Five ways to finish a song"},
          {"name": "steps", "summary": "the steps, split by |", "default": "Set a deadline | Bounce it every night | Steal one idea | Cut the second verse | Ship it on Friday"},
          {"name": "cta", "summary": "the last page's call", "default": "Save this for your next session"},
          {"name": "handle", "summary": "who posted it", "default": "@slowsignal"},
          {"name": "background", "summary": "the art across every page", "default": "gradient:seed=31,palette=reactor,motif=flow"}
        ],
        "background": {"type": "background", "fill": "{background}", "darken": 0.45, "grain": 0.06},
        "cover": [
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 150, "min_size": 60, "max_lines": 4, "line_height": 0.95,
           "align": "left", "valign": "bottom", "color": "light", "frame": {"anchor": "bottom-left", "height": 0.55, "width": 0.92}},
          {"type": "text", "id": "swipe", "text": "{count} steps  →", "font": "text", "weight": "bold", "size": 34, "tracking": 120, "case": "upper",
           "align": "left", "color": "light", "frame": {"anchor": "top-left", "height": 0.06}}
        ],
        "each": [
          {"type": "text", "id": "number", "text": "{n}", "font": "display", "size": 420, "align": "left", "valign": "top", "color": "accent",
           "frame": {"anchor": "top-left", "width": 0.6, "height": 0.4}},
          {"type": "text", "id": "step", "text": "{item}", "font": "display", "size": 110, "min_size": 50, "max_lines": 4, "line_height": 1,
           "align": "left", "valign": "top", "color": "light", "frame": {"anchor": "top-left", "height": 0.4, "y": 0.42}},
          {"type": "text", "id": "page", "text": "{n} / {count}", "font": "text", "weight": "medium", "size": 28, "align": "right",
           "color": "light", "frame": {"anchor": "bottom-right", "width": 0.3, "height": 0.05}}
        ],
        "end": [
          {"type": "text", "id": "cta", "text": "{cta}", "font": "display", "size": 120, "min_size": 50, "max_lines": 4, "align": "left",
           "color": "light", "frame": {"anchor": "left", "height": 0.5}},
          {"type": "text", "id": "handle", "text": "{handle}", "font": "text", "weight": "bold", "size": 40, "align": "left",
           "color": "accent", "frame": {"anchor": "bottom-left", "height": 0.07}}
        ]
      },
      {
        "name": "carousel-editorial",
        "summary": "Editorial carousel: a serif headline cover, one quoted point a page under a hairline with a page count, a sign-off — on cream paper",
        "preset": "ig-portrait",
        "pairing": "editorial",
        "repeat": "points",
        "slots": [
          {"name": "title", "summary": "the headline", "default": "Notes on making quiet records"},
          {"name": "points", "summary": "the points, split by |", "default": "Leave room for the room | Record the mistake twice | Mix at the volume people listen | Finish before you are sure"},
          {"name": "byline", "summary": "who wrote it", "default": "Elin Marsh"},
          {"name": "background", "summary": "the paper", "default": "#F2ECE1"}
        ],
        "background": {"type": "background", "fill": "{background}", "grain": 0.05},
        "cover": [
          {"type": "text", "id": "title", "text": "{title}", "font": "display", "size": 130, "min_size": 60, "max_lines": 4, "line_height": 1,
           "color": "#1B1A17", "frame": {"height": 0.5}},
          {"type": "text", "id": "byline", "text": "by {byline}", "font": "text", "weight": "medium", "size": 32, "tracking": 200, "case": "upper",
           "color": "#1B1A17", "frame": {"anchor": "bottom", "height": 0.06}}
        ],
        "each": [
          {"type": "text", "id": "count", "text": "{n} of {count}", "font": "text", "weight": "medium", "size": 28, "tracking": 200, "case": "upper",
           "color": "#8A8172", "frame": {"anchor": "top", "height": 0.05}},
          {"type": "shape", "id": "rule", "shape": "line", "stroke": {"color": "#1B1A17", "width": 2}, "frame": {"anchor": "top", "width": 0.2, "height": 0.01, "y": 0.08}},
          {"type": "text", "id": "point", "text": "“{item}”", "font": "display", "size": 120, "min_size": 50, "max_lines": 5, "line_height": 1.05,
           "color": "#1B1A17", "frame": {"height": 0.6}}
        ],
        "end": [
          {"type": "text", "id": "signoff", "text": "{byline}", "font": "display", "size": 110, "color": "#1B1A17", "frame": {"height": 0.3}}
        ]
      }
    ]
    """#
}
