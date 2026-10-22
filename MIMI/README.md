# MIMI

<img src="assets/mimi-preview.png" alt="MIMI, a silver classic tabby cat" width="192">

A little offline desktop cat for Windows, written in R.

MIMI is a companion edition of [MOMO](https://github.com/shanlong-who/MOMO).
It uses the same animation states and controls, with a new cat character inspired
by the supplied photograph: a round face, green-gold eyes, silver-white fur and
bold dark tabby markings. It is a personal project, made just for fun.

## Start and stop

Keep this whole folder together and double-click **Start MIMI.cmd**. You can also
use the Start MIMI launcher in the parent project folder. A console may appear
briefly while your R installation is checked, then close when the cat is ready.

Right-click the cat and choose **Exit MIMI**, or double-click **Exit MIMI.cmd**.
Opening Start MIMI again brings the existing cat home. MIMI appears a little to
the left of MOMO's default location. You can drag it anywhere on the primary screen.

MIMI and MOMO have separate preferences and instance markers. Both can run at
the same time; closing one does not close the other.

## Requirements

- Windows 10 or 11 with a normal interactive desktop session.
- R 4.2 or later, including Tcl/Tk.
- The **ps** package installed in the selected R installation.

Install the additional package once in R if needed:

```r
install.packages("ps")
```

Once R, ps and the complete MIMI folder are on the computer, the pet runs offline.
ChatGPT and RStudio do not need to be open. MIMI never downloads packages or
artwork at startup and does not use an account or AI service while running.

The launcher looks for R using `MIMI_RSCRIPT`, PATH, standard R installer registry
entries, then common per-user and system installation folders. For a custom
installation, set `MIMI_RSCRIPT` to that installation's `Rscript.exe`.

To run from R or RStudio, set the working directory to this folder and use:

```r
source("run_mimi.R")
```

That R session stays busy until the cat closes. The Windows launcher starts a
separate R process. From another R session in this folder, you can close MIMI with:

```r
source("stop_mimi.R")
```

## Controls

| Action | Result |
| --- | --- |
| Drag | Move MIMI |
| Click | Say hello |
| Double-click | Jump |
| Right-click | Open actions, settings and exit |
| Open Start MIMI again | Bring the same cat home |

The menu includes greeting, jumping, playing, stretching, resting, pause,
wandering, cursor tracking, always-on-top and four sizes. There is no tray icon.
Position bounds use the primary screen with space reserved for the taskbar.

## Local files and troubleshooting

MIMI reads its artwork from `assets`. It does not make network requests, send
telemetry, add itself to Windows startup or change security settings.

Preferences stay in the R user data directory; startup logs and diagnostics stay
in the R user cache directory. To inspect those locations in R:

```r
tools::R_user_dir("mimi", "data")
tools::R_user_dir("mimi", "cache")
```

`MIMI_DATA_DIR` and `MIMI_CACHE_DIR` can override those paths for testing.
If the cat is not visible, open Start MIMI again to bring it home. If R or ps
is missing, follow the launcher's message. Extract the full folder before
starting. On a managed device, follow your organization's IT policy if a
launcher is blocked; this app does not require security exclusions.

## Development

The runtime needs only `tcltk` and `ps`. Artwork preparation uses `magick` and `png`.
From this folder, with Rscript on PATH:

```text
Rscript --vanilla run_mimi.R --self-test
Rscript --vanilla run_mimi.R --smoke-test
Rscript --vanilla tests/check_public_files.R
Rscript --vanilla scripts/prepare_assets.R
```

The checks load all 74 frames at four sizes, exercise directions, bounds,
preferences and instance markers, then display every frame in a transparent
window. Reports stay in the cache directory. Windows Tk uses a transparent
color, so display atlases use binary alpha edges. Source artwork is retained.

## Artwork and license

The sprite artwork was made with the built-in image-generation tool, using the
supplied photograph as a character reference and MOMO's atlas as a motion
template. The reference photograph is not included. The generation prompts are
in [artwork-prompt.txt](artwork-prompt.txt).

The source code and generated sprite artwork use the [MIT License](LICENSE).
