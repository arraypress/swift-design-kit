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
| `background` | A fill, which can be a colour, a `linear`/`radial` blend, a GradientKit wallpaper (`seed`, `palette`, `motif`), a picture file, or a picture made from words (`ai`: model, revision, seed, shape, prompt, style). Treatments: `fit`, `blur`, `darken`, `scrim` (bottom, top, both, or `auto`, which is measured), `grade` (an img/vid look, inline or a file), `duotone`, `gradient_map`, `grain`, `vignette`, `upscale`. |
| `text` | Words with `{slot}` markers and `**accent**` / `*italic*` / `~muted~` spans. Options: `font` (a role — `display` or `text`, set by the design's pairing — any family installed on this Mac, the bundled `inter` / `source-serif` / `jetbrains-mono`, an open font fetched on first use, or a `.ttf`/`.otf`), `weight` (`thin` … `black`; a role's own weight when left out), `size` (design units, or a step of the type scale: `caption`, `body`, `lead`, `subtitle`, `title`, `headline`, `display`, `giant`), `min_size`, `max_lines`, `fit: shrink`, `tracking`, `line_height`, `case`, `align`, `valign`. Colour: `color`, which can be `auto` (picked from the art), a palette role (`accent`, `light`…), or a `gradient`. Also `stroke` (outline or hollow), `plate` (whole block or per line, with `auto` drawing only as much plate as WCAG 4.5:1 needs), and `avoid`: `faces`, and `subject` (the main subject of the art under the words, as Vision lifts it, plus any cut-out picture). |
| `image` | A picture file, or its subject lifted out (`cutout`, with `edge`: `crisp` by default, `soft` or `feather:N`, and `choke`). Options: `fit`/`focus`, `mask` (rect, rounded, circle, polygon), and `stroke`, which follows the mask or draws a sticker outline round a cut-out. |
| `shape` | `rect`, `rounded`, `ellipse`, `line`, `polygon`, `star`; frames and borders — `frame` (an inset border, `radius` for round corners), `double-frame` (two rules `gap` apart), `brackets` (corner marks), `film-strip` (sprocket edges); `arrow`, `ring`, `burst`, `badge` (a scalloped seal) and `divider`. A fill (a colour or a palette role), a `gradient`, or a `stroke` (with `dash`). |
| `texture` | `paper`, `halftone` (dots growing toward `angle`), `noise`, `scanlines` or `dust` (specks and hairs), drawn from a `seed` in one `color` at a `scale` and `density` — made to be blended over what is under it. |
| `qr` | A link or text as a QR code (QRKit). |
| `group` | Layers placed inside the group's frame and composited as one. |

Every layer also takes `id`, `frame`, `opacity`, `blend`, `rotation`,
`shadow`, `glow` and `fade` (out toward an edge, or `radial`, between a
`start` and an `end`). Blends: normal, multiply, screen, overlay, darken,
lighten, color-dodge, color-burn, soft-light, hard-light, difference,
exclusion, hue, saturation, color, luminosity, linear-burn, linear-dodge — the
same in a PNG and a PDF (PDF has no linear burn or dodge; CoreGraphics' PDF
context draws them as it can). A background also takes `gradient_map`: its
tones mapped through two or more colours, darkest first.

**Type is a pairing, not a face per layer.** A design's `fonts` names a
pairing (`design pairings`): a display face and a text face that go together,
and a type scale. Each role lists candidates — faces macOS ships first, then
the bundled ones, then open fonts — and the first that is here (or can be
fetched) is pinned in the made design, so a replay sets the same faces. Text
layers say `"font": "display"` or `"text"`. Thirteen pairings: modern,
editorial (Didot over Avenir Next), literary (Big Caslon over Baskerville),
swiss (Helvetica Neue), geometric (Futura over Avenir Next), condensed (Bebas
Neue), poster (Anton), retro (Shrikhand over American Typewriter), brutalist
(Archivo Black over Space Mono), cinema, soft-serif (Fraunces over DM Sans),
fashion (Bodoni 72 over Futura), technical. `Fonts.installed` / `FontCatalog`
list every installed family with its styles, a category (serif, sans, mono,
display, script, symbol, from CoreText's class and monospace bit) and a few
words for its feel. **Open fonts** (31 OFL families from google/fonts at a
pinned commit, each file's SHA-256 recorded) are fetched through the
services' `FontFetching` on first use; nothing is bundled. A face whose
OS/2 embedding bits forbid embedding is drawn as pictures in a PDF.

**Colours are roles from the art.** The palette is found in the art with
ImagePalette (OKLab k-means): `dominant` and `secondary` by share, `accent`
by a harmony rule (`auto` takes the art's own most colourful colour 60° or
more round the wheel, else `complementary`; also `analogous`, `split`,
`mono`), and `neutral`, `light`, `dark` tinted with the dominant's hue. A
design's `palette` picks the rule or pins any role. Words in a hued role keep
its hue and move its lightness until they read; `light` and `dark` stay at
their end of the scale (the other one is taken when one does not read, never a
mid grey).

**Frames are rules, not pixels.** A frame has:
- an `anchor` (nine points) in an `area` (`safe`, `trim`, or `bleed`, which is
  the default for backgrounds);
- a `width`/`height` as fractions of that area, or an `aspect`;
- a `margin`;
- a column span (`columns: [first, count]` over the design's `grid`);
- or a place `below`/`above` an earlier layer by its id. Text is measured by
  its drawn lines, not its box.

**`avoid` moves words off what they would cover.** Faces (Vision's face
boxes) and the subject (Vision's foreground mask, the subject's own pixels:
the microphone and its cable, not the desk) are looked for in the art under
the text — backgrounds and pictures only, never other words or shapes — and
the text's lines are measured against them. Over 1% covered, every other
anchor is tried at full width, and alignment that hugged the old anchor
follows the new one (a title set left at top-left is set right at
top-right); the first that clears wins, else the one that covers least. Only
when no anchor clears is the frame narrowed (80%, 60%, 45%, 35% of its
width, each anchor in turn), and only to clear. A place that does not fit or
puts the words on other words is never taken. Shapes and codes drawn under
the words (a label strip, a starburst) hide the subject: words on them are
not on it. The starters whose words sit
over the art (`cover-clean`, `podcast-cover`, `gig-poster`,
`youtube-thumbnail`, `story-announcement`) avoid both.

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
| swift-object-cutout | Subject lift (Vision), crisp decontaminated edges (1.3). |
| swift-psd-kit | The layered PSD writer. |
| swift-media-kit ImagePalette | Colours from the art, for `color: auto`. |
| swift-qr-kit | QR codes. |
| swift-document-theme | The bundled fonts (OFL). |
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
| read-back | On-device text recognition reads back fewer of the words than were drawn. When recognition cannot run at all (a busy Neural Engine; it is retried, then run on the CPU), the result is "not measured", never "unreadable". |
| print-size | Text prints under 6 pt (fail) or under 8 pt (warning). |
| resolution | A picture is drawn more than 1.25× its pixels. |
| bleed | A print page has less than 3 mm of bleed, or a picture that does not reach the bleed edge. |
| platform | The page breaks the preset's size rules, for example a cover under 3000×3000. |
| unfilled | A `{slot}` has no value. |
| subject | More than 2% of a text layer's letters lie on the subject of the art under it (`onSubject` in each text measure, `0` when there is no subject, `null` when Vision could not run). The fix names `avoid: ["subject"]` when the layer does not have it. Warning only. |
| families | The words use more than two type families. Warning only. |
| colors | Words and shapes use more than three colours (a palette role counts once; colours within 0.1 in OKLab count once). Warning only. |
| embedding | A face's licence bits forbid embedding it: the PDF draws its words as pictures. Warning only. |
| avoid | A layer that avoids faces or the subject still covers them and no placement clears it. Warning only. |

Measured on this machine:
- The same design writes byte-identical PNGs across runs, processes, and
  debug and release builds (golden hash in the tests).
- GradientKit backgrounds are identical per seed (on the same GPU).
- The engine renders a 3000² cover with its checks in about 4 s in a release
  build.
- The first OCR call in a new program waits about a minute while Vision loads
  its recogniser. After that it is quick.
- The subject mask takes about 0.2 s. On the generated "Slow Signal" podcast
  cover (FLUX.2 Klein 4B, seed 5) the mask is the microphone and its cable,
  12% of the picture; the title had 17% of its letters on it, and with
  `avoid: ["subject"]` it is narrowed at top-left to 35% of its width: 0%.
  A flat colour or a plain gradient lifts no subject: across the 12
  starter templates on their gradient backgrounds, nothing moved and every
  layer measured 0% on a subject.
- The 17 starters (0.3) on their gradient defaults pass every check with no
  warning: contrast, read-back, safe area, two families, three colours. On
  the generated backgrounds of the 0.1 showcase (1024 px, drawn without
  enlarging), words fail to read back in three — the stroked condensed
  thumbnail headline (25%), a seal's two words (50%) and a flyer's small
  details line (60%); the retro title over a bright greenhouse read 0% until
  its gradient map stopped short of cream (now 100%) — and two set words on
  the subject where no placement clears it; the checks say so, with the fix.
- A cut-out's edge is crisp and carries no background (swift-object-cutout
  1.3): on the showcase's generated portrait the old 7 px halo of wall colour
  round the hair is gone.

## Layered PSD

`Exporter.write(rendered, to: url, format: .psd)` writes a layered Photoshop
file through swift-psd-kit: each layer drawn alone at full size (its shadow,
glow and fade with it), with its id as its name, its opacity and its blend
mode; a group becomes a folder (one that casts a shadow, glows or fades is one
layer). Words are pixels — PSDKit does not write Photoshop's type-engine data.
`LayeredExport.notes` says what the file could not carry.

Measured on the 17 starters (3000² and up, gradient backgrounds): the merged
image `psd render` reads is the design's PNG byte for byte (17 of 17); `psd
render --layers` (PSDKit flattening the layers itself) is within a mean of
0.29/255 of it (p99 ≤ 1, max 2); psd-tools 1.25 lists the same layers and its
own flattening is within a mean of 0.5 (p99 ≤ 2, max 2). Per blend mode (a three-colour gradient at 0.8
over a two-colour blend, 400²), PSDKit's Photoshop arithmetic against
CoreGraphics: 13 modes within a mean of 0.6/255 (p99 ≤ 4); soft light mean
3.8 (CoreGraphics draws Pegtop's curve, Photoshop its own); colour dodge 19.9,
linear dodge 17.8, colour burn 6.1, linear burn 5.6 — CoreGraphics applies a
layer's opacity before it clamps, Photoshop after, so where the result clips
they part. The PSD keeps the mode; Photoshop shows its own version of it.

## Requirements

macOS 27 / iOS 27, because the AI product runs on Core AI. Swift 6.2. Made
backgrounds use the models `imagine` installs (FLUX.2 Klein 4B, SANA Sprint
1.6B). Core AI compiles a model per program the first time that program
loads it, so the first made background in a new tool takes a few minutes.
The engine (`DesignKit`) builds for the iOS Simulator. The AI product does
not, because the simulator SDK has no Core AI.

## License

MIT, see [LICENSE](LICENSE). The bundled fonts are OFL (in DocumentTheme).
Open fonts are fetched, not bundled, each with its OFL.txt; installed system
fonts are used in place and only ever leave as drawn glyphs (or embedded in a
PDF where their licence bits allow).
