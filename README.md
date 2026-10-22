# MOMO

<img src="assets/momo-preview.png" alt="MOMO, a silver tabby cat with a teal collar" width="192">

A little offline desktop cat for Windows, written in R.

MOMO can sit on your desktop, look at your cursor, wander around, wave and jump.
It is a personal side project, made just for fun. ChatGPT and RStudio do not need
to be open while it runs.

## Requirements

- Windows 10 or 11 with a desktop session.
- R 4.2 or later, with Tcl/Tk support.
- The **ps** R package, installed in the R version you will use for MOMO.

MOMO has been tested with R 4.6.0 and Tcl/Tk 8.6.17 on Windows. Other supported R
versions have not been tested individually. macOS and Linux are not supported
by this version because it uses Windows-specific Tk transparency.

## First-time setup

1. Install [R for Windows](https://cran.r-project.org/bin/windows/base/) if needed.
   Keep its Tcl/Tk component enabled.
2. In that R installation, install the only additional runtime package:

   ```r
   install.packages("ps")
   ```

3. Download this repository using **Code → Download ZIP**, or clone it.
4. Extract the whole folder. Do not run MOMO from inside the ZIP file.

Internet access may be needed to download R, the repository and the package
during setup. Once they are available locally, MOMO works offline. It never
downloads packages or artwork when you start it.

## Start and stop

Double-click **Start MOMO.cmd**. A small console window may appear briefly while
the launcher checks your R installation; it closes after MOMO starts.
The launcher uses the Windows PowerShell included with Windows to start your
installed R without leaving a console window open. The pet itself runs in R.

Right-click MOMO and choose **Exit MOMO** to close it, or double-click
**Exit MOMO.cmd**. Opening **Start MOMO.cmd** again brings the same cat back to
the lower-right corner instead of starting a second copy.

The launchers look for R in this order:

1. An optional `MOMO_RSCRIPT` environment variable pointing to `Rscript.exe`.
2. `Rscript.exe` on `PATH`.
3. Standard R installer registry entries.
4. Common per-user and system R installation folders.

No installation path or R version is hard-coded. The complete folder can be
moved or renamed after closing MOMO. Keep the R scripts and the `assets` folder together.

### Start from your own R session

In RStudio or R, set the working directory to the extracted MOMO folder, then run:

```r
source("run_momo.R")
```

That R session stays busy until MOMO closes. For an independent process, use the
Windows launcher instead. If `Rscript` is on your `PATH`, you can also use:

```text
Rscript --vanilla run_momo.R
```

To stop MOMO from another R session in the same folder:

```r
source("stop_momo.R")
```

## Controls

| Action | Result |
| --- | --- |
| Drag MOMO | Move it |
| Click | Say hello |
| Double-click | Jump |
| Right-click | Open actions and settings |
| Open the launcher again | Bring MOMO home |

The menu includes pause, wandering, cursor tracking, always-on-top and four sizes.
There is no tray icon. Wandering and position bounds use the primary screen,
with a small margin reserved for the taskbar.

## Local files and privacy

MOMO reads its artwork from the extracted folder. It does not use an account,
send telemetry, call an AI service or make network requests. It does not add
itself to Windows startup or change security settings.

Preferences and temporary instance markers are stored in your R user data
directory. Startup logs and diagnostics are stored in your R user cache
directory. They are **not** saved in this repository. To see the locations:

```r
tools::R_user_dir("momo", "data")
tools::R_user_dir("momo", "cache")
```

For testing or a custom local setup, `MOMO_DATA_DIR` and `MOMO_CACHE_DIR` can
override those directories for the current R process. `MOMO_RSCRIPT` selects a
specific R installation for the Windows launchers.

## Troubleshooting

**R was not found.** Start `run_momo.R` from your installed R, add `Rscript.exe`
to `PATH`, or set `MOMO_RSCRIPT` to the full path of your own `Rscript.exe`.

**The ps package is missing.** Install it in the R version selected by the
launcher. Packages installed for a different R version may not be available.

**MOMO is not visible.** Open the launcher again to bring it home. Use a normal
interactive Windows desktop; services and headless sessions are not supported.

**A launcher is blocked on a managed computer.** Follow your organization's IT
process. The app does not require security exclusions or changes to execution
policy. Starting from an approved R/RStudio session is another supported entry
point; organization restrictions still apply.

**The folder was moved.** Use the launchers from the new folder. Any old Windows
shortcuts you created yourself still point to their original location.

**Startup failed.** The console keeps the error visible. Local startup logs are
under the `logs` subfolder of the cache directory; diagnostics are under
`diagnostics`. Review and redact local paths before posting a log publicly.

## Development and checks

The runtime uses only `tcltk` and `ps`. `png` and `magick` are needed only if you
want to regenerate the prepared artwork or the README preview.

From the repository folder:

```text
Rscript --vanilla run_momo.R --self-test
Rscript --vanilla run_momo.R --smoke-test
Rscript --vanilla tests/check_public_files.R
```

The self-test checks all 74 occupied sprite cells at four sizes, preferences,
cursor directions and screen bounds. The smoke test shows every occupied cell
and all four sizes in a real window, then exits. Reports stay in the local cache.

To rebuild display assets from the original atlas:

```text
Rscript --vanilla scripts/prepare_assets.R
```

Windows Tk uses a transparent color, so the prepared display images use binary
alpha edges. The original sprite atlas is retained in `assets`.

## Artwork and license

MOMO's original sprite artwork was created with an AI image-generation tool.
The source code and included MOMO artwork are shared under the [MIT License](LICENSE).
