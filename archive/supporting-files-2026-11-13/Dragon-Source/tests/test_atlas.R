library(png)
library(magick)
library(jsonlite)
library(digest)

counts <- c(7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8)
paths <- c("assets/spritesheet.png", "../Dragon-GPT/dragon/spritesheet.webp")
decoded <- list()
for (path in paths) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  info <- image_info(image_read(path))
  stopifnot(info$width == 1536, info$height == 2288, info$matte, file.info(path)$size < 20 * 1024^2)
  rgba <- readPNG(image_write(image_read(path), format = "png"))
  decoded[[basename(path)]] <- rgba
  stopifnot(dim(rgba)[3] == 4)
  for (channel in 1:3) stopifnot(all(rgba[, , channel][rgba[, , 4] == 0] == 0))
  stopifnot(identical(rgba[1:208, 1:192, ], rgba[1:208, 1153:1344, ]))
  cells <- list()
  for (row in 0:10) for (column in 0:7) {
    yy <- seq.int(row * 208 + 1, (row + 1) * 208)
    xx <- seq.int(column * 192 + 1, (column + 1) * 192)
    alpha <- rgba[yy, xx, 4]
    used <- column < counts[[row + 1]]
    if (used) {
      stopifnot(mean(alpha > 0.125) > 0.08, mean(alpha > 0.125) < 0.8,
                any(alpha > 0 & alpha < 1),
                max(alpha[c(1:4, 205:208), ]) == 0, max(alpha[, c(1:4, 189:192)]) == 0)
    } else stopifnot(max(alpha) == 0)
    cells[[length(cells) + 1L]] <- list(row = row, frame = column, used = used,
      occupied.pixels = sum(alpha > 0.125), edge.clear = max(alpha[c(1:4, 205:208), ]) == 0 && max(alpha[, c(1:4, 189:192)]) == 0)
  }
  metrics <- read.csv("qa/final-frame-metrics.csv")
  jump <- metrics[metrics$state == "jumping", ]
  idle <- metrics[metrics$state == "idle", ]
  stopifnot(max(jump$lift) > 12, jump$lift[[1]] < 2, tail(jump$lift, 1) < 2,
            abs(jump$height[[1]] - median(idle$height)) <= 2)
  result <- list(ok = TRUE, scope = "R structural and registration checks; visual semantics recorded separately",
    file = normalizePath(path, winslash = "/"), sha256 = digest(readBin(path, "raw", file.info(path)$size), algo = "sha256", serialize = FALSE),
    width = info$width, height = info$height, version = 2, animation.and.look.frames = 73,
    neutral.cells = 1, populated.cells = 74, empty.cells = 14,
    jump.maximum.lift.pixels = max(jump$lift), cells = cells)
  out <- if (grepl("webp$", path)) "../Dragon-GPT/dragon/validation.json" else "qa/atlas-validation.json"
  write_json(result, out, pretty = TRUE, auto_unbox = TRUE)
  cat(sprintf("PASS: %s; 73 frames plus neutral, 14 empty cells, transparent borders, coherent lift scale.\n", basename(path)))
}
stopifnot(identical(decoded[[1]], decoded[[2]]))
cat("PASS: decoded PNG and lossless WebP contain identical RGBA pixels.\n")
