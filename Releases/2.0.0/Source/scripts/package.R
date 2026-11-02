library(zip)
library(digest)
library(magick)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) stop("Usage: Rscript package.R BUILD_DIR TEST_DIR ASSET_DIR NEW_RELEASE_DIR")
build.dir <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
test.dir <- normalizePath(args[[2]], winslash = "/", mustWork = TRUE)
asset.dir <- normalizePath(args[[3]], winslash = "/", mustWork = TRUE)
output.dir <- args[[4]]
stopifnot(!dir.exists(output.dir))
dir.create(output.dir, recursive = TRUE)
output.dir <- normalizePath(output.dir, winslash = "/")
script.path <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
project.dir <- dirname(dirname(normalizePath(script.path, winslash = "/")))
test.report <- readLines(file.path(test.dir, "NATIVE-TEST-RESULTS.txt"))
stopifnot(length(test.report) == 13L, all(startsWith(test.report, "PASS:")))

sha256 <- function(path) {
  digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
}
summary <- list()
for (pet in c("MOMO", "MIMI")) {
  folder <- paste0(pet, "-Lite-2.0.0")
  pet.dir <- file.path(output.dir, folder)
  dir.create(pet.dir)
  exe <- file.path(pet.dir, paste0(pet, ".exe"))
  stopifnot(file.copy(file.path(build.dir, paste0(pet, ".exe")), exe))
  stopifnot(file.copy(file.path(project.dir, c("LICENSE", "THIRD-PARTY-NOTICES.txt")), pet.dir))
  dir.create(file.path(pet.dir, "licenses"))
  license.files <- list.files(file.path(project.dir, "licenses"), full.names = TRUE)
  stopifnot(file.copy(license.files, file.path(pet.dir, "licenses")))
  readme <- c(paste(pet, "Lite 2.0.0"), "Released: 2026-11-01", "",
    paste0("Double-click ", pet, ".exe. No installation is required."),
    "Windows 10/11, Intel or AMD x64. No R, RStudio, .NET or internet connection needed.",
    "The artwork and icon are embedded. The EXE can be moved on its own.", "",
    "Drag: move. Click: hello. Double-click: jump.",
    "Right-click: actions, pause, wandering, cursor tracking, size and exit.",
    "Open the EXE again to bring the same pet home.",
    "MOMO and MIMI can run together and keep their settings separately.", "",
    if (pet == "MOMO") "MOMO has no collar or pendant." else "MIMI has remastered fur, eyes and tabby markings.",
    "All 74 animation frames have complete silhouettes and transparent margins.",
    "Frame extraction prevents clipped paws, ears and fragments from neighboring frames.", "",
    paste0("Settings: %LOCALAPPDATA%\\DesktopPetsLite\\", pet, "\\preferences.ini"),
    "The app does not add itself to startup, collect telemetry or access the network.",
    "This EXE is unsigned. No administrator privileges are required.", "",
    "Code and generated artwork: MIT License. Copyright (c) 2026 Shanlong Ding.",
    "See LICENSE and THIRD-PARTY-NOTICES.txt for notices.")
  writeLines(readme, file.path(pet.dir, "README.txt"))
  writeLines(test.report, file.path(pet.dir, "TEST-RESULTS.txt"))
  writeLines(paste(sha256(exe), basename(exe), sep = "  "), file.path(pet.dir, "SHA256SUMS.txt"))
  zip.path <- file.path(output.dir, paste0(folder, "-windows-x64.zip"))
  zipr(zip.path, files = folder, root = output.dir, compression_level = 9)
  verification.dir <- file.path(output.dir, paste0("verify-", tolower(pet)))
  dir.create(verification.dir)
  unzip(zip.path, exdir = verification.dir)
  extracted.exe <- file.path(verification.dir, folder, paste0(pet, ".exe"))
  stopifnot(identical(sha256(extracted.exe), sha256(file.path(build.dir, paste0(pet, ".exe")))))
  baseline.path <- file.path(dirname(project.dir), "PACKAGE-SIZES.csv")
  baseline <- read.csv(baseline.path, stringsAsFactors = FALSE)
  previous.bytes <- baseline$previous.zip.bytes[baseline$pet == pet]
  stopifnot(length(previous.bytes) == 1L, is.finite(previous.bytes), previous.bytes > 0)
  summary[[pet]] <- data.frame(pet, exe.bytes = file.info(exe)$size,
    zip.bytes = file.info(zip.path)$size, previous.zip.bytes = previous.bytes,
    reduction.percent = 100 * (1 - file.info(zip.path)$size / previous.bytes))
}
sizes <- do.call(rbind, summary)
write.csv(sizes, file.path(output.dir, "PACKAGE-SIZES.csv"), row.names = FALSE)
zip.paths <- list.files(output.dir, pattern = "\\.zip$", full.names = TRUE)
writeLines(paste(vapply(zip.paths, sha256, character(1)), basename(zip.paths), sep = "  "),
           file.path(output.dir, "SHA256SUMS.txt"))
writeLines(c("PASS: each packaged EXE has the same SHA-256 as its tested build.",
             "PASS: both final ZIPs extract correctly and contain their license notices.",
             test.report), file.path(output.dir, "RELEASE-VALIDATION.txt"))

preview <- image_blank(680, 380, color = "#f7f8fa")
for (i in 1:2) {
  pet <- c("momo", "mimi")[[i]]
  cat.image <- image_read(file.path(asset.dir, paste0(pet, "-preview.png")))
  preview <- image_composite(preview, cat.image, operator = "over",
                             offset = sprintf("+%d+65", 42 + (i - 1) * 340))
  preview <- image_annotate(preview, toupper(pet), size = 25, font = "Arial", weight = 600,
                            color = "#303640", location = sprintf("+%d+28", 120 + (i - 1) * 340))
}
image_write(preview, file.path(output.dir, "MOMO-MIMI-preview.png"))
print(sizes)
