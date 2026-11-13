library(magick)
library(png)
library(jsonlite)
library(digest)

standard.only <- "--standard" %in% commandArgs(trailingOnly = TRUE)
states <- c("idle", "running-right", "running-left", "waving", "jumping", "failed", "waiting", "running", "review")
counts <- c(6, 8, 8, 4, 5, 8, 6, 6, 6)
if (!standard.only) {
  states <- c(states, "look-first", "look-second")
  counts <- c(counts, 8, 8)
}
atlas <- image_blank(1536, 2288, color = "none")
cells <- list()
metrics <- list()
row.cells <- list()
look.scale <- NULL
if (!standard.only) {
  # Both source look families use one normalized scale, preserving their shared registration.
  look.heights <- numeric()
  for (state in c("look-first", "look-second")) {
    figures <- readRDS(file.path("qa/rows", state, "figures.rds"))
    meta <- read_json(file.path("qa/rows", state, "extraction.json"))
    norm <- 1024 / meta$source.height
    look.heights <- c(look.heights, vapply(figures, function(x) x$height * norm, numeric(1)))
  }
  look.scale <- 176 / median(look.heights)
}
for (row in seq_along(states)) {
  state <- states[[row]]
  figures <- readRDS(file.path("qa/rows", state, "figures.rds"))
  stopifnot(length(figures) == counts[[row]])
  widths <- vapply(figures, `[[`, numeric(1), "width")
  heights <- vapply(figures, `[[`, numeric(1), "height")
  scale <- min(176 / median(heights), 176 / max(widths), 184 / max(heights))
  if (state %in% c("look-first", "look-second")) {
    meta <- read_json(file.path("qa/rows", state, "extraction.json"))
    scale <- look.scale * 1024 / meta$source.height
    stopifnot(max(widths * scale) <= 176, max(heights * scale) <= 188)
  }
  bottoms <- vapply(figures, `[[`, numeric(1), "source.bottom")
  lifts <- rep(0, length(figures))
  if (state == "jumping") {
    scale <- min(176 / mean(heights[c(1, length(heights))]), 176 / max(widths))
    lifts <- (max(bottoms) - bottoms) * scale
    stopifnot(max(lifts) >= 12, lifts[[1]] < 8, tail(lifts, 1) < 8)
    # Preserve standing stature and source lift; compress only the arc to safe top padding.
    airborne <- lifts > 0
    arc.factor <- min(1, (190 - heights[airborne] * scale) / lifts[airborne])
    lifts <- lifts * arc.factor
  }
  row.cells[[state]] <- vector("list", length(figures))
  for (i in seq_along(figures)) {
    figure <- figures[[i]]
    size <- round(c(figure$width, figure$height) * scale)
    pose <- image_resize(image_read(figure$path), sprintf("%dx%d!", size[1], size[2]), filter = "Lanczos")
    x <- floor((192 - size[1]) / 2)
    if (state %in% c("running-right", "running-left")) {
      source.rgba <- readPNG(figure$path)
      head.alpha <- source.rgba[seq_len(round(figure$height * 0.27)), , 4]
      head.x <- sum(colSums(head.alpha) * seq_len(ncol(head.alpha))) / sum(head.alpha)
      target.x <- if (state == "running-right") 112 else 80
      x <- round(target.x - head.x * scale)
      x <- max(6, min(186 - size[1], x))
    }
    y <- round(198 - size[2] - lifts[[i]])
    stopifnot(x >= 6, y >= 6, x + size[1] <= 186, y + size[2] <= 202)
    cell <- image_composite(image_blank(192, 208, color = "none"), pose, operator = "over",
                            offset = sprintf("+%d+%d", x, y))
    row.cells[[state]][[i]] <- cell
    atlas <- image_composite(atlas, cell, operator = "over", offset = sprintf("+%d+%d", (i - 1) * 192, (row - 1) * 208))
    cells[[length(cells) + 1L]] <- cell
    metrics[[length(metrics) + 1L]] <- data.frame(state, row = row - 1L, frame = i - 1L,
         width = size[1], height = size[2], x, y, lift = lifts[[i]], source.scale = scale)
  }
}
metrics <- do.call(rbind, metrics)
stem <- if (standard.only) "standard" else "final"
write.csv(metrics, file.path("qa", paste0(stem, "-frame-metrics.csv")), row.names = FALSE)
atlas.path <- if (standard.only) "qa/standard-atlas.png" else "assets/spritesheet.png"
image_write(atlas, atlas.path, depth = 8)

# Contact sheets and previews are rendered from exact encoded output cells.
encoded <- image_read(atlas.path)
contact <- image_blank(1536, length(states) * 236, color = "#eceef3")
for (row in seq_along(states)) {
  state <- states[[row]]
  contact <- image_annotate(contact, state, size = 16, font = "Arial", color = "#35384b",
                             location = sprintf("+12+%d", (row - 1) * 236 + 1))
  rendered <- list()
  for (i in seq_len(counts[[row]])) {
    crop <- image_crop(encoded, sprintf("192x208+%d+%d", (i - 1) * 192, (row - 1) * 208), repage = TRUE)
    rendered[[i]] <- image_composite(image_blank(192, 208, color = "#28303b"), crop, operator = "over")
    contact <- image_composite(contact, rendered[[i]], offset = sprintf("+%d+%d", (i - 1) * 192, (row - 1) * 236 + 24))
  }
  fps <- if (state %in% c("running-right", "running-left", "jumping")) 10 else 5
  animation <- image_animate(image_join(rendered), fps = fps, loop = 0, dispose = "background")
  image_write(animation, file.path("../Dragon-GPT/dragon/previews", paste0(state, ".gif")))
}
image_write(contact, file.path("qa", paste0(stem, "-contact-sheet.png")))
if (!standard.only) {
  image_write(encoded, "../Dragon-GPT/dragon/spritesheet.webp", format = "webp", depth = 8,
              defines = c("webp:lossless" = "true"))
  preview <- row.cells$idle[[1]]
  image_write(preview, "assets/preview.png")
  icon <- image_extent(image_resize(preview, "256x256"), "256x256", gravity = "center", color = "none")
  icons <- image_join(lapply(c(16, 24, 32, 48, 64, 128, 256), function(s) image_resize(icon, sprintf("%dx%d!", s, s))))
  image_write(icons, "assets/dragon.ico", format = "ico", depth = 8)
  file.copy("qa/final-contact-sheet.png", "../Dragon-GPT/dragon/contact-sheet.png", overwrite = TRUE)
  sequence <- c(rep(list(row.cells$idle[[1]]), 5), row.cells$jumping, rep(list(row.cells$idle[[1]]), 5))
  jump.preview <- lapply(sequence, function(cell) image_composite(image_blank(192, 208, color = "#28303b"), cell))
  image_write(image_animate(image_join(jump.preview), fps = 10, loop = 0), "../Dragon-GPT/dragon/previews/idle-jump-idle.gif")
  look <- c(list(preview), row.cells$`look-first`, row.cells$`look-second`)
  look.sheet <- image_blank(5 * 192, 4 * 236, color = "#28303b")
  labels <- c("Neutral", sprintf("%05.1f", seq(0, 337.5, 22.5)))
  for (i in seq_along(look)) {
    xx <- ((i - 1) %% 5) * 192
    yy <- ((i - 1) %/% 5) * 236
    look.sheet <- image_composite(look.sheet, look[[i]], offset = sprintf("+%d+%d", xx, yy + 24))
    look.sheet <- image_annotate(look.sheet, labels[[i]], size = 16, font = "Arial", color = "white",
                                 location = sprintf("+%d+%d", xx + 10, yy + 2))
  }
  image_write(look.sheet, "../Dragon-GPT/dragon/look-directions.png")
}
cat(sprintf("Assembled %d encoded frames (%s).\n", nrow(metrics), stem))
