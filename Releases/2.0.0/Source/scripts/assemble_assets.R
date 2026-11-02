library(magick)
library(png)
library(processx)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("Usage: Rscript assemble_assets.R ARTWORK_DIR NEW_ASSET_DIR TOOLCHAIN_BIN")
artwork.dir <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output.dir <- args[[2]]
toolchain.dir <- normalizePath(args[[3]], winslash = "/", mustWork = TRUE)
stopifnot(!dir.exists(output.dir))
dir.create(output.dir, recursive = TRUE)
output.dir <- normalizePath(output.dir, winslash = "/")
script.path <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
project.dir <- dirname(dirname(normalizePath(script.path, winslash = "/")))
Sys.setenv(PATH = paste(toolchain.dir, Sys.getenv("PATH"), sep = .Platform$path.sep))
r.bin <- R.home("bin")
if (!file.exists(file.path(r.bin, "R.dll"))) r.bin <- file.path(r.bin, "x64")
helper.path <- file.path(output.dir, "components.dll")
run(file.path(toolchain.dir, "g++.exe"), c("-O2", "-shared", "-static-libgcc", "-static-libstdc++",
  paste0("-I", R.home("include")), file.path(project.dir, "scripts", "components_native.cpp"),
  paste0("-L", r.bin), "-lR", "-o", helper.path), windows_hide_window = TRUE)
dyn.load(helper.path)
source(file.path(project.dir, "scripts", "component_helpers.R"))
source(file.path(project.dir, "scripts", "extract_frames.R"))
frame.counts <- c(7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8)
frame.map <- data.frame(row = rep(seq_along(frame.counts), frame.counts),
                        column = unlist(lapply(frame.counts, seq_len)))
frame.map$sheet <- (seq_len(nrow(frame.map)) - 1L) %/% 16L + 1L
frame.map$cell <- (seq_len(nrow(frame.map)) - 1L) %% 16L + 1L
coverage <- list()

for (pet in c("momo", "mimi")) {
  extracted <- extract_frames(artwork.dir, pet)
  write.csv(extracted$bounds, file.path(output.dir, paste0(pet, "-source-bounds.csv")), row.names = FALSE)
  cat(sprintf("%s: extracted 74 complete cats; repaired %d frames crossing the original grid.\n",
              pet, sum(extracted$bounds$crossed.grid)))
  atlas <- image_blank(2048, 3080, color = "none")
  for (i in seq_len(nrow(frame.map))) {
    frame <- frame.map[i, ]
    cell <- extracted$cells[[i]]
    # Repacking and resizing retain the generated full alpha channel.
    atlas <- image_composite(atlas, cell, operator = "over",
      offset = sprintf("+%d+%d", (frame$column - 1) * 256, (frame$row - 1) * 280))
    rgba <- image_data(cell, channels = "rgba")
    alpha <- as.integer(rgba[4, , ]) / 255
    fraction <- mean(alpha > 0.125)
    stopifnot(fraction > 0.08, fraction < 0.95, any(alpha > 0 & alpha < 1))
    coverage[[length(coverage) + 1L]] <- data.frame(pet, frame = i, fraction)
    if (i == 1L) {
      image_write(cell, file.path(output.dir, paste0(pet, "-preview.png")), depth = 8)
      icon <- image_extent(image_resize(cell, "256x256"), "256x256", gravity = "center", color = "none")
      icon.sizes <- c(16, 24, 32, 48, 64, 128, 256)
      icon.images <- image_join(lapply(icon.sizes, function(size) image_resize(icon, sprintf("%dx%d!", size, size))))
      image_write(icon.images, file.path(output.dir, paste0(pet, ".ico")), format = "ico", depth = 8)
    }
  }
  # A single RGBA atlas replaces the four sizes used by the R editions.
  image_write(atlas, file.path(output.dir, paste0(pet, "-atlas.png")), depth = 8,
              defines = c("png:compression-level" = "9"))
  saved.rgba <- readPNG(file.path(output.dir, paste0(pet, "-atlas.png")))
  for (i in seq_len(nrow(frame.map))) {
    frame <- frame.map[i, ]
    yy <- seq.int((frame$row - 1) * 280 + 1, frame$row * 280)
    xx <- seq.int((frame$column - 1) * 256 + 1, frame$column * 256)
    saved.coverage <- mean(saved.rgba[yy, xx, 4] > 0.125)
    stopifnot(saved.coverage > 0.08, saved.coverage < 0.95)
    alpha <- saved.rgba[yy, xx, 4]
    stopifnot(max(alpha[c(1:6, 275:280), ]) == 0, max(alpha[, c(1:6, 251:256)]) == 0)
  }
  preview <- image_read(file.path(output.dir, paste0(pet, "-preview.png")))
  dark <- image_composite(image_blank(320, 340, color = "#20242b"), preview, offset = "+32+30")
  light <- image_composite(image_blank(320, 340, color = "#f3f2ef"), preview, offset = "+32+30")
  image_write(image_append(c(dark, light)), file.path(output.dir, paste0(pet, "-edge-check.png")))
}
write.csv(do.call(rbind, coverage), file.path(output.dir, "frame-coverage.csv"), row.names = FALSE)
cat("Assembled 74 frames per pet with full transparency, previews and Windows icons.\n")
