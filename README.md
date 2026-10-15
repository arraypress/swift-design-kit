# swift-design-kit

One-page designs, such as cover art, flyers, posters, thumbnails and story
cards, made by an agent or a person and drawn headlessly. A design is a
strict JSON recipe: a canvas, an ordered list of layers laid out by rule,
and the values a template's slots were filled with. Made pictures are pinned
in it, so the same recipe on the same build draws the same pixels. Every
render is checked blind: contrast, OCR read-back, clipping, safe area, print
size, resolution, bleed and platform rules, each measured on the drawn pixels.

The `design` CLI is built on it. The engine (`DesignKit`) imports no UI
framework and no Core AI, so a future iPhone app can reuse it. The AI product
(`DesignKitAI`) draws backgrounds and enlarges pictures on this Mac.

## The model

| Layer | What it draws |
|---|---|
| `background` | A fill, which can be a colour, a `linear`/`radial` blend, a GradientKit wallpaper (`seed`, `palette`, `motif`), a picture file, or a picture made from words (`ai`: model, revision, seed, shape, prompt, style). Treatments: `fit`, `blur`, `darken`, `scrim` (bottom, top, both, or `auto`, which is measured), `grade` (an img/vid look, inline or a file), `duotone`, `grain`, `vignette`, `upscale`. |
| `text` | Words with `{slot}` markers and `**accent**` / `*italic*` / `~muted~` spans. Options: `font` (system, the bundled `inter` / `source-serif` / `jetbrains-mono`, or a `.ttf`/`.otf`), `weight`, `size`, `min_size`, `max_lines`, `fit: shrink`, `tracking`, `line_height`, `case`, `align`, `valign`. Colour: `color`, which can be `auto` (picked from the art), or a `gradient`. Also `stroke` (outline or hollow), `plate` (whole block or per line, with `auto` drawing only as much plate as WCAG 4.5:1 needs), and `avoid` (faces or a cut-out subject). |
| `image` | A picture file, or its subject lifted out (`cutout`). Options: `fit`/`focus`, `mask` (rect, rounded, circle, polygon), and `stroke`, which follows the mask or draws a sticker outline round a cut-out. |
| `shape` | `rect`, `rounded`, `ellipse`, `line`, `polygon` or `star`, with a fill, a `gradient` or a `stroke`. |
| `qr` | A link or text as a QR code (QRKit). |
| `group` | Layers placed inside the group's frame and composited as one. |

Every layer also takes `id`, `frame`, `opacity`, `blend` (normal, multiply,
screen, overlay, soft-light), `rotation`, `shadow` and `glow`.

**Frames are rules, not pixels.** A frame has:
- an `anchor` (nine points) in an `area` (`safe`, `trim`, or `bleed`, which is
  the default for backgrounds);
- a `width`/`height` as fractions of that area, or an `aspect`;
- a `margin`;
- a column span (`columns: [first, count]` over the design's `grid`);
- or a place `below`/`above` an earlier layer by its id. Text is measured by
  its drawn lines, not its box.

**Sizes are design units:** a thousandth of the trimmed page's shorter side.
`size: 80` is 8% of it at every size, from a 1080 post to an A3 poster.

## Use

```swift
import DesignKit
import DesignKitAI

let template = StarterTemplates.named("cover-clean")!
let design = try Making.design(from: template, values: ["title": "Night Drive",
                                                        "background": "imagine:rain-soaked neon street"])
let services = DesignServices(generator: MachineImages(), upscaler: MachineUpscaler())
let rendered = try await DesignEngine.render(design, services: services)
try Exporter.write(rendered, to: URL(fileURLWithPath: "cover.png"), format: .png)
rendered.report.findings            // what the checks found, each with its fix
try Recipes.save(rendered.prepared.design, to: recipeURL, from: folder, overwrites: false)
```

- **Changes:** `Recipes.set("title=Night Drive (Remix)", in: design)` changes a
  slot. `background.seed=8` changes a field found by its last name.
  `background=imagine:…` changes what a layer draws, and a full dotted path
  also works.
- **Variants:** `Variants.seeded(design, seeds:)` and `Variants.contactSheet`
  give several backgrounds to pick from.

## Built on

| Library | What it gives |
|---|---|
| [swift-canvas-kit](https://github.com/arraypress/swift-canvas-kit) | The text engine (CoreText, auto-shrink, strokes, gradient glyphs), fonts, image loading, grading, blur and scrims. design-kit adds the compositor, layout, checks and print. |
| swift-gradient-kit | Gradient backgrounds. It needs Metal. |
| swift-object-cutout | Subject lift (Vision). |
| swift-media-kit ImagePalette | Colours from the art, for `color: auto`. |
| swift-qr-kit | QR codes. |
| swift-document-theme | The bundled fonts. |
| swift-video-grade VideoGradeLook | Look files shared with img and vid. |
| swift-legibility | Ink box, letter-ring contrast and OCR read-back. |
| swift-recipe-kit | Strict recipes, `--set` and slots. |
| swift-image-generation, swift-upscale | Made backgrounds and SwinIR enlargement, in DesignKitAI. |

## Checks

These are measured, never judged:

| Check | What fails it |
|---|---|
| clipped / safe-area | The text layer's own ink (outline, shadow and plate included) reaches past the page or the safe area. |
| fit | The text does not fit even at `min_size`. |
| contrast | The median luminance of the letters against a 3-unit ring round them falls below 3:1 for type 30 units and up, or 4.5:1 below that. The fix names the plate that would reach the target. |
| read-back | On-device text recognition reads back fewer of the words than were drawn. |
| print-size | Text prints under 6 pt (fail) or under 8 pt (warning). |
| resolution | A picture is drawn more than 1.25× its pixels. |
| bleed | A print page has less than 3 mm of bleed, or a picture that does not reach the bleed edge. |
| platform | The page breaks the preset's size rules, for example a cover under 3000×3000. |
| unfilled | A `{slot}` has no value. |

Measured on this machine:
- The same design writes byte-identical PNGs across runs, processes, and
  debug and release builds (golden hash in the tests).
- GradientKit backgrounds are identical per seed (on the same GPU).
- The engine renders a 3000² cover with its checks in about 4 s in a release
  build.
- The first OCR call in a new program waits about a minute while Vision loads
  its recogniser. After that it is quick.

## Requirements

macOS 27 / iOS 27, because the AI product runs on Core AI. Swift 6.2. Made
backgrounds use the models `imagine` installs (FLUX.2 Klein 4B, SANA Sprint
1.6B). Core AI compiles a model per program the first time that program
loads it, so the first made background in a new tool takes a few minutes.
The engine (`DesignKit`) builds for the iOS Simulator. The AI product does
not, because the simulator SDK has no Core AI.

## License

MIT, see [LICENSE](LICENSE). The bundled fonts are OFL (in DocumentTheme).
