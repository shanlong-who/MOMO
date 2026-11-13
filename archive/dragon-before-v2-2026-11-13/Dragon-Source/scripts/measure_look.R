library(png)
library(magick)
library(jsonlite)

atlas <- readPNG("assets/spritesheet.png")
im <- image_read("assets/spritesheet.png")
look.cells <- lapply(0:15, function(i) {
  yy <- (9 + i %/% 8) * 208 + seq_len(208)
  xx <- (i %% 8) * 192 + seq_len(192)
  atlas[yy, xx, , drop = FALSE]
})
registration <- lapply(seq_along(look.cells), function(i) {
  alpha <- look.cells[[i]][, , 4]
  lower <- alpha[111:198, ]
  occupied <- which(alpha > 0.125, arr.ind = TRUE)
  data.frame(direction = (i - 1) * 22.5, lower.body.x = sum(colSums(lower) * seq_len(192)) / sum(lower),
             bottom = max(occupied[, 1]), top = min(occupied[, 1]), occupied.pixels = nrow(occupied))
})
registration <- do.call(rbind, registration)
write.csv(registration, "qa/look-registration.csv", row.names = FALSE)
adjacent <- vapply(seq_len(16), function(i) mean(abs(look.cells[[i]] - look.cells[[i %% 16 + 1]])), numeric(1))
report <- list(scope = "Descriptive encoded-pixel continuity and body-registration measurements",
  lower.body.x.range.pixels = diff(range(registration$lower.body.x)),
  baseline.range.pixels = diff(range(registration$bottom)),
  adjacent.mean.absolute.rgba.difference = adjacent,
  boundary.157.5.to.180 = adjacent[[8]], boundary.337.5.to.000 = adjacent[[16]])
write_json(report, "qa/look-continuity.json", pretty = TRUE, auto_unbox = TRUE)
blind.order <- c(12, 0, 8, 4)
sheet <- image_blank(768, 236, color = "#28303b")
for (i in seq_along(blind.order)) {
  k <- blind.order[[i]]
  cell <- image_crop(im, sprintf("192x208+%d+%d", (k %% 8) * 192, (9 + k %/% 8) * 208), repage = TRUE)
  sheet <- image_composite(sheet, cell, offset = sprintf("+%d+24", (i - 1) * 192))
  sheet <- image_annotate(sheet, LETTERS[[i]], size = 16, font = "Arial", color = "white",
                          location = sprintf("+%d+2", (i - 1) * 192 + 10))
}
image_write(sheet, "qa/blind-cardinals.png")
print(registration)
print(report[2:3])
