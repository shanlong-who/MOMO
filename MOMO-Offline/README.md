# MOMO Offline

<img src="assets/momo-preview.png" alt="MOMO, a silver tabby cat with a teal collar" width="192">

A little offline desktop cat for Windows, written in R. MOMO is a silver tabby
with amber eyes and a teal collar. It shares MIMI's actions and controls,
with separate settings so both cats can run together.

## Setup and start

You need Windows 10 or 11, R 4.2 or later with Tcl/Tk, and the **ps** R package.
Install ps once in the R installation you will use:

```r
install.packages("ps")
```

Keep this whole folder together and double-click **Start MOMO.cmd**. A console
may appear briefly while R is checked, then close once the cat is ready.
Right-click the cat and choose **Exit MOMO**, or use **Exit MOMO.cmd**.

After setup, MOMO runs offline. ChatGPT and RStudio do not need to be open.
Opening the launcher again brings the existing MOMO home. Its default home is
near the lower-right corner.

For a desktop shortcut, use this folder's start file as the target and
`assets/momo.ico` as the icon. Recreate the shortcut if the folder is moved.

## Controls

Drag to move, click to say hello, double-click to jump, and right-click for the
menu. It includes play, stretch, rest, pause, wandering, cursor tracking,
always-on-top, four sizes and exit. Position bounds use the primary screen.

## Run from R or RStudio

Set the working directory to this MOMO-Offline folder, then run:

```r
source("run_momo.R")
```

The R session stays busy until MOMO closes. From another session in this folder:

```r
source("stop_momo.R")
```

The Windows launcher starts a separate R process and looks for R through
`MOMO_RSCRIPT`, PATH, installer registry entries and common installation folders.

## Local data and checks

MOMO makes no network requests, sends no telemetry and uses no account or
AI service while running. Preferences and logs stay outside this source folder:

```r
tools::R_user_dir("momo", "data")
tools::R_user_dir("momo", "cache")
```

`MOMO_DATA_DIR` and `MOMO_CACHE_DIR` can override those locations.
If the cat is not visible, open the launcher again to bring it home.
Install a missing ps package in the R selected by the launcher.

With Rscript on PATH, run these from this folder:

```text
Rscript --vanilla run_momo.R --self-test
Rscript --vanilla run_momo.R --smoke-test
Rscript --vanilla tests/check_public_files.R
```

Artwork preparation uses `magick` and `png`:

```text
Rscript --vanilla scripts/prepare_assets.R
```

## Artwork and license

MOMO's sprite artwork was created with an AI image-generation tool.
The source and included generated artwork use the [MIT License](LICENSE).

See the [project README](../README.md) for all three versions and full setup notes.
