library(magick)
library(png)

args <- commandArgs(trailingOnly = TRUE)
script_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(script_file)) script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
app_dir <- if (length(args)) normalizePath(args[[1]], winslash = "/") else dirname(dirname(normalizePath(script_file, winslash = "/")))
source(file.path(app_dir, "bootstrap.R"), local = TRUE)
report_dir <- momo_ensure_directory(momo_runtime_paths()$reports)
original <- image_read(file.path(app_dir, "assets", "original-spritesheet.png"))
frame_counts <- c(7L, 8L, 8L, 4L, 5L, 8L, 6L, 6L, 6L, 8L, 8L)

for (width in c(144L, 192L, 240L, 288L)) {
  height <- as.integer(width * 208L / 192L)
  atlas_pixels <- array(0, dim = c(height * 11L, width * 8L, 4L))
  for (row in seq_along(frame_counts)) {
    for (column in seq_len(frame_counts[[row]])) {
      frame <- image_crop(original, sprintf("192x208+%d+%d", (column - 1L) * 192L, (row - 1L) * 208L), repage = TRUE)
      frame <- image_resize(frame, sprintf("%dx%d!", width, height), filter = "Lanczos")
      rgba <- aperm(image_data(frame, channels = "rgba"), c(3L, 2L, 1L))
      rgba <- array(as.integer(rgba) / 255, dim = dim(rgba))
      # Windows Tk supports a transparent color, so use a crisp binary mask
      # to prevent the key color from tinting partially transparent fur edges.
      rgba[, , 4L] <- as.numeric(rgba[, , 4L] >= 0.4)
      y <- seq.int((row - 1L) * height + 1L, row * height)
      x <- seq.int((column - 1L) * width + 1L, column * width)
      atlas_pixels[y, x, ] <- rgba
    }
  }
  writePNG(atlas_pixels, file.path(app_dir, "assets", sprintf("momo-%d.png", width)))
}
writeLines(c(
  "Prepared 74 occupied cells at four sizes from the original MOMO artwork.",
  "The source artwork is retained unchanged.",
  "Display assets use a binary alpha mask for Windows Tk color transparency."
), file.path(report_dir, "asset-preparation.txt"))
cat("Prepared local Tk artwork at all four sizes.\n")
