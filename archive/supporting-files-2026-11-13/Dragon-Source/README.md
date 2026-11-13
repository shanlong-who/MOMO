# Dragon 2.0 source

Dragon-GPT is the existing MOMO-style local desktop pet package.
Dragon-Offline is the standalone Windows x64 companion. Both use the same
new simplified artwork and full-body animation atlas.

The user approved the simplified concept in `artwork/approved-concept.png`:
a larger expressive adult face, crescent horns, broad white hair locks,
compact lavender wings, a thick smooth crescent tail and a simple ivory
dress with one waist clasp and one lavender hem band. `artwork/base.png`
is the canonical production master. Every source row is newly generated
from this identity; no old detailed animation frames are reused.

Human acting replaces the previous pet-like movement rhythm: a small palm
greeting and wink, graceful directional gliding, a restrained celebratory
lift, attentive waiting, thinking, inspection and concern followed by recovery.
The native engine uses per-pose timing, once-only response playback,
longer quiet intervals, shorter and slower automatic glides, and stable-gaze
debouncing. Existing settings remain compatible.

## Files and checks

- `artwork`: approved concept, canonical base, generated rows and prompt set.
- `scripts`: R preparation, assembly, previews, build and packaging; the
  existing native connected-component helper is retained.
- `src`: adapted Win32/GDI+ source with embedded PNG/icon and DPI manifest.
- `tests`: encoded atlas and native runtime checks.
- `qa`: extracted figures, registration metrics, direction reviews, contact
  sheets, build logs and runtime test reports.

The atlas retains the supplied local MOMO/MIMI convention: six animated idle
frames plus neutral in column 6, with 74 occupied cells and fourteen empty
cells overall. The 57 standard animation frames and sixteen gaze poses keep
the usual v2 order. Neutral is a copy of the approved calm idle frame and is
excluded from animation loops.

R performs connected-figure extraction, chroma cleanup, shared per-row scale,
body registration, lift preservation, exact geometry and transparent-cell
checks. Final PNG and lossless WebP must match, including the neutral cell.
Visual semantics, continuity observations and independent reviews are
recorded separately from structural checks. This local workflow does not
claim to run the cloud Pets skill's Python quality pipeline or create a
remote pet record.

## Rebuild

The source ZIP contains `Dragon-Source` and the small sibling package
templates. Extract it to a working directory and run from `Dragon-Source`.

Run from this folder with R 4.6 and Rtools45. Required packages: `magick`,
`png`, `processx`, `jsonlite`, `digest`, `ps` and `zip`.
Optional `av` encodes the MP4 preview; GIFs do not need it.
The R scripts declare the toolchain path for this Windows host.

```r
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/prepare_rows.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/assemble.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "tests/test_atlas.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/measure_look.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/render_previews.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/build.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "tests/test_native.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/package.R")
```

The previous Dragon 1.0 edition is preserved in the project archive when the
validated 2.0 outputs are promoted to the main Dragon folders.
