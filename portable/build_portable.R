# Build each cat into a separate ZIP. Never modifies the source pet folders.
library(digest)
library(zip)

build.arguments <- commandArgs(TRUE)
if (length(build.arguments) != 5L) {
  stop("Usage: Rscript build_portable.R SOURCE_ROOT CLEAN_R_HOME PS_ZIP OUTPUT_DIR VERSION")
}
source.root <- normalizePath(build.arguments[[1L]], winslash = "/", mustWork = TRUE)
runtime.home <- normalizePath(build.arguments[[2L]], winslash = "/", mustWork = TRUE)
ps.archive <- normalizePath(build.arguments[[3L]], winslash = "/", mustWork = TRUE)
output.directory <- normalizePath(build.arguments[[4L]], winslash = "/", mustWork = FALSE)
release.version <- build.arguments[[5L]]
script.file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
template.directory <- file.path(dirname(normalizePath(script.file, winslash = "/")), "templates")
if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", release.version)) stop("Use a semantic release version.")
if (dir.exists(output.directory)) stop("Build output already exists. Choose a new empty output directory.")
dir.create(output.directory, recursive = TRUE)

copy_file <- function(from, to) {
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(from, to, overwrite = FALSE, copy.mode = FALSE)) stop("Could not copy: ", from)
}

write_text <- function(lines, path, windows = FALSE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  connection <- file(path, open = "wb")
  on.exit(close(connection))
  writeLines(enc2utf8(lines), connection, sep = if (windows) "\r\n" else "\n", useBytes = TRUE)
}

# Select only files in the original R distribution manifest. Personal packages
# and local overrides can never enter the runtime through this allowlist.
manifest.lines <- readLines(file.path(runtime.home, "MD5"))
runtime.files <- sub("^[a-f0-9]+ \\*", "", manifest.lines)
runtime.hashes <- sub(" .*", "", manifest.lines)
base.packages <- c("base", "compiler", "datasets", "grDevices", "graphics", "grid", "methods",
                   "parallel", "splines", "stats", "stats4", "tcltk", "tools", "utils")
base.description <- read.dcf(file.path(runtime.home, "library", "base", "DESCRIPTION"))
if (base.description[1L, "Version"] != "4.6.1") stop("This release requires a clean R 4.6.1 runtime.")
runtime.pattern <- paste0("^(bin|etc|modules|Tcl|share)/|^library/(",
                         paste(base.packages, collapse = "|"), ")/|^(COPYING|README|doc/COPYRIGHTS)")
selected <- grepl(runtime.pattern, runtime.files)
runtime.files <- runtime.files[selected]
runtime.hashes <- runtime.hashes[selected]
runtime.actual <- unname(tools::md5sum(file.path(runtime.home, runtime.files)))
if (anyNA(runtime.actual) || any(runtime.actual != runtime.hashes)) {
  stop("The R runtime differs from its original distribution manifest. Use a clean official extraction.")
}
if (any(grepl("(^|/)\\.\\.(/|$)", runtime.files))) stop("Unsafe path in the runtime manifest.")
cat("PASS: clean runtime manifest verified for", length(runtime.files), "files.\n")

for (pet.name in c("MOMO", "MIMI")) {
  pet.id <- tolower(pet.name)
  pet.source <- file.path(source.root, paste0(pet.name, "-Offline"))
  pet.directory <- file.path(output.directory, paste0(pet.name, "-Portable"))
  pet.runtime <- file.path(pet.directory, "runtime", "R")
  for (relative.file in runtime.files) {
    copy_file(file.path(runtime.home, relative.file), file.path(pet.runtime, relative.file))
  }
  copy_file(file.path(runtime.home, "MD5"), file.path(pet.runtime, "ORIGINAL-MD5"))
  zip::unzip(ps.archive, exdir = file.path(pet.runtime, "library"))
  ps.description <- read.dcf(file.path(pet.runtime, "library", "ps", "DESCRIPTION"))
  stopifnot(ps.description[1L, "Version"] == "1.9.3")
  ps.manifest <- readLines(file.path(pet.runtime, "library", "ps", "MD5"))
  ps.files <- sub("^[a-f0-9]+ \\*", "", ps.manifest)
  stopifnot(all(unname(tools::md5sum(file.path(pet.runtime, "library", "ps", ps.files))) == sub(" .*", "", ps.manifest)))

  app.files <- c("bootstrap.R", paste0(pet.id, ".R"))
  app.assets <- paste0("assets/", pet.id, "-", c(144L, 192L, 240L, 288L), ".png")
  for (relative.file in c(app.files, app.assets)) {
    copy_file(file.path(pet.source, relative.file), file.path(pet.directory, "app", relative.file))
  }
  copy_file(file.path(pet.source, "LICENSE"), file.path(pet.directory, "LICENSE"))
  for (template.name in c("portable.cmd", "portable.R")) {
    template.lines <- readLines(file.path(template.directory, template.name), warn = FALSE)
    write_text(gsub("@PET@", pet.name, template.lines, fixed = TRUE),
               file.path(pet.directory, "scripts", template.name), windows = endsWith(template.name, ".cmd"))
  }
  for (action in c(Start = "start", Exit = "stop", Check = "check")) {
    label <- names(c(Start = "start", Exit = "stop", Check = "check"))[match(action, c("start", "stop", "check"))]
    lines <- c("@echo off", "setlocal EnableExtensions DisableDelayedExpansion",
               paste0('call "%~dp0scripts\\portable.cmd" ', action), "set \"PET_EXIT_CODE=%ERRORLEVEL%\"")
    if (action == "check") lines <- c(lines, "echo.", "pause") else
      lines <- c(lines, "if not \"%PET_EXIT_CODE%\"==\"0\" (", "  echo.",
                 paste0("  echo ", pet.name, " could not complete the action. Read the message above."), "  pause", ")")
    write_text(c(lines, "exit /b %PET_EXIT_CODE%"),
               file.path(pet.directory, paste(label, paste0(pet.name, ".cmd"))), windows = TRUE)
  }
  write_text(c(paste(pet.name, "Portable", release.version), "",
               "Windows 10/11, Intel or AMD 64-bit (x64).", "",
               "1. Extract the entire ZIP into a local folder.",
               paste0("2. Double-click Start ", pet.name, ".cmd."),
               paste0("3. Right-click the cat to change settings or exit. Exit ", pet.name, ".cmd also closes it."), "",
               "R, Tcl/Tk and ps are included. RStudio, an R installation, an account and internet access are not needed.",
               "A console may appear briefly during startup. The cat then runs in a separate hidden-console R process.",
               "Opening Start again brings the existing cat home. Both cats can run at the same time.",
               "Close the cat before moving its folder. Keep app, runtime and scripts together.",
               "If the folder is in OneDrive or another cloud folder, keep all files available on this device.", "",
               "Controls: drag to move, click to greet, double-click to jump, right-click for the menu.",
               "The menu includes wandering, cursor tracking, always-on-top and four sizes.", "",
               paste0("Troubleshooting: double-click Check ", pet.name, ".cmd. It checks every release file and all animation frames."),
               "The check shows the settings and diagnostic paths. Settings and logs use the Windows user profile,",
               "not the extracted folder. Portable editions use separate settings from the original source editions.",
               "If a release file is missing or changed, extract a fresh copy of the ZIP.",
               "On a managed device, launcher restrictions must be handled through the organization's IT process.", "",
               "The pet makes no network requests, installs no services, and does not change Windows startup or the registry.",
               "The R runtime is included for this app; it is not a general-purpose development installation.",
               "See THIRD-PARTY-NOTICES.txt for runtime licenses and corresponding source locations.",
               "Project: https://github.com/shanlong-who/MOMO"), file.path(pet.directory, "README.txt"))
  write_text(c("Third-party components", "",
               "MOMO/MIMI source code and artwork: MIT; see LICENSE.",
               "R 4.6.1: redistributed under the GNU GPL version 3 option described in R's copyright notice.",
               "Full license: runtime/R/share/licenses/GPL-3; copyright details: runtime/R/doc/COPYRIGHTS.",
               "R source: https://cran.r-project.org/src/base/R-4/R-4.6.1.tar.gz",
               paste0("A matching R source archive is also an asset of release v", release.version, ":"),
               paste0("https://github.com/shanlong-who/MOMO/releases/tag/v", release.version),
               "The unmodified runtime files were extracted from the official R 4.6.1 Windows installer.",
               "Only base packages and runtime support files are included. No runtime file was patched.", "",
               "ps 1.9.3: MIT. See runtime/R/library/ps/LICENSE and runtime/R/share/licenses/MIT.",
               "Source: https://cran.r-project.org/src/contrib/ps_1.9.3.tar.gz (also attached to this release).", "",
               "Tcl/Tk and other libraries retain their upstream copyright and license notices in runtime/R.",
               "R Windows build sources and external dependency recipes:",
               "https://svn.r-project.org/R-dev-web/trunk/WindowsBuilds/winutf8/ucrt3/",
               "https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html",
               "https://github.com/waddella/Tclbuild",
               "See runtime/R/doc/COPYRIGHTS for the upstream component-specific source information.", "",
               "No RStudio components or personal R packages are included."), file.path(pet.directory, "THIRD-PARTY-NOTICES.txt"))
  write_text(c(paste0("Release: ", release.version), "Platform: windows-x64", "R: 4.6.1", "ps: 1.9.3",
               "Tcl/Tk: 8.6.17", "Build method: official installer extraction; original runtime files verified with MD5"),
             file.path(pet.directory, "VERSIONS.txt"))
  release.files <- sort(list.files(pet.directory, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  integrity <- data.frame(file = release.files,
                          md5 = unname(tools::md5sum(file.path(pet.directory, release.files))))
  stopifnot(!anyNA(integrity$md5))
  write.table(integrity, file.path(pet.directory, "MANIFEST.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
  archive.path <- file.path(output.directory, paste0(pet.name, "-Portable-", release.version, "-windows-x64.zip"))
  zip::zipr(archive.path, files = basename(pet.directory), root = output.directory, compression_level = 9L)
  cat("Built:", basename(archive.path), "\n")
}
archives <- list.files(output.directory, pattern = "\\.zip$", full.names = TRUE)
hash.lines <- vapply(archives, function(path) paste(digest::digest(file = path, algo = "sha256"), basename(path)), character(1))
writeLines(hash.lines, file.path(output.directory, "SHA256SUMS.txt"))
cat("PASS: two portable ZIPs and SHA-256 checksums created.\n")
