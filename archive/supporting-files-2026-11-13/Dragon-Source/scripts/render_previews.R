library(magick)
library(jsonlite)

atlas <- image_read("assets/spritesheet.png")
states <- c("Idle", "Glide right", "Glide left", "Hello", "Celebrate", "Concern and recovery", "Waiting", "Thinking", "Review")
counts <- c(6, 8, 8, 4, 5, 8, 6, 6, 6)
delays <- list(c(160, 50, 12, 12, 35, 90), rep(22, 8), rep(22, 8), c(30, 55, 40, 60),
              c(30, 30, 45, 35, 50), c(25, 35, 35, 45, 45, 45, 40, 50),
              c(50, 65, 40, 50, 55, 60), c(45, 65, 45, 60, 60, 50), c(40, 50, 50, 50, 45, 45))
cell_at <- function(row, column) {
  image_crop(atlas, sprintf("192x208+%d+%d", column * 192, row * 208), repage = TRUE)
}
frames <- list()
durations <- numeric()
stills <- c("Idle", "Glide right", "Hello", "Celebrate")
still.frame <- c(0, 2, 2, 2)
still.panels <- list()
video.dir <- "qa/video-frames"
dir.create(video.dir, recursive = TRUE, showWarnings = FALSE)
for (row in 0:8) {
  elapsed <- 0
  for (column in 0:(counts[[row + 1]] - 1L)) {
    cell <- cell_at(row, column)
    panel <- image_blank(320, 256, color = "#28303b")
    panel <- image_annotate(panel, sprintf("%s | %.2fs", states[[row + 1]], elapsed / 100),
      size = 16, font = "Arial", color = "white", location = "+12+6")
    panel <- image_composite(panel, cell, offset = "+64+36")
    frames[[length(frames) + 1L]] <- panel
    durations <- c(durations, delays[[row + 1]][[column + 1]])
    if (states[[row + 1]] %in% stills && column == still.frame[match(states[[row + 1]], stills)]) {
      still.panels[[length(still.panels) + 1L]] <- panel
    }
    image_write(panel, file.path(video.dir, sprintf("frame-%03d.png", length(frames))))
    elapsed <- elapsed + delays[[row + 1]][[column + 1]]
  }
}
preview.dir <- "../Dragon-GPT/dragon/previews"
image_write(image_animate(image_join(frames), delay = durations, loop = 0), file.path(preview.dir, "all-states.gif"))
stills.board <- image_append(image_join(still.panels))
image_write(stills.board, file.path(preview.dir, "motion-stills.png"))
write_json(list(scope = "Previews use intended Offline cadence; the desktop host controls its own playback",
                states = states, frame.delays.centiseconds = delays),
           "qa/preview-timing.json", pretty = TRUE, auto_unbox = TRUE)

# Encode the same labeled keyframes at 10 fps; only the preview needs this optional build package.
library.dir <- normalizePath("qa/build-library", winslash = "/", mustWork = FALSE)
if (requireNamespace("av", quietly = TRUE) || requireNamespace("av", lib.loc = library.dir, quietly = TRUE)) {
  library(av, lib.loc = if (requireNamespace("av", quietly = TRUE)) NULL else library.dir)
  files <- normalizePath(list.files(video.dir, pattern = "png$", full.names = TRUE), winslash = "/")
  video.frames <- rep(files, pmax(1, round(durations / 10)))
  av_encode_video(video.frames, file.path(preview.dir, "all-states.mp4"), framerate = 10, verbose = FALSE)
}

# A synchronized native-size montage shows each gesture once, then holds its calm last pose.
selected.rows <- c(0, 1, 3, 4, 7, 8)
montage <- lapply(0:79, function(tick) {
  elapsed <- (tick * 10) %% 400
  panel <- image_blank(648, 492, color = "#28303b")
  for (i in seq_along(selected.rows)) {
    row <- selected.rows[[i]]
    total <- sum(delays[[row + 1]])
    moment <- if (row %in% c(0, 1, 2)) elapsed %% total else min(elapsed, total - 1)
    column <- which(cumsum(delays[[row + 1]]) > moment)[[1]] - 1L
    x <- ((i - 1) %% 3) * 216 + 12
    y <- ((i - 1) %/% 3) * 246
    panel <- image_annotate(panel, states[[row + 1]], size = 16, font = "Arial", color = "white",
      location = sprintf("+%d+%d", x + 6, y + 6))
    panel <- image_composite(panel, cell_at(row, column), offset = sprintf("+%d+%d", x, y + 30))
  }
  panel
})
image_write(image_animate(image_join(montage), delay = 10, loop = 0), "../Dragon-preview.gif")
image_write(montage[[1]], "../Dragon-preview.png")
cat("Rendered state loops, all-state timeline, four labeled stills, look loop and native-size montage.\n")
