library(magick)
library(png)
library(jsonlite)
library(digest)

output.dir <- "GPT-Assets/cloud-pet-check-20261113"
dir.create(output.dir, recursive = TRUE, showWarnings = FALSE)
pet.root <- file.path(Sys.getenv("USERPROFILE"), ".codex", "pets")
hash_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}

old.paths <- c(
  "archive/cloud-momo-before-update-20261113/momo-active-original.png",
  "archive/cloud-momo-before-update-20261113/momo-local-migrated.png")
old.hashes <- vapply(old.paths, hash_file, character(1))
stopifnot(length(unique(old.hashes)) == 1L)
panels <- list()
for (i in seq_along(old.paths)) {
  sprite <- image_crop(image_read(old.paths[[i]]), "192x208+0+0", repage = TRUE)
  panel <- image_composite(image_blank(240, 256, "#f1f3f7"), sprite,
                            operator = "over", offset = "+24+40")
  panel <- image_annotate(panel, c("Existing active MOMO", "Existing migrated MOMO")[[i]],
                           location = "+8+22", size = 14, font = "Arial", color = "#26313d")
  panels[[i]] <- panel
}
new.sprite <- image_crop(image_read(file.path(pet.root, "momo/spritesheet.webp")),
                          "192x208+0+0", repage = TRUE)
new.panel <- image_composite(image_blank(240, 256, "#f1f3f7"), new.sprite,
                              operator = "over", offset = "+24+40")
new.panel <- image_annotate(new.panel, "Confirmed collar-free MOMO",
                            location = "+8+22", size = 14, font = "Arial", color = "#26313d")
image_write(image_append(image_join(c(panels, list(new.panel)))),
              file.path(output.dir, "before-and-requested.png"))

counts <- c(7L, 8L, 8L, 4L, 5L, 8L, 6L, 6L, 6L, 8L, 8L)
states <- c("idle", "running-right", "running-left", "waving", "jumping", "failed",
             "waiting", "running", "review", "look-first-half", "look-second-half")
results <- list()
for (pet in c("momo", "mimi")) {
  source.dir <- paste0(toupper(pet), "-GPT/", pet)
  installed.dir <- file.path(pet.root, pet)
  manifest <- read_json(file.path(installed.dir, "pet.json"))
  installed.path <- file.path(installed.dir, manifest$spritesheetPath)
  expected.hash <- hash_file(file.path(source.dir, "spritesheet.webp"))
  stopifnot(manifest$id == pet, hash_file(installed.path) == expected.hash)
  atlas <- image_read(installed.path)
  stopifnot(image_info(atlas)$width == 1536L, image_info(atlas)$height == 2288L)
  cells <- list()
  occupied <- 0L
  for (row in 0:10) {
    row.hashes <- character()
    for (column in 0:7) {
      img <- image_crop(atlas, sprintf("192x208+%d+%d", column * 192L, row * 208L),
                         repage = TRUE)
      rgba <- readPNG(image_write(img, format = "png", defines = c("png:color-type" = "6")))
      alpha <- rgba[, , 4]
      if (column < counts[[row + 1L]]) {
        stopifnot(any(alpha > 0.5), max(alpha[c(1, 208), ]) == 0,
                  max(alpha[, c(1, 192)]) == 0)
        occupied <- occupied + 1L
        row.hashes <- c(row.hashes, digest(rgba, algo = "sha256"))
      } else stopifnot(max(alpha) == 0)
    }
    cells[[row + 1L]] <- list(state = states[[row + 1L]],
      populated_cells = length(row.hashes), distinct_frames = length(unique(row.hashes)))
    stopifnot(length(unique(row.hashes)) >= 2L)
  }
  stopifnot(occupied == 74L)
  results[[pet]] <- list(installed_file_matches_approved_package = TRUE,
    sha256 = expected.hash, populated_cells = occupied, unused_cells = 14L,
    edge_clipping = FALSE, state_frame_variation = cells,
    runtime_switch = "Requires desktop observation; local files cannot establish cloud selection")
}
write_json(list(old_cloud_momo_images_are_identical = TRUE,
                 old_cloud_sha256 = unname(old.hashes[[1]]), pets = results),
             file.path(output.dir, "local-and-original-cloud-check.json"),
             auto_unbox = TRUE, pretty = TRUE)
cat("Both old cloud MOMO images are byte-identical.\n")
cat("Both installed atlases match the approved packages; all 74 cells, transparent unused slots,\n")
cat("cell edges and per-state frame variation passed.\n")
