library(magick)
library(png)

args <- commandArgs(trailingOnly = TRUE)
script_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(script_file)) script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
app_dir <- if (length(args)) normalizePath(args[[1]], winslash = "/") else dirname(dirname(normalizePath(script_file, winslash = "/")))
source(file.path(app_dir, "bootstrap.R"), local = TRUE)
report_dir <- mimi_ensure_directory(mimi_runtime_paths()$reports)
original <- image_read(file.path(app_dir, "assets", "original-spritesheet.png"))
source_info <- image_info(original)
stopifnot(length(original) == 1L, source_info$matte)
# The generator may return a nearby canvas size; map its regular grid to
# the unchanged runtime cell dimensions before making the display atlases.
normalized <- image_resize(original, "1536x2288!", filter = "Lanczos")
frame_counts <- c(7L, 8L, 8L, 4L, 5L, 8L, 6L, 6L, 6L, 8L, 8L)
coverage <- list()

for (width in c(144L, 192L, 240L, 288L)) {
  height <- as.integer(width * 208L / 192L)
  atlas_pixels <- array(0, dim = c(height * 11L, width * 8L, 4L))
  for (row in seq_along(frame_counts)) {
    for (column in seq_len(frame_counts[[row]])) {
      frame <- image_crop(normalized, sprintf("192x208+%d+%d", (column - 1L) * 192L, (row - 1L) * 208L), repage = TRUE)
      frame <- image_resize(frame, sprintf("%dx%d!", width, height), filter = "Lanczos")
      rgba <- aperm(image_data(frame, channels = "rgba"), c(3L, 2L, 1L))
      rgba <- array(as.integer(rgba) / 255, dim = dim(rgba))
      # Windows Tk uses a color key, so prepared frames need binary alpha.
      rgba[, , 4L] <- as.numeric(rgba[, , 4L] >= 0.4)
      fraction <- mean(rgba[, , 4L])
      stopifnot(fraction > 0.08, fraction < 0.95)
      coverage[[length(coverage) + 1L]] <- data.frame(width, row, column, fraction)
      y <- seq.int((row - 1L) * height + 1L, row * height)
      x <- seq.int((column - 1L) * width + 1L, column * width)
      atlas_pixels[y, x, ] <- rgba
    }
  }
  writePNG(atlas_pixels, file.path(app_dir, "assets", sprintf("mimi-%d.png", width)))
}
preview <- image_crop(image_read(file.path(app_dir, "assets", "mimi-192.png")), "192x208+1152+0", repage = TRUE)
image_write(preview, file.path(app_dir, "assets", "mimi-preview.png"))
icon <- image_extent(image_resize(preview, "256x256"), "256x256", gravity = "center", color = "none")
image_write(icon, file.path(app_dir, "assets", "mimi.ico"), format = "ico")
write.csv(do.call(rbind, coverage), file.path(report_dir, "asset-coverage.csv"), row.names = FALSE)
writeLines(c(
  "Prepared 74 occupied cells at four sizes from the generated MIMI artwork.",
  sprintf("Source artwork: %d x %d, retained unchanged.", source_info$width, source_info$height),
  "The regular 8 x 11 grid is mapped to the original MOMO runtime cell dimensions.",
  "Display assets use a binary alpha mask for Windows Tk color transparency."
), file.path(report_dir, "asset-preparation.txt"))
cat("Prepared MIMI artwork at all four sizes, preview and icon.\n")
