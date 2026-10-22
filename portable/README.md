# Windows portable releases

The portable ZIPs include R 4.6.1, Tcl/Tk 8.6.17 and ps 1.9.3. Users do not
need to install R, RStudio or packages. Windows 10/11 on Intel or AMD x64 is
the supported desktop target.

Download **MOMO-Portable-1.0.0-windows-x64.zip** or
**MIMI-Portable-1.0.0-windows-x64.zip** from
[GitHub Releases](https://github.com/shanlong-who/MOMO/releases/latest).
Extract the entire ZIP, then double-click the matching **Start** file.
The repository's automatically generated source ZIP does not contain R.

## Included files

Each portable folder contains a Start launcher, an Exit launcher, a Check
launcher, a short README, the pet code and four image atlases, the bundled
runtime, licenses, version information and a file-integrity manifest.

Settings and startup logs use the Windows user profile. The portable editions
use the application names `momo-portable` and `mimi-portable`, so their settings
and instance markers are independent of the original source editions.
The original three product folders remain available in the repository.

The launchers use `runtime/R/bin/x64/Rscript.exe` directly. They do not search
PATH or the registry for R. External R libraries, startup profiles and Tcl/Tk
paths are isolated. No package, image or runtime download occurs at startup.

## Reproduce a build

The build runs on Windows and needs R packages `digest` and `zip`. The tests
also need `processx` and `ps`. These are build/test dependencies; only `ps`
is included as an additional package in the user's runtime.

1. Download the official R 4.6.1 Windows installer from CRAN and verify its
   published checksum. Extract it into a temporary build directory with
   Inno Unpacker, using `-x -a` to include duplicate files. Do not run the
   installer against an existing R installation.
2. Download the CRAN Windows binary `ps_1.9.3.zip`.
3. Run the following commands from the repository root, replacing the example
   build paths with your temporary paths:

```text
Rscript --vanilla portable/build_portable.R . CLEAN_R_HOME PS_ZIP NEW_OUTPUT_DIR 1.0.0
Rscript --vanilla portable/test_portable.R NEW_OUTPUT_DIR NEW_TEST_DIR REPORT_FILE
```

`CLEAN_R_HOME` is the extracted installer's `{app}` directory. The builder
verifies every selected R file against its original `MD5` manifest and refuses
a modified or mixed-version runtime. It copies an explicit allowlist of
distribution files and base packages, then adds the separately verified ps
binary package. Personal R libraries and configuration files are excluded.

The output and test directories must be new. The scripts do not overwrite or
delete an existing build. Use temporary build directories outside cloud-sync
folders for predictable download and extraction performance.

The pinned downloads and checksums are recorded in
[`upstream-files.tsv`](upstream-files.tsv). The GitHub Actions workflow builds
and tests the same ZIPs on a separate Windows runner.

## Validation

The tests extract the final ZIPs into paths containing spaces and Chinese
characters, verify every file, and exercise all 74 frames at four sizes.
They also test real transparent windows, public Start and Exit launchers,
repeated Start, concurrent cats, relocation, missing assets, missing runtime,
and isolation from system R and user profiles.

HTTP/HTTPS proxies are deliberately unusable during runtime tests. This checks
that startup needs no downloads; it does not disconnect the host's network.
A bundled process path and library check establishes which R actually ran.
No claim is made that the host's existing R was uninstalled.

Keep the version-specific test report and SHA-256 checksums with each release.
Do not describe Windows ARM, macOS, Linux or every managed-device policy as
tested. Users should use their organization's IT process for blocked launchers.

## Runtime sources and licenses

The project code and cat artwork remain MIT licensed. Bundled R and other
components retain their upstream licenses. The portable notices identify the
GPL version 3 distribution option for R and point to the full license texts
and upstream build sources. Attach the matching R and ps source archives to
the same GitHub Release, alongside the portable ZIPs and checksum file.

The Inno unpacker is a build tool and is not included in the portable packages.
