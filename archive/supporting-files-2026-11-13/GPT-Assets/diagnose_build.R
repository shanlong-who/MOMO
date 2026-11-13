library(magick)
library(png)

print(formals(image_composite))
source.image <- image_read("Releases/2.0.0/Source/assets/aligned/momo-atlas.png")
cell <- image_crop(source.image, "256x280+0+0", repage = TRUE)
cell <- image_resize(cell, "192x208", filter = "Lanczos")
cell <- image_extent(cell, "192x208", gravity = "center", color = "none")
rgba <- image_data(cell, channels = "rgba")
cat("cell alpha:", range(as.integer(rgba[4L, , ])), "\n")
invisible <- rgba[4L, , ] == as.raw(0)
for (channel in 1:3) {
  values <- rgba[channel, , ]
  values[invisible] <- as.raw(0)
  rgba[channel, , ] <- values
}
float <- aperm(array(as.integer(rgba) / 255, dim(rgba)), c(3, 2, 1))
cat("float alpha:", range(float[, , 4L]), "\n")
reloaded <- image_read(writePNG(float))
cat("reloaded alpha:", range(as.integer(image_data(reloaded, channels = "rgba")[4L, , ])), "\n")
atlas <- image_blank(1536, 2288, "none")
atlas <- image_composite(atlas, reloaded, operator = "over", offset = "+0+0")
cat("atlas alpha:", range(as.integer(image_data(atlas, channels = "rgba")[4L, , ])), "\n")
cat("blank pixel:", as.integer(image_data(atlas, channels = "rgba")[, 1500, 2000]), "\n")
image_write(image_background(reloaded, "white", flatten = TRUE), "GPT-Assets/work/diagnostic-cell.png")
saved <- image_read("GPT-Assets/build/2026-11-13-verified/momo/spritesheet.webp")
data <- image_data(saved, channels = "rgba")
print(image_info(saved))
cat("saved blank pixel:", as.integer(data[, 1500, 2000]), "\n")
for (pet in c("momo", "mimi")) {
  path <- paste0("GPT-Assets/artwork/", pet, if (pet == "momo") "-idle-front-closed.png" else "-idle-front.png")
  img <- image_read(path)
  print(image_info(img))
  img <- image_background(img, "#e4e9ef", flatten = TRUE)
  image_write(img, paste0("GPT-Assets/work/", pet, "-generated-flat.png"))
}
for (row in 0:10) {
  occupied <- vapply(0:7, function(column) {
    any(data[4L, column * 192L + seq_len(192L), row * 208L + seq_len(208L)] != as.raw(0))
  }, logical(1))
  cat(row, occupied, "\n")
}
for (position in list(c(0, 7), c(3, 4), c(4, 7), c(8, 7))) {
  alpha <- data[4L, position[2] * 192L + seq_len(192L), position[1] * 208L + seq_len(208L)]
  cat("Unused", position, "count", sum(alpha != as.raw(0)), "alpha range", range(as.integer(alpha)), "\n")
  print(head(which(alpha != as.raw(0), arr.ind = TRUE)))
}
image_write(image_resize(image_background(saved, "#e4e9ef", flatten = TRUE), "768x1144!"),
            "GPT-Assets/work/decoded-diagnostic.png")
