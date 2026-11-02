extract_frames <- function(artwork.dir, pet) {
  frames <- vector("list", 74)
  bounds <- list()
  for (sheet in 1:5) {
    path <- file.path(artwork.dir, sprintf("%s-sheet-%d.png", pet, sheet))
    rgba <- readPNG(path)
    stopifnot(length(dim(rgba)) == 3L, dim(rgba)[3] == 4L)
    height <- dim(rgba)[1]
    width <- dim(rgba)[2]
    labelled <- label_components(rgba[, , 4])
    objects <- labelled$components
    objects <- objects[objects$area > 1000, ]
    expected <- if (sheet == 5) 10L else 16L
    objects$column <- floor(objects$cx / (width / 4)) + 1L
    objects$row <- floor(objects$cy / (height / 4)) + 1L
    objects$cell <- (objects$row - 1L) * 4L + objects$column
    stopifnot(nrow(objects) == expected, identical(sort(as.integer(objects$cell)), seq_len(expected)))
    objects <- objects[order(objects$cell), ]
    for (i in seq_len(nrow(objects))) {
      object <- objects[i, ]
      xx <- seq.int(max(0, object$xmin - 3), min(width - 1, object$xmax + 3)) + 1L
      yy <- seq.int(max(0, object$ymin - 3), min(height - 1, object$ymax + 3)) + 1L
      crop <- rgba[yy, xx, , drop = FALSE]
      core <- labelled$labels[yy, xx, drop = FALSE] == object$id
      # Retain the full silhouette and its soft edge, excluding adjacent cats.
      allowed <- matrix(FALSE, nrow(core), ncol(core))
      for (dx in -2:2) for (dy in -2:2) {
        target.x <- seq.int(max(1, 1 + dx), min(ncol(core), ncol(core) + dx))
        target.y <- seq.int(max(1, 1 + dy), min(nrow(core), nrow(core) + dy))
        allowed[target.y, target.x] <- allowed[target.y, target.x] |
          core[target.y - dy, target.x - dx]
      }
      alpha <- crop[, , 4]
      alpha[!allowed | alpha <= 3 / 255] <- 0
      crop[, , 4] <- alpha
      for (channel in 1:3) {
        values <- crop[, , channel]
        values[alpha == 0] <- 0
        crop[, , channel] <- values
      }
      frame <- (sheet - 1L) * 16L + object$cell
      frames[[frame]] <- list(
        image = image_read(writePNG(crop)),
        width = length(xx) * 1024 / width,
        height = length(yy) * 1120 / height)
      object$pet <- pet
      object$sheet <- sheet
      object$frame <- frame
      object$crossed.grid <- object$xmin < (object$column - 1) * width / 4 |
        object$xmax >= object$column * width / 4 |
        object$ymin < (object$row - 1) * height / 4 |
        object$ymax >= object$row * height / 4
      bounds[[length(bounds) + 1L]] <- object
    }
  }
  widths <- vapply(frames, function(frame) frame$width, numeric(1))
  heights <- vapply(frames, function(frame) frame$height, numeric(1))
  # One scale per cat preserves pose proportions; no frame is stretched to fit.
  scale <- min(240 / max(widths), 256 / max(heights), 1)
  cells <- lapply(frames, function(frame) {
    size <- pmax(1L, round(c(frame$width, frame$height) * scale))
    cat.image <- image_resize(frame$image, sprintf("%dx%d!", size[1], size[2]), filter = "Lanczos")
    x <- floor((256 - size[1]) / 2)
    y <- 280 - 12 - size[2]
    stopifnot(x >= 8, y >= 12)
    image_composite(image_blank(256, 280, color = "none"), cat.image,
                    operator = "over", offset = sprintf("+%d+%d", x, y))
  })
  list(cells = cells, bounds = do.call(rbind, bounds), scale = scale)
}
