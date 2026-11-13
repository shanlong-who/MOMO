library(magick)

source.dir <- "Releases/2.0.0/Source/assets/aligned"
for (pet in c("momo", "mimi")) {
  atlas <- image_read(file.path(source.dir, paste0(pet, "-atlas.png")))
  target <- image_blank(1024, 560, "none")
  for (column in 0:6) {
    cell <- image_crop(atlas, sprintf("256x280+%d+0", column * 256L), repage = TRUE)
    target <- image_composite(target, cell, operator = "over",
      offset = sprintf("+%d+%d", (column %% 4L) * 256L, (column %/% 4L) * 280L))
  }
  image_write(target, paste0("GPT-Assets/work/", pet, "-idle-edit-target.png"))
}
