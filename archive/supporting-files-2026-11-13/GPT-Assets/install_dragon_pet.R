library(jsonlite)
library(digest)
library(magick)

# Without --install this script only validates the source and destination.
install.requested <- "--install" %in% commandArgs(trailingOnly = TRUE)
project.root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source.dir <- normalizePath("Dragon-GPT/dragon", winslash = "/", mustWork = TRUE)
codex.root <- normalizePath(file.path(Sys.getenv("USERPROFILE"), ".codex"), winslash = "/", mustWork = TRUE)
pet.root <- normalizePath(file.path(codex.root, "pets"), winslash = "/", mustWork = TRUE)
destination <- file.path(pet.root, "dragon")
stopifnot(tolower(pet.root) == tolower(paste0(codex.root, "/pets")))

hash_file <- function(path) {
  digest(readBin(path, "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)
}
inventory_files <- function(directory, exclude.dragon = FALSE) {
  files <- sort(list.files(directory, recursive = TRUE, all.files = TRUE,
                           no.. = TRUE, include.dirs = FALSE))
  if (exclude.dragon) files <- files[!startsWith(tolower(files), "dragon/")]
  data.frame(path = files, sha256 = vapply(file.path(directory, files), hash_file, character(1)),
              row.names = NULL, stringsAsFactors = FALSE)
}
verify_files <- function(directory, expected) {
  stopifnot(identical(inventory_files(directory), expected))
}

manifest <- read_json(file.path(source.dir, "pet.json"))
validation <- read_json(file.path(source.dir, "validation.json"))
sprite.path <- file.path(source.dir, manifest$spritesheetPath)
sprite.info <- image_info(image_read(sprite.path))
stopifnot(manifest$id == "dragon", manifest$displayName == "Dragon",
          manifest$spriteVersionNumber == 2L, manifest$spritesheetPath == "spritesheet.webp",
          validation$ok, validation$populated.cells == 74L,
          hash_file(sprite.path) == validation$sha256,
          sprite.info$width == 1536L, sprite.info$height == 2288L, sprite.info$matte)
source.inventory <- inventory_files(source.dir)
other.inventory <- inventory_files(pet.root, exclude.dragon = TRUE)
old.inventory <- if (dir.exists(destination)) inventory_files(destination) else NULL
if (!is.null(old.inventory)) stopifnot(read_json(file.path(destination, "pet.json"))$id == "dragon")
cat("Preflight passed: Dragon 2.0 manifest, validated atlas hash and complete source inventory.\n")
cat("Destination:", destination, "\n")
cat("Files to install:", nrow(source.inventory), "; existing Dragon:", !is.null(old.inventory), "\n")
if (!install.requested) quit(status = 0L)

run.id <- format(Sys.time(), "%Y%m%d-%H%M%S", tz = "Asia/Manila")
stage.root <- file.path(project.root, "GPT-Assets/work", paste0("dragon-desktop-install-", run.id))
backup.root <- file.path(project.root, "archive", paste0("dragon-desktop-before-", run.id))
stopifnot(!dir.exists(stage.root), !dir.exists(backup.root))
dir.create(stage.root, recursive = TRUE)
stopifnot(file.copy(source.dir, stage.root, recursive = TRUE))
verify_files(file.path(stage.root, "dragon"), source.inventory)
backup.path <- NULL
if (!is.null(old.inventory)) {
  verify_files(destination, old.inventory)
  dir.create(backup.root, recursive = TRUE)
  backup.root <- normalizePath(backup.root, winslash = "/", mustWork = TRUE)
  stopifnot(startsWith(tolower(backup.root), tolower(paste0(project.root, "/archive/"))))
  backup.path <- file.path(backup.root, "dragon")
  stopifnot(file.rename(destination, backup.path))
  verify_files(backup.path, old.inventory)
}
tryCatch({
  stopifnot(!dir.exists(destination), file.copy(file.path(stage.root, "dragon"), pet.root, recursive = TRUE))
  verify_files(destination, source.inventory)
  stopifnot(identical(inventory_files(pet.root, exclude.dragon = TRUE), other.inventory))
}, error = function(error) {
  # Preserve an incomplete copy for inspection; restore a prior Dragon if needed.
  if (dir.exists(destination)) stopifnot(file.rename(destination, file.path(stage.root, "dragon-incomplete")))
  if (!is.null(backup.path)) stopifnot(file.rename(backup.path, destination))
  stop(error)
})
result <- list(status = "installed-and-verified", edition = "2.0.0", installed_at = run.id,
  destination = destination, source = source.dir, backup = backup.path,
  sprite_sha256 = hash_file(file.path(destination, "spritesheet.webp")),
  files_verified = nrow(source.inventory), other_pet_files_unchanged = nrow(other.inventory),
  installed_files = source.inventory,
  activation = "Installed in the local desktop library. Refresh and selection in the app have not been performed.")
write_json(result, file.path(stage.root, "installation-result.json"), auto_unbox = TRUE, pretty = TRUE)
write_json(result, file.path(project.root, "GPT-Assets/dragon-installation-result.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Installed and verified Dragon 2.0:", destination, "\n")
cat("Existing pet files preserved:", nrow(other.inventory), "\n")
