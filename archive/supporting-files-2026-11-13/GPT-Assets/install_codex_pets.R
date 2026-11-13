library(jsonlite)
library(digest)

script.path <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
invisible(parse(file = script.path))

# Run without arguments for a read-only preflight; use --install to commit.
install.requested <- "--install" %in% commandArgs(trailingOnly = TRUE)
project.root <- normalizePath(".", winslash = "/", mustWork = TRUE)
codex.root <- normalizePath(file.path(Sys.getenv("USERPROFILE"), ".codex"),
                            winslash = "/", mustWork = TRUE)
pet.root <- normalizePath(file.path(codex.root, "pets"), winslash = "/", mustWork = TRUE)
stopifnot(identical(tolower(pet.root), tolower(paste0(codex.root, "/pets"))))

hash_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}

inventory_files <- function(directory) {
  paths <- sort(list.files(directory, recursive = TRUE, all.files = TRUE,
                            no.. = TRUE, include.dirs = FALSE))
  data.frame(path = paths, sha256 = vapply(file.path(directory, paths),
                                         hash_file, character(1)), row.names = NULL)
}

verify_files <- function(directory, expected) {
  actual <- inventory_files(directory)
  stopifnot(identical(actual, expected))
  invisible(TRUE)
}

sources <- setNames(file.path(project.root, c("MOMO-GPT/momo", "MIMI-GPT/mimi")),
                    c("momo", "mimi"))
source.inventory <- lapply(sources, inventory_files)
for (pet in names(sources)) {
  manifest <- read_json(file.path(sources[[pet]], "pet.json"))
  validation <- read_json(file.path(sources[[pet]], "validation.json"))
  stopifnot(identical(manifest$id, pet), manifest$spriteVersionNumber == 2L,
            identical(manifest$spritesheetPath, "spritesheet.webp"),
            validation$ok, validation$unchanged_source_cells == 74L,
            validation$edited_pose_cells == 0L,
            hash_file(file.path(sources[[pet]], manifest$spritesheetPath)) ==
              validation$spritesheet_sha256)
}

existing.momo <- file.path(pet.root, "momo")
new.mimi <- file.path(pet.root, "mimi")
stopifnot(dir.exists(existing.momo), !dir.exists(new.mimi),
          identical(read_json(file.path(existing.momo, "pet.json"))$id, "momo"))
old.inventory <- inventory_files(existing.momo)
cat("Preflight passed: validated original-art MOMO and MIMI packages.\n")
cat("Existing MOMO:", existing.momo, "\n")
cat("New MIMI:", new.mimi, "\n")
cat("Existing MOMO files to preserve:", nrow(old.inventory), "\n")
if (!install.requested) quit(status = 0L)

run.id <- format(Sys.time(), "%Y%m%d-%H%M%S", tz = "Asia/Manila")
backup.root <- file.path(project.root, "archive", paste0("codex-pets-before-", run.id))
stage.root <- file.path(project.root, "GPT-Assets", "work", paste0("codex-install-", run.id))
stopifnot(!dir.exists(backup.root), !dir.exists(stage.root))
dir.create(backup.root, recursive = TRUE)
dir.create(stage.root, recursive = TRUE)
backup.root <- normalizePath(backup.root, winslash = "/", mustWork = TRUE)
stopifnot(startsWith(tolower(backup.root), tolower(paste0(project.root, "/archive/"))))

# Prepare both complete directories before changing the installed pet.
for (pet in names(sources)) {
  stopifnot(file.copy(sources[[pet]], stage.root, recursive = TRUE))
  verify_files(file.path(stage.root, pet), source.inventory[[pet]])
}
verify_files(existing.momo, old.inventory)
write_json(list(status = "prepared", source_files = source.inventory,
                previous_momo_files = old.inventory),
           file.path(backup.root, "installation-plan.json"), auto_unbox = TRUE, pretty = TRUE)

backup.momo <- file.path(backup.root, "momo")
# Move the old directory into the workspace archive; do not delete any old file.
stopifnot(file.rename(existing.momo, backup.momo))
verify_files(backup.momo, old.inventory)
installed <- character()
tryCatch({
  for (pet in names(sources)) {
    destination <- file.path(pet.root, pet)
    stopifnot(!dir.exists(destination), file.copy(file.path(stage.root, pet), pet.root,
                                                recursive = TRUE))
    installed <- c(installed, pet)
    verify_files(destination, source.inventory[[pet]])
  }
}, error = function(error) {
  # Retain partial installs for inspection and restore the original MOMO.
  for (pet in names(sources)) {
    destination <- file.path(pet.root, pet)
    if (dir.exists(destination)) {
      stopifnot(file.rename(destination, file.path(stage.root, paste0(pet, "-failed"))))
    }
  }
  stopifnot(file.rename(backup.momo, existing.momo))
  stop(error)
})

result <- list(status = "installed-and-verified", installed_at = run.id,
  local_pet_root = pet.root, backup = backup.momo,
  previous_momo_files = old.inventory,
  installed = lapply(names(sources), function(pet) list(
    id = pet, directory = file.path(pet.root, pet),
    files = inventory_files(file.path(pet.root, pet)))),
  selection = "Original momo ID retained; no selection or global app settings changed")
write_json(result, file.path(backup.root, "installation-result.json"),
           auto_unbox = TRUE, pretty = TRUE)
write_json(result, file.path(project.root, "GPT-Assets", "codex-installation-result.json"),
           auto_unbox = TRUE, pretty = TRUE)
cat("Installed and verified MOMO and MIMI.\nBackup:", backup.momo, "\n")
