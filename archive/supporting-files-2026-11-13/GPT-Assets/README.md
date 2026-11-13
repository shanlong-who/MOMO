# GPT pet package sources

## Final artwork decision

Use the original released Offline artwork for both pets. MOMO uses the
existing collar-free version; MIMI uses the existing MIMI-Offline artwork.
Preserve all original faces, head angles, expressions, poses and frame order.
The proposed frontal idle redraws were rejected and are not included in
either final package. They remain here only as working history.

The original unmodified GPT ZIP is in `../archive/momo-pet-v2.zip`.

## Sources and conversion

Source atlases are in `../Releases/2.0.0/Source/assets/aligned`:
`momo-atlas.png` and `mimi-atlas.png`. They are the released Offline artwork.

Each source cell is 256 x 280. Every cell receives the same proportional
resize to 190 x 208 and one transparent column on each side, producing
192 x 208 cells in a transparent 1536 x 2288 lossless WebP atlas.
The nine animation rows, neutral frame and sixteen look poses retain the
original package layout, including its six idle frames plus neutral cell.
Runtime animation timing and interactions remain controlled by Codex.

`validation.json` checks every delivered cell against its transformed source,
all original occupied and unused slots, transparent RGB, cell padding,
manifest identity and SHA-256 hashes. The build also checks the ZIP paths.
These describe the original local package checks. A later desktop account
artwork update is documented below.

## Local Codex installation

Both packages were subsequently installed into `%USERPROFILE%/.codex/pets`:
`momo/` replaces the existing MOMO with the same ID, and `mimi/` adds MIMI.
The previous MOMO directory was preserved under `../archive/codex-pets-before-*`.
Every installed file was checked against the corresponding new package.
See `codex-installation-result.json` for the exact backup path and hashes.

In the app, open Settings > Pets, select Refresh, then choose Momo or Mimi.
The [official Pets documentation](https://learn.chatgpt.com/docs/pets)
describes the refresh and selection controls. The app's visible picker was
not inspected during the file installation.

## Desktop account versions

The desktop app migrated local pets to account records. Replacing a local
file did not replace the artwork in the already migrated account record.
The two existing account MOMO records initially contained identical collared
artwork. They now have these distinct names:

- `Momo`: the approved collar-free artwork, updated in its existing record.
- `Momo Collar`: the original collared artwork, preserved byte for byte.
- `Mimi`: unchanged.

Both existing MOMO IDs and the previous active selection were retained.
The stored collar-free artwork was downloaded again and checked against
every decoded pixel of the approved local atlas. The user confirmed that
all three appearances, animations and switching work in the desktop app.
See `cloud-pet-check-20261113/` for the account and artwork verification,
the visual comparison, and the user's direct desktop confirmation.

## Rebuild with R

Run from the project root. Required packages are `magick`, `png`, `jsonlite`,
`zip` and `digest`.

```r
source("GPT-Assets/inspect_assets.R")
source("GPT-Assets/build_gpt_pets.R")
```

Or run these scripts with `Rscript --vanilla`. The builder creates a fresh
timestamped directory under `GPT-Assets/build` and refuses to overwrite an
existing build directory. It reads only the released atlases; the experimental
idle preparation scripts and generated artwork are not used.

Animation previews are generated from the final encoded WebP, including
each standard state, all states, idle-to-jump-to-idle, and the look loop.
