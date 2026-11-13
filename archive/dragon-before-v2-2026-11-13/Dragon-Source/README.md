# Dragon source

Two outputs share the same dragon character and animation atlas:
`../Dragon-GPT` is the existing MOMO-style local v2 pet package;
`../Dragon-Offline` is a standalone Windows x64 companion.
The existing MOMO and MIMI files are preserved.

The supplied reference defines long white hair, ivory segmented horns,
pointed ears, violet eyes, pale lavender wings, a white scaled tail and an
elegant high-neck white dress. The compact full-body art retains adult anime
proportions and simplifies small ornamentation for desktop display.

The built-in image generation tool made the base, each independent animation
row, cardinal anchors and both coherent gaze families. `artwork/rows` retains
those inputs. R extracts connected figures without fixed-cell cutting,
retains smooth alpha, removes green staging and disconnected residue,
uses shared scale within each row, preserves jump lift and encodes the atlas.

The native Windows engine is adapted from the supplied MOMO/MIMI Lite source.
Changes are limited to Dragon identity, the standard 73-frame layout and
action labels. It embeds the PNG and icon and imports Windows system DLLs.

## Rebuild

Run from this folder with R 4.6 and Rtools45. Required R packages are `magick`,
`png`, `processx`, `jsonlite`, `digest`, `ps` and `zip`. Toolchain paths are
declared at the top of the R scripts for this Windows environment.

```r
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/prepare_rows.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/assemble.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "tests/test_atlas.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/build.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "tests/test_native.R")
system2(file.path(R.home("bin"), "Rscript.exe"), "scripts/package.R")
```

The R validation report records actual structural and registration checks.
Visual direction semantics are recorded separately. This local export workflow
does not claim to run the ChatGPT Work creation skill's Python quality pipeline
or to create a remote pet record.
