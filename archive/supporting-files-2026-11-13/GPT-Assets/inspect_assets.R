library(magick)
library(png)
library(jsonlite)

dir.create("GPT-Assets/work/original", recursive = TRUE, showWarnings = FALSE)
unzip("archive/momo-pet-v2.zip", exdir = "GPT-Assets/work/original")

source.dir <- "Releases/2.0.0/Source/assets/aligned"
for (pet in c("momo", "mimi")) {
  atlas <- image_read(file.path(source.dir, paste0(pet, "-atlas.png")))
  print(image_info(atlas))
  preview <- image_resize(atlas, "1024x1540!")
  preview <- image_background(preview, "#eef0f4", flatten = TRUE)
  image_write(preview, paste0("GPT-Assets/work/", pet, "-source-sheet.png"))
}

original.path <- "GPT-Assets/work/original/momo/spritesheet.webp"
print(image_info(image_read(original.path)))
original <- image_data(image_read(original.path), channels = "rgba")
frame.counts <- vapply(0:10, function(row) {
  sum(vapply(0:7, function(column) {
    yy <- row * 208L + seq_len(208L)
    xx <- column * 192L + seq_len(192L)
    any(original[4L, xx, yy] != as.raw(0))
  }, logical(1)))
}, integer(1))
cat("Original frame counts:", paste(frame.counts, collapse = ", "), "\n")
write_json(list(frame_counts = frame.counts),
           "GPT-Assets/work/original-layout.json", auto_unbox = TRUE, pretty = TRUE)
