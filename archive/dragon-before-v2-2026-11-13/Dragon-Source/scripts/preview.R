library(magick)

atlas <- image_read("assets/spritesheet.png")
counts <- c(6, 8, 8, 4, 5, 8, 6, 6, 6)
labels <- c("Idle", "Walk", "Wave", "Jump", "Think", "Review")
rows <- c(0, 1, 3, 4, 7, 8)
frames <- lapply(0:23, function(tick) {
  panel <- image_blank(3 * 216, 2 * 246, color = "#28303b")
  for (i in seq_along(rows)) {
    row <- rows[[i]]
    column <- tick %% counts[[row + 1]]
    cell <- image_crop(atlas, sprintf("192x208+%d+%d", column * 192, row * 208), repage = TRUE)
    x <- ((i - 1) %% 3) * 216 + 12
    y <- ((i - 1) %/% 3) * 246
    panel <- image_annotate(panel, labels[[i]], size = 16, font = "Arial", color = "white",
                            location = sprintf("+%d+%d", x + 6, y + 6))
    panel <- image_composite(panel, cell, offset = sprintf("+%d+%d", x, y + 30))
  }
  panel
})
image_write(image_animate(image_join(frames), fps = 5, loop = 0), "../Dragon-preview.gif")
image_write(frames[[1]], "../Dragon-preview.png")
