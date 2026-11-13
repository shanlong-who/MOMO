library(jsonlite)
library(digest)
library(zip)
library(magick)

# Run from the project root. Existing package bytes are copied without repacking.
release.dir <- "Releases/2.1.0"
dir.create(release.dir, recursive = TRUE, showWarnings = FALSE)
hash_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}
read_checksums <- function(path) {
  lines <- readLines(path, warn = FALSE)
  values <- sub("\\s+.*$", "", lines)
  names(values) <- sub("^[^[:space:]]+[[:space:]]+", "", lines)
  values
}

cat.hashes <- read_checksums("Releases/2.0.0/SHA256SUMS.txt")
dragon.hashes <- read_checksums("archive/supporting-files-2026-11-13/Dragon-SHA256SUMS.txt")
packages <- data.frame(
  character = rep(c("MOMO", "MIMI", "Dragon"), each = 2L),
  edition = rep(c("GPT", "Offline"), 3L),
  source = c("MOMO-GPT/momo-pet-v2.zip", "Releases/2.0.0/MOMO-Lite-2.0.0-windows-x64.zip",
    "MIMI-GPT/mimi-pet-v2.zip", "Releases/2.0.0/MIMI-Lite-2.0.0-windows-x64.zip",
    "Dragon-GPT/dragon-pet-v2.zip",
    "archive/supporting-files-2026-11-13/Dragon-Offline-windows-x64.zip"),
  expected = c(read_checksums("MOMO-GPT/SHA256SUMS.txt")[["momo-pet-v2.zip"]],
    cat.hashes[["MOMO-Lite-2.0.0-windows-x64.zip"]],
    read_checksums("MIMI-GPT/SHA256SUMS.txt")[["mimi-pet-v2.zip"]],
    cat.hashes[["MIMI-Lite-2.0.0-windows-x64.zip"]],
    dragon.hashes[["dragon-pet-v2.zip"]], dragon.hashes[["Dragon-Offline-windows-x64.zip"]]),
  stringsAsFactors = FALSE)
packages$filename <- basename(packages$source)
packages$sha256 <- vapply(packages$source, hash_file, character(1))
stopifnot(all(packages$expected == packages$sha256), !anyDuplicated(packages$filename))
packages$bytes <- file.info(packages$source)$size
packages$component_version <- ifelse(packages$edition == "GPT", "sprite v2", "2.0.0")
validation <- c(
  "MOMO, MIMI and Dragon collection 2.1.0 - distribution validation",
  "Prepared on 2026-11-13 (Asia/Manila).", "",
  "PASS: All six ZIPs match their existing recorded SHA-256 values.",
  "PASS: No executable, artwork, animation or distribution ZIP was rebuilt or modified.")

for (i in seq_len(nrow(packages))) {
  package <- packages[i, ]
  destination <- file.path(release.dir, package$filename)
  if (file.exists(destination)) stopifnot(hash_file(destination) == package$sha256) else
    stopifnot(file.copy(package$source, destination))
  stopifnot(hash_file(destination) == package$sha256)
  entries <- zip_list(destination)$filename
  stopifnot(!any(grepl("(^/|^[A-Za-z]:|(^|/)\\.\\.(/|$)|\\\\)", entries)))
  extracted.dir <- tempfile(paste0("release-", tolower(package$character), "-"))
  dir.create(extracted.dir)
  zip::unzip(destination, exdir = extracted.dir)

  if (package$edition == "GPT") {
    pet <- tolower(package$character)
    source.dir <- file.path(paste0(package$character, "-GPT"), pet)
    extracted.pet <- file.path(extracted.dir, pet)
    manifest <- read_json(file.path(extracted.pet, "pet.json"))
    stopifnot(manifest$id == pet, manifest$spriteVersionNumber == 2L,
              manifest$spritesheetPath == "spritesheet.webp")
    source.files <- list.files(source.dir, recursive = TRUE)
    for (file in source.files) {
      stopifnot(hash_file(file.path(extracted.pet, file)) == hash_file(file.path(source.dir, file)))
    }
    sheet <- image_read(file.path(extracted.pet, manifest$spritesheetPath))
    stopifnot(image_info(sheet)$width == 1536L, image_info(sheet)$height == 2288L,
              image_info(sheet)$matte)
    validation <- c(validation, sprintf(
      "PASS: %s GPT extracts successfully; manifest, transparent v2 sheet and all package files match the approved folder.",
      package$character))
  } else {
    root <- if (package$character == "Dragon") "Dragon-Offline" else
      paste0(package$character, "-Lite-2.0.0")
    executable <- if (package$character == "Dragon") "Dragon-Offline.exe" else
      paste0(package$character, ".exe")
    extracted.exe <- file.path(extracted.dir, root, executable)
    approved.exe <- file.path(paste0(package$character, "-Offline"), executable)
    stopifnot(hash_file(extracted.exe) == hash_file(approved.exe))
    validation <- c(validation, sprintf(
      "PASS: %s Offline extracts successfully; packaged EXE matches the current tested project EXE.",
      package$character))
  }
}
validation <- c(validation, "",
  "This release check verifies distribution integrity and package extraction.",
  "Previously recorded native application tests remain in the repository and packages.",
  "The collection version is 2.1.0; the native applications retain internal version 2.0.0.")
validation.path <- file.path(release.dir, "RELEASE-VALIDATION.txt")
writeLines(validation, validation.path, useBytes = TRUE)
checksum.lines <- c(paste(packages$sha256, packages$filename, sep = "  "),
                     paste(hash_file(validation.path), "RELEASE-VALIDATION.txt", sep = "  "))
writeLines(checksum.lines, file.path(release.dir, "SHA256SUMS.txt"), useBytes = TRUE)
write_json(list(collection_version = "2.1.0", tag = "v2.1.0", packages = packages,
  checksum_file = "SHA256SUMS.txt", validation_file = "RELEASE-VALIDATION.txt"),
  file.path(release.dir, "release-manifest.json"), auto_unbox = TRUE, pretty = TRUE)
cat("PASS: prepared six unchanged ZIPs, consolidated checksums and extraction validation.\n")
print(packages[, c("character", "edition", "filename", "bytes")], row.names = FALSE)
