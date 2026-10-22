# MOMO & MIMI

Two little offline desktop cats for Windows, written in R.

| MOMO | MIMI |
| :---: | :---: |
| <img src="assets/momo-preview.png" alt="MOMO, a silver tabby cat with a teal collar" width="192"> | <img src="MIMI/assets/mimi-preview.png" alt="MIMI, a silver classic tabby cat without a collar" width="192"> |
| Silver tabby with a teal collar | Silver-white classic tabby with bold dark markings |

Choose MOMO, MIMI, or run both together. They share the same actions: sitting on
your desktop, looking at your cursor, wandering around, waving and jumping.
Each cat saves its own settings, and closing one leaves the other running.

This is a personal side project, made just for fun. ChatGPT and RStudio do not
need to be open while either cat runs.

## Choose your cat

After completing the setup below, use these files in the main repository folder:

| Cat | Start | Stop |
| --- | --- | --- |
| MOMO | Double-click **Start MOMO.cmd** | **Exit MOMO.cmd** |
| MIMI | Double-click **Start MIMI.cmd** | **Exit MIMI.cmd** |

To have both cats on your desktop, open both start files. MIMI's default home is
a little to the left of MOMO's. Drag either cat to move it, or right-click for
actions, settings and exit.

## Requirements

- Windows 10 or 11 with a desktop session.
- R 4.2 or later, with Tcl/Tk support.
- The **ps** R package, installed in the R version you will use for the cats.

Both cats have been tested with R 4.6.0 and Tcl/Tk 8.6.17 on Windows. Other
supported R versions have not been tested individually. macOS and Linux are not supported
by this version because it uses Windows-specific Tk transparency.

## First-time setup

1. Install [R for Windows](https://cran.r-project.org/bin/windows/base/) if needed.
   Keep its Tcl/Tk component enabled.
2. In that R installation, install the only additional runtime package:

   ```r
   install.packages("ps")
   ```

3. Download this repository using **Code → Download ZIP**, or clone it.
4. Extract the whole folder, including `assets` and `MIMI`. Start the cats from
   the extracted folder, rather than from inside the ZIP file.

Internet access may be needed to download R, the repository and the package
during setup. Once they are available locally, both cats work offline. Neither
downloads packages or artwork at startup.

## Start and stop

Double-click **Start MOMO.cmd** or **Start MIMI.cmd**. A small console window may
appear briefly while the launcher checks your R installation; it closes after
the selected cat starts. The launchers use the Windows PowerShell included with
Windows to start your installed R without leaving a console window open.
The pets themselves run in R.

Right-click a cat and choose **Exit MOMO** or **Exit MIMI** to close that cat,
or double-click its matching exit file. Opening a start file again brings that
same cat home instead of starting a second copy.

The launchers look for R in this order:

1. An optional `MOMO_RSCRIPT` or `MIMI_RSCRIPT` environment variable, for the
   selected cat, pointing to `Rscript.exe`.
2. `Rscript.exe` on `PATH`.
3. Standard R installer registry entries.
4. Common per-user and system R installation folders.

No installation path or R version is hard-coded. The complete repository folder
can be moved or renamed after closing both cats. Keep its directory structure:
MOMO's files are at the top level, and MIMI's files are inside `MIMI`.

### Start from your own R session

In RStudio or R, set the working directory to the extracted repository folder.
Choose one of these commands:

```r
source("run_momo.R")
```

```r
source("MIMI/run_mimi.R")
```

That R session stays busy until the selected cat closes. To run both, use the
Windows launchers or two separate R sessions. If `Rscript` is on your `PATH`,
you can also choose a command from:

```text
Rscript --vanilla run_momo.R
Rscript --vanilla MIMI/run_mimi.R
```

To stop MOMO from another R session in the repository folder:

```r
source("stop_momo.R")
```

To stop MIMI:

```r
source("MIMI/stop_mimi.R")
```

## Controls

| Action | Result |
| --- | --- |
| Drag a cat | Move it |
| Click | Say hello |
| Double-click | Jump |
| Right-click | Open actions and settings |
| Open a cat's launcher again | Bring that cat home |

The menu includes pause, wandering, cursor tracking, always-on-top and four sizes.
There is no tray icon. Wandering and position bounds use the primary screen,
with a small margin reserved for the taskbar.

## Local files and privacy

Both cats read their artwork from the extracted folder. Neither uses an account,
sends telemetry, calls an AI service or makes network requests. They do not add
themselves to Windows startup or change security settings.

Each cat has its own preferences and temporary instance markers in your R user
data directory. Startup logs and diagnostics stay in separate R user cache
directories. They are **not** saved in this repository. To see the locations:

```r
tools::R_user_dir("momo", "data")
tools::R_user_dir("momo", "cache")
tools::R_user_dir("mimi", "data")
tools::R_user_dir("mimi", "cache")
```

For testing or a custom local setup, use the matching variables for each cat:

| Setting | MOMO | MIMI |
| --- | --- | --- |
| Data directory | `MOMO_DATA_DIR` | `MIMI_DATA_DIR` |
| Cache directory | `MOMO_CACHE_DIR` | `MIMI_CACHE_DIR` |
| R installation for the launcher | `MOMO_RSCRIPT` | `MIMI_RSCRIPT` |

Keep the two data directories separate when overriding them.

## Troubleshooting

**R was not found.** Start `run_momo.R` or `MIMI/run_mimi.R` from your installed R,
add `Rscript.exe` to `PATH`, or set the selected cat's `MOMO_RSCRIPT` or
`MIMI_RSCRIPT` variable to the full path of your own `Rscript.exe`.

**The ps package is missing.** Install it in the R version selected by the
launcher. Packages installed for a different R version may not be available.

**A cat is not visible.** Open its launcher again to bring it home. Use a normal
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
Rscript --vanilla MIMI/run_mimi.R --self-test
Rscript --vanilla MIMI/run_mimi.R --smoke-test
Rscript --vanilla tests/check_public_files.R
Rscript --vanilla tests/check_companions.R
```

The self-test checks all 74 occupied sprite cells at four sizes, preferences,
cursor directions and screen bounds. The smoke test shows every occupied cell
and all four sizes in a real window, then exits. The companion check verifies
separate data/cache paths and independent instance, show and exit signals.
Reports stay in each cat's local cache.

To rebuild display assets from the original atlas:

```text
Rscript --vanilla scripts/prepare_assets.R
Rscript --vanilla MIMI/scripts/prepare_assets.R
```

Windows Tk uses a transparent color, so the prepared display images use binary
alpha edges. Each cat's source sprite atlas is retained in its own `assets` folder.

## Artwork and license

Both cats' sprite artwork was created with an AI image-generation tool. MIMI's
appearance was inspired by a supplied cat photograph, using MOMO's atlas as the
motion template. The reference photograph is not included. MIMI's generation
prompts are saved in [MIMI/artwork-prompt.txt](MIMI/artwork-prompt.txt).

The source code and included generated artwork for both cats are shared under
the [MIT License](LICENSE). See [MIMI/README.md](MIMI/README.md) for MIMI's own guide.
