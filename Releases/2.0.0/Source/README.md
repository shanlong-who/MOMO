# Lite 2.0.0 source snapshot

This folder holds the shared C++ source, build and test scripts, corrected
animation assets, remastered artwork and license notices for MOMO and MIMI
Lite 2.0.0. Both pets use `src/pet.cpp`; the build selects MIMI with a compiler
definition. The application source and final assets are unchanged from the
released version. The packaging script reads the saved size baseline in
`../PACKAGE-SIZES.csv`, so old installers and an Archive folder are not needed.

The Windows applications need no R runtime. R and the compiler are used only
when developing, building or testing them.

## Contents

- `src`: native Win32/GDI+ application and DPI manifest.
- `assets/aligned`: the final animation atlases, icons and frame checks.
- `artwork/remastered`: the edited artwork used to create the final assets.
- `scripts`: source build, asset preparation and packaging scripts.
- `tests`: the existing native application test suite.
- `licenses`: compiler runtime license notices.

## Build and test

Run from this folder using R with `processx` and `digest`, and a MinGW-w64
toolchain such as the one included in Rtools45. The test suite also uses `ps`.
Use new output directories: the scripts refuse to overwrite existing output.

```text
Rscript scripts/build.R "D:/R/rtools45/x86_64-w64-mingw32.static.posix/bin" assets/aligned build/next
Rscript tests/test_native.R build/next validation/next
```

To recreate the assets first, also install the R packages `magick` and `png`:

```text
Rscript scripts/assemble_assets.R artwork/remastered assets/rebuilt "D:/R/rtools45/x86_64-w64-mingw32.static.posix/bin"
```

Build with `assets/rebuilt` if using those newly assembled assets.

To package a build that passed the full test suite, also install `zip` and
`magick`, then run:

```text
Rscript scripts/package.R build/next validation/next assets/aligned release/next
```

This creates both ZIPs with checksums, license notices and validation results.
Use the new asset directory instead of `assets/aligned` when rebuilding artwork.

## Development history

The [earlier R and chat-app source](https://github.com/shanlong-who/MOMO/tree/v1.0.0)
is retained in GitHub history. Old installers and intermediate native builds
are not required to build the current applications. The public release
validation is in [RELEASE-VALIDATION.txt](../RELEASE-VALIDATION.txt).

The runnable applications are in `../../../MOMO-Offline` and
`../../../MIMI-Offline`. Use the released EXEs there for everyday use.
