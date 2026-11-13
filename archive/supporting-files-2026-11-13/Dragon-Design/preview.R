library(magick)

concept <- image_read("Dragon-Design/simplified-character-concept.png")
current <- image_read("Dragon-Source/assets/preview.png")
proposed <- image_crop(concept, "528x1024+0+0", repage = TRUE)
proposed <- image_resize(proposed, "x180")
proposed.info <- image_info(proposed)
board <- image_blank(384, 238, color = "#e6e1e1")
board <- image_annotate(board, "Current", size = 14, font = "Arial", color = "#40364e", location = "+64+4")
board <- image_annotate(board, "Proposed", size = 14, font = "Arial", color = "#40364e", location = "+248+4")
board <- image_composite(board, current, offset = "+0+28")
board <- image_composite(board, proposed,
  offset = sprintf("+%d+%d", 192 + floor((192 - proposed.info$width) / 2), 28 + 198 - proposed.info$height))
image_write(board, "Dragon-Design/native-size-comparison.png")
