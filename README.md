# swift-design-kit

One-page designs, such as cover art, flyers, posters, thumbnails and story
cards, made by an agent or a person and drawn headlessly. A design is a
strict JSON recipe: a canvas, an ordered list of layers laid out by rule,
and the values a template's slots were filled with. Made pictures are pinned
in it, so the same recipe on the same build draws the same pixels. Every
render is checked blind: contrast, OCR read-back, clipping, safe area, print
size, resolution, bleed and platform rules, each measured on the drawn pixels.

The `design` CLI is built on it. The engine (`DesignKit`) imports no UI
framework and no Core AI of its own, so a future iPhone app can reuse it
(its cut-out dependency now needs Core AI — see Requirements). The AI product
(`DesignKitAI`) draws backgrounds and enlarges pictures on this Mac.

## The model

| Layer | What it draws |
|---|---|
| `background` | A fill, which can be a colour, a `linear`/`radial` blend, a GradientKit wallpaper (`seed`, `palette`, `motif`), a picture file, or a picture made from words (`ai`: model, revision, seed, shape, prompt, style). Treatments: `fit`, `blur`, `darken`, `scrim` (bottom, top, both, or `auto`, which is measured), `grade` (an img/vid look, inline or a file), `duotone`, `gradient_map`, `grain`, `vignette`, `upscale`, and `edit`: the picture changed in place by words on this machine (FLUX.2 Klein 4B; pinned like a made picture). |
| `text` | Words with `{slot}` markers and `**accent**` / `*italic*` / `~muted~` spans. Options: `font` (a role — `display` or `text`, set by the design's pairing — any family installed on this Mac, the bundled `inter` / `source-serif` / `jetbrains-mono`, any of ~2,000 Google Fonts families fetched on first use, or a `.ttf`/`.otf`), `weight` (`thin` … `black`; a role's own weight when left out), `size` (design units, or a step of the type scale: `caption`, `body`, `lead`, `subtitle`, `title`, `headline`, `display`, `giant`), `min_size`, `max_lines`, `fit: shrink`, `tracking`, `line_height`, `case`, `align`, `valign`. Colour: `color`, which can be `auto` (picked from the art), a palette role (`accent`, `light`…), or a `gradient`. Also `stroke` (outline or hollow), `plate` (whole block or per line, with `auto` drawing only as much plate as WCAG 4.5:1 needs), and `avoid`: `faces`, and `subject` (the main subject of the art under the words, as Vision lifts it, plus any cut-out picture). Fine type (see Typography): `axes`, `features`, `letters`, `path`, `extrude`, `inline`. |
| `image` | A picture file, or its subject lifted out (`cutout`, with `edge`: `crisp` by default, `soft` or `feather:N`, and `choke`). Options: `fit`/`focus`, `mask` (rect, rounded, circle, polygon), and `stroke`, which follows the mask or draws a sticker outline round a cut-out. |
| `shape` | `rect`, `rounded`, `ellipse`, `line`, `polygon`, `star`; frames and borders — `frame` (an inset border, `radius` for round corners), `double-frame` (two rules `gap` apart), `brackets` (corner marks), `film-strip` (sprocket edges); `arrow`, `ring`, `burst`, `badge` (a scalloped seal) and `divider`. A fill (a colour or a palette role), a `gradient`, or a `stroke` (with `dash`). |
| `texture` | `paper`, `halftone` (dots growing toward `angle`), `noise`, `scanlines` or `dust` (specks and hairs), drawn from a `seed` in one `color` at a `scale` and `density` — made to be blended over what is under it. |
| `qr` | A link or text as a QR code (QRKit). |
| `group` | Layers placed inside the group's frame and composited as one. |
| `list` | Names or titles fitted into the frame: a festival line-up by billing tier, a tracklist, credits (see Lists). |

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
words for its feel. **Google Fonts**: every family in google/fonts at one
pinned commit — 2,021 families under the OFL, Apache 2.0 and the Ubuntu Font
Licence, each with its styles, variable axes, and the SHA-256 of every file
and of its licence file (`GoogleFontIndex.swift`, generated by
`Scripts/google-fonts-index.py`; 35 folders with no METADATA.pb or no licence
file are left out) — are fetched through the services' `FontFetching` on
first use, the licence kept beside the fonts; nothing is bundled. A text
layer names one by its name (`"font": "Space Mono"`); the made design
records the commit (`google_fonts`), and a replay on a build that fetches
from another commit warns. `OpenFonts.search` / `FontCatalog.google` list
them. 31 are chosen for the pairings. A face whose OS/2 embedding bits
forbid embedding is drawn as pictures in a PDF.

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
- **Faces by name:** `--var font="Space Mono"` (both roles), `display-font=`,
  `text-font=` in `Making.design` values, and the same names in `Recipes.set`.
- **Sets:** `ReleaseKit.adapted(design, to: "story")` — see Release kits.
- **Brands:** `Brands.applied(brand, to: design)` — see Brands.
- **Output:** `Exporter.write(rendered, to:, format: .svg)`, or `.pdf` with
  `cmyk: true`; `PrintColor.gamut(of:inks:)`.
- **Critique:** `Critic.critique(rendered, name:)` — a one-line verdict.

## Typography

| Key | What it does |
|---|---|
| `axes` | Variable-font axes: `{"weight": 760, "width": 85, "slant": -8, "optical-size": 72}` or any four-letter tag (`SOFT`, `WONK`). |
| `features` | OpenType features through CoreText: `small-caps`, `all-small-caps`, `no-ligatures`, `discretionary-ligatures`, `tabular`, `proportional`, `oldstyle`, `lining`, `slashed-zero`, `fractions`, `ordinals`, `swash`, `titling`, `alternates`, `ss01`…`ss20`, any tag, `-tag` for off. Written back as tags. |
| `letters` | Styling for some letters: picked by `range` `[from, to)`, `word` (from 1; −1 the last) or every `match`, each with `color`, `size` (a multiple), `weight`, `baseline` (a lift, as a share of the size) and `tracking`. Counted in the words as drawn. |
| `path` | Words set along `arc` (`bend` −1…1: a rainbow or a smile), `circle` (centred at `start`, degrees from the top) or `wave` (`waves`, `amplitude`). One line, shrunk to the path's length. |
| `extrude` | Depth: copies stacked back along `angle` (`135`: down and right), `depth` units deep, the `color` of the sides (`auto`: the letters darkened), `shade` darker at the back. |
| `inline` | A line `width` thick running `inset` inside the letters' edge (an outline alone is `stroke` with `"style": "hollow"`). |

The engine for all of it is CanvasKit 0.7 (`TextStyle.variations`,
`.features`, `.characterStyles`, and `TextDrawer.outlines`/`line`, which
hand back the laid-out glyphs as outlines). Every layer is measured by the
same checks. A feature or axis the face does not have changes nothing in
CoreText; the checks find that by laying the words out with and without it
and comparing the glyphs (`features`, `axes` warnings). Measured:
- Glyph outlines land where CoreText draws the words: mean 0.77/255 over a
  line with an accent run and a scaled, lifted range (font smoothing off),
  under 2% of the ink.
- Read-back of curved words ("Deep Signal Radio", Avenir Next bold, 2000²):
  arcs bent 0.15, 0.3, 0.5 and −0.3, −0.6, and waves of amplitude 0.2 and
  0.5 read 100%; an arc bent 0.8, a wave of 0.9 and a full circle read 33%.
  Recognition reads straight lines, so on a path a low read-back is a
  warning, never a failure.
- Contrast of extruded letters is measured against what touches them,
  their own sides included: pink letters over sides of the same pink
  darkened measured 2.6:1 (fail); over near-black sides, 5.3:1. An inline
  through the stems cut read-back of "DEEP SIGNAL" to 50%.
- An inline is a filled shape (the letters' outline stroked, less the inner
  stroke, kept inside them) — no transparency layer, so a CMYK PDF keeps it in
  CMYK and an SVG writes it as one path.

## Lists

`"type": "list"`: `items` is an array (`"Name"`, or `{"text", "tier",
"detail"}`) or text with `{slot}` markers — `|` or new lines between items,
`||` (or a blank line) between billing tiers, `::` before a detail.
`flow: inline` (a line-up) runs each tier's items on with a `separator`
(`·`), breaking into the fewest lines and then evening them out (the widest
line as narrow as it can be); `flow: lines` (a tracklist) puts one item a
line in `columns`, `numbered` `01`, `02`…, with its `detail` set right.
`sizes` per tier (top billing first), `weights`, `separator_color`,
`detail_color`, `align`, `case`, `tracking`, `line_height`, `min_scale`. The
largest share of the sizes at which every item fits whole is taken (each
tier shrunk alike); the lines are then drawn and checked as text layers
(`<id>-1`, `<id>-2`…), and a list that does not fit even at `min_scale`
fails `list`. The recipe keeps the list, never its lines. Measured on the
fixture line-up (A3, Bebas Neue): every line fits, reads back 100%, and the
headliner comes out at 168 units, the second tier at 97, the third at 62.

## Release kits

`ReleaseKit.adapted(design, to: size)` puts one design on another page:
`cover` (3000²), `square` (1080²), `portrait` (1080×1350), `story`
(1080×1920), `youtube` (1280×720), `banner` (1500×500), `podcast`, or any
preset. Layout is already by rule, so the design is laid out again rather
than stretched; on a wide page, whose short side is short, words are set up
to 1.5× larger (the square root of width over height) and shrink to their
frames. Growing the frames too was tried and dropped: stacks built with
`above`/`below` broke (a podcast host line climbed off its band and failed
contrast). A made background is the same picture on every page, cropped to
fill. `design set` writes each size, a contact sheet and each size's checks;
the podcast cover's six sizes all pass.

## Brands

A `Brand` (name, logo, colours by palette role, a pairing or two faces, a
corner, a logo width) laid over any design by `Brands.applied`: the colours
are pinned on the palette roles the templates already colour words and
shapes by, so a brand recolours any template; the type becomes the design's;
the logo fills a `logo` layer, or goes in the first corner (then side) its
words leave clear. Plain colours fill the roles in order: accent, secondary,
light, dark, dominant, neutral. **By value, not by reference**: the colours,
faces and logo path are written into the design itself (with `"brand"` for
the record), so a recipe replays the same after the brand is edited or
removed — a reference would silently restyle every old recipe. The CLI keeps
each logo under a name made from its SHA-256, so no edit ever overwrites a
file a recipe points at.

## SVG and CMYK

| Format | Keeps | Loses |
|---|---|---|
| PNG / JPEG | Everything, as pixels. | Nothing; JPEG has no transparency. |
| PDF | Words as text (embedded where licence bits allow), shapes as paths, print boxes and crop marks. | Linear dodge/burn are drawn as CoreGraphics can. |
| PDF `cmyk` | As PDF, every colour and picture converted to the Generic CMYK Profile by ColorSync (pictures perceptual, inks relative colorimetric), with a PDF/X output intent; large opaque pictures carried as CMYK JPEG. | Layers with opacity, a blend, shadow, glow, fade or a group are blended in an RGB transparency group (CoreGraphics' PDF writer has no CMYK blending space); `PrintColor.notes` says so. |
| SVG | Shapes as paths, words as `<text>`/`<tspan>` per line and run (face, size, weight, colour, tracking, `font-variation-settings`, `font-feature-settings`), rotation, opacity, CSS blend modes, shadows as `feDropShadow`, fades as masks, Google faces embedded as `@font-face`. | Backgrounds, pictures, textures and codes are embedded pictures (JPEG when opaque, PNG otherwise); words on a path, extruded or inlined are outlines; a group with a shadow, glow or fade is one picture; linear dodge/burn draw normally; a Mac's own faces are named, not embedded. |

Measured: the cover-clean SVG drawn by WebKit (Quick Look) against the PNG,
mean 2.1/255 (the JPEG background's noise); the typography fixture (small
caps, old-style figures, an arc, a wave, extrusion, inline), 1.4/255; by
librsvg, 1.9 and 2.1 — but librsvg reads neither `@font-face` nor
`font-feature-settings`, so a Google face falls back there (23/255 on the
Bebas Neue line-up). A CMYK PDF of the line-up and the typography fixture holds
only `/N 4` ICC and DeviceCMYK colour spaces (no RGB), 18.8 MB against 36.7
for RGB. The gamut report sends every pixel (at 400 px) and every word and
shape colour to CMYK and back: past ΔE76 10 (about four times what a careful
eye notices) is out of gamut — #00FF00 is, mid grey and #FFD166 are not; the
typography fixture had 0.8% of its pixels out.

## Critique

`Critic.critique` judges a finished design in a line: the first failed
check, the weakest contrast, the lowest read-back, words on the subject, the
type hierarchy (the largest size over the next one down: 1.5× and up reads as
a title), whether every block of words shares an edge or a centre with
another block, the safe area or the page (by its ink, or by the edge its
alignment holds — large type's side bearings keep ink off that edge), whether
centred words sit centred (side margins within 2:1), and how many faces and
colours. Accents — words turned on their own, words on a small shape (a
burst, a tag) and one- or two-character ornaments — are their own unit and
left out of the layout measures. A failed check is blocking; the layout
measures warn. Calibrated on the 17 starters, each reviewed by eye: all 17
pass every measure (before accents were set apart, five were flagged — a
tilted badge, a burst, a tag, a quotation mark, and "Hush"'s side bearing).

## AI layers

Both run on this Mac only when a design asks, one model at a time, and are
pinned in the recipe:
- **`edit`** on a background: FLUX.2 Klein 4B's edit path changes the picture
  in place (`"edit": "make it night"`, `strength` 0.75 by default: low keeps
  the layout). The model, revision, shape and seed are written when made, and
  the result is cached by its pin and the source's pixels, so a replay draws
  the same bytes (measured: identical). A gradient edited into "a snowy night
  sky over a frozen lake" at 1500²: 2 min 24 s with the model load.
- **Upscale to print size**: on a print page an image layer or a picture
  background under print resolution is enlarged ×4 with SwinIR by default
  (`upscale: false` opts out; on screen it stays opt-in), and the recipe
  records `upscaled_with: swinir@<revision>`; a replay enlarged by another
  upscaler warns (`upscaler`).

## Built on

| Library | What it gives |
|---|---|
| [swift-canvas-kit](https://github.com/arraypress/swift-canvas-kit) 0.7 | The text engine (CoreText, auto-shrink, strokes, gradient glyphs, variable axes, OpenType features, character styles, glyph outlines, CMYK inks), fonts, image loading, grading, blur and scrims. design-kit adds the compositor, layout, checks and print. |
| swift-gradient-kit | Gradient backgrounds. It needs Metal. |
| swift-object-cutout | Subject lift — BiRefNet when installed (1.4), else Vision — with crisp decontaminated edges. |
| swift-psd-kit | The layered PSD writer. |
| swift-media-kit ImagePalette | Colours from the art, for `color: auto`. |
| swift-qr-kit | QR codes. |
| swift-document-theme | The bundled fonts (OFL). |
| swift-video-grade VideoGradeLook | Look files shared with img and vid. |
| swift-legibility | Ink box, letter-ring contrast and OCR read-back. |
| swift-recipe-kit | Strict recipes, `--set` and slots. |
| swift-image-generation, swift-upscale | Made backgrounds and SwinIR enlargement, in DesignKitAI. |
| swift-depth-estimator, swift-inpaint | Depth Anything and LaMa for parallax loops, in DesignKitAI. |

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
| list | A list does not fit its frame even at `min_scale`. |
| features / axes | An OpenType feature changes no glyph of these words in this face, or the face has no such axis. Warning only. |
| fonts | The recipe's Google faces were fetched at another google/fonts commit than this build's. Warning only. |
| upscaler | A picture the recipe had enlarged with one upscaler was enlarged with another. Warning only. |

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

## Carousels

A `Carousel` (`"carousel": 1`) is several pages of one canvas sharing their
slots, type and palette, with one `background` drawn across all of them: each
page's background gets `span: [page, pages]`, the art is drawn once at the
whole strip's width (a gradient for the strip's shape, a picture filled to it)
and each page takes its slice, so it runs on as the pages are swiped
(measured: a black-to-white blend across two 200 px pages meets within 3/255
at the seam). `Carousels.sharedPalette` finds the palette roles once in the
whole strip and pins them, so `accent` is one colour on every page.
`CarouselTemplate`s (`carousel-steps`, `carousel-editorial`) make a cover, a
page per item of one slot (`{item}`, `{n}`, `{count}`) and an end page; each
page is drawn and checked as any design. A one- or two-character text (a page
number) that fails read-back is a warning: recognition passes over lone glyphs
("2" and "4" read 0% on the steps carousel while "1", "3", "5" read).

**Plan for the old `reel` / slide-kit templates** (81 templates, 1,296 slides
in swift-slide-kit, never released as a CLI): convert them mechanically rather
than redraw them — a CanvasKit `SlideLayer` is a unit rect, so it maps to a
`Placement` (`area: trim`, `anchor: top-left`, `width`/`height`/`x`/`y` from
the rect); its `TextStyle` to a text layer (sizes from the 1080-wide reference
to design units: × 1000/1080), chips and pills to plates, image plates to
backgrounds; a slide-kit deck becomes a carousel with `{tokens}` as slots.
Run the 1,296 slides through both engines and compare pixels before retiring
slide-kit; `reel`'s video export becomes an animated carousel through the
`Animator`.

## Mockups

`Mockups.render(design, kind:)` shows a finished design as a `vinyl` sleeve
(the disc half out, its label in the cover's own colour), a `cd` jewel case
(hinge, plastic glare), a `phone` (a tall design full screen; a cover as a
player shows it, on its own blurred colours with bars and controls — shapes,
no words) or a `poster` pasted on a plaster wall, turned in perspective (Core
Image) with tape and a shadow. Everything is drawn from the design and a seed
— no photographs, no brands — and the same seed draws the same scene.

## Animated covers

`Animator.animate(rendered, motion:, to: url)` writes a seamless H.264 loop
(Spotify Canvas, stories: 3–8 s, 9:16 by the design's canvas) of the design's
art moving under its still words. `motion` is `zoom` (a push in and back),
`drift` (a figure of eight) or `parallax`: the art's depth found by Depth
Anything V2 Small, the nearest third split off with a soft edge, what it
uncovers filled by LaMa (the hole grown by the movement), and a camera circling
so the near part moves three times as far as the rest. Over the art: light
`leaks` on closed paths, `particles` rising one frame-height a loop, grain from
a cycle of eight. Every movement is a periodic function of the loop's phase, so
the frame after the last is the first. No video model.

Measured on every loop: the seam (the last frame against the first, over the
typical step between frames; 1.6 and up fails), each text layer's contrast on
every frame, and read-back on three frames. A 6 s story loop with leaks and 80
particles: seam 0.8×, every word 10.5:1 or better on every frame, 54 s in a
release build; a parallax loop over a generated coastal road (FLUX.2 Klein):
seam 1.0×, title 5.4:1 at its worst frame, 28 s with both models loaded; a
replay draws the same frames (the MP4's bytes differ by its timestamps). The
words are drawn still over the moving art, so a blend between them and the art
(a multiplied texture) is lost in a loop. The recipe keeps `motion`, with the
depth and fill models a parallax used.

## Requirements

macOS 27 / iOS 27, because the AI product runs on Core AI. Swift 6.2. Made
backgrounds use the models `imagine` installs (FLUX.2 Klein 4B, SANA Sprint
1.6B). Core AI compiles a model per program the first time that program
loads it, so the first made background in a new tool takes a few minutes.
The engine's own code imports no Core AI; swift-object-cutout (BiRefNet
subject mattes) compiles its Core AI path only where the SDK has it, from
1.4.1, so `DesignKit` builds for the iOS Simulator (checked with xcodebuild)
and lifts subjects with Vision there. The AI product (`DesignKitAI`) is
macOS / iOS device only.

## License

MIT, see [LICENSE](LICENSE). The bundled fonts are OFL (in DocumentTheme).
Google fonts are fetched, not bundled, each with its licence file; installed system
fonts are used in place and only ever leave as drawn glyphs (or embedded in a
PDF where their licence bits allow).
