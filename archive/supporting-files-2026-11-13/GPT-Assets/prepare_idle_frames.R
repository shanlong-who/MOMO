library(magick)
library(png)
library(jsonlite)

dyn.load(normalizePath("Releases/2.0.0/Source/assets/aligned/components.dll"))
source("Releases/2.0.0/Source/scripts/component_helpers.R")
dir.create("GPT-Assets/idle-frames", recursive = TRUE, showWarnings = FALSE)

for (pet in c("momo", "mimi")) {
  source.path <- paste0("GPT-Assets/artwork/", pet, "-idle-front.png")
  rgba <- readPNG(source.path)
  height <- dim(rgba)[1]
  width <- dim(rgba)[2]
  labelled <- label_components(rgba[, , 4], threshold = 0.125)
  objects <- labelled$components
  objects <- objects[objects$area > 10000, ]
  objects$column <- floor(objects$cx / (width / 4))
  objects$row <- floor(objects$cy / (height / 2))
  objects$slot <- objects$row * 4L + objects$column + 1L
  stopifnot(nrow(objects) == 7L, identical(sort(as.integer(objects$slot)), 1:7))
  objects <- objects[order(objects$slot), ]
  common.scale <- min(174 / max(objects$xmax - objects$xmin + 1),
                      184 / max(objects$ymax - objects$ymin + 1))
  pet.dir <- file.path("GPT-Assets/idle-frames", pet)
  dir.create(pet.dir, showWarnings = FALSE)
  for (i in 1:7) {
    object <- objects[i, ]
    xx <- seq.int(max(0, object$xmin - 3), min(width - 1, object$xmax + 3)) + 1L
    yy <- seq.int(max(0, object$ymin - 3), min(height - 1, object$ymax + 3)) + 1L
    crop <- rgba[yy, xx, , drop = FALSE]
    core <- labelled$labels[yy, xx, drop = FALSE] == object$id
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
    size <- pmax(1L, round(c(length(xx), length(yy)) * common.scale))
    sprite <- image_resize(image_read(writePNG(crop)),
                           sprintf("%dx%d!", size[1], size[2]), filter = "Lanczos")
    # One shared scale and foot baseline; no frame-by-frame size normalization.
    x <- floor((192L - size[1]) / 2L)
    y <- 200L - size[2]
    cell <- image_composite(image_blank(192, 208, "none"), sprite, operator = "over",
                             offset = sprintf("+%d+%d", x, y))
    image_write(cell, file.path(pet.dir, sprintf("idle-%02d.png", i - 1L)), depth = 8)
  }
  write_json(list(source = source.path, common_scale = common.scale, baseline = 200,
                  objects = objects), file.path(pet.dir, "extraction.json"),
             auto_unbox = TRUE, pretty = TRUE)
  cat(pet, ": extracted seven complete frontal idle poses.\n")
}
