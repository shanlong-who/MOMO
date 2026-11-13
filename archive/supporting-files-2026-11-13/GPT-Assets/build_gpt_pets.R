library(magick)
library(png)
library(jsonlite)
library(zip)
library(digest)

# Repack the released Offline artwork without redrawing or changing any pose.
args <- commandArgs(trailingOnly = TRUE)
project.root <- normalizePath(".", winslash = "/")
output.root <- if (length(args)) args[[1]] else
  file.path("GPT-Assets/build", paste0("rebuild-", format(Sys.time(), "%Y%m%d-%H%M%S")))
stopifnot(!dir.exists(output.root))
dir.create(output.root, recursive = TRUE)
output.root <- normalizePath(output.root, winslash = "/")

source.dir <- file.path(project.root, "Releases/2.0.0/Source/assets/aligned")
original.dir <- file.path(project.root, "GPT-Assets/work/original/momo")
frame.counts <- c(7L, 8L, 8L, 4L, 5L, 8L, 6L, 6L, 6L, 8L, 8L)
states <- c("idle", "running-right", "running-left", "waving", "jumping",
            "failed", "waiting", "running", "review", "look-000-157.5",
            "look-180-337.5")
frame.map <- data.frame(
  row = rep(0:10, frame.counts),
  column = unlist(lapply(frame.counts, function(n) seq_len(n) - 1L)))
frame.map$state <- states[frame.map$row + 1L]

hash_file <- function(path) {
  # OneDrive can report file.access() == -1 for readable files on this host.
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}

original.manifest <- read_json(file.path(original.dir, "pet.json"))
original.image <- image_read(file.path(original.dir, "spritesheet.webp"))
original.rgba <- image_data(original.image, channels = "rgba")

is_occupied <- function(rgba, row, column) {
  xx <- column * 192L + seq_len(192L)
  yy <- row * 208L + seq_len(208L)
  any(rgba[4L, xx, yy] != as.raw(0))
}

original.mask <- matrix(FALSE, 11, 8)
for (row in 0:10) for (column in 0:7) {
  original.mask[row + 1L, column + 1L] <- is_occupied(original.rgba, row, column)
}
stopifnot(identical(as.integer(rowSums(original.mask)), frame.counts))

clear_hidden_rgb <- function(img) {
  rgba <- readPNG(image_write(img, format = "png"))
  invisible <- rgba[, , 4L] == 0
  for (channel in 1:3) {
    values <- rgba[, , channel]
    values[invisible] <- 0
    rgba[, , channel] <- values
  }
  image_read(writePNG(rgba))
}

make_preview_frame <- function(img, title) {
  canvas <- image_blank(288, 270, "#f1f3f7")
  canvas <- image_composite(canvas, img, operator = "over", offset = "+48+38")
  image_annotate(canvas, title, location = "+12+24", size = 17,
                 font = "Arial", color = "#26313d")
}

animate_frames <- function(frames, path, fps = 10) {
  animation <- image_animate(image_join(frames), fps = fps, dispose = "previous")
  image_write(animation, path, format = "gif")
}

reports <- list()
for (pet in c("momo", "mimi")) {
  cat("Building", pet, "\n")
  pet.dir <- file.path(output.root, pet)
  preview.dir <- file.path(pet.dir, "previews")
  dir.create(preview.dir, recursive = TRUE)
  source.path <- file.path(source.dir, paste0(pet, "-atlas.png"))
  source.image <- image_read(source.path)
  stopifnot(image_info(source.image)$width == 2048L,
            image_info(source.image)$height == 3080L)

  atlas <- image_blank(1536, 2288, "none")
  cells <- vector("list", nrow(frame.map))
  frame.stats <- vector("list", nrow(frame.map))
  for (i in seq_len(nrow(frame.map))) {
    frame <- frame.map[i, ]
    cell <- image_crop(source.image,
      sprintf("256x280+%d+%d", frame$column * 256, frame$row * 280), repage = TRUE)
    # One uniform 26/35 scale for every cell preserves poses and registration.
    cell <- image_resize(cell, "192x208", filter = "Lanczos")
    cell <- image_extent(cell, "192x208", gravity = "center", color = "none")
    cell <- clear_hidden_rgb(cell)
    cells[[i]] <- cell
    atlas <- image_composite(atlas, cell, operator = "over",
      offset = sprintf("+%d+%d", frame$column * 192, frame$row * 208))
  }
  atlas <- clear_hidden_rgb(atlas)
  sheet.path <- file.path(pet.dir, "spritesheet.webp")
  image_write(atlas, sheet.path, format = "webp", quality = 100,
              defines = c("webp:lossless" = "true", "webp:exact" = "true"))

  # Validate the exact decoded delivery bytes against every repacked source cell.
  decoded <- image_read(sheet.path)
  decoded.rgba <- image_data(decoded, channels = "rgba")
  info <- image_info(decoded)
  stopifnot(info$width == 1536L, info$height == 2288L,
            info$matte, file.info(sheet.path)$size < 20 * 1024^2)
  delivery.mask <- matrix(FALSE, 11, 8)
  for (row in 0:10) for (column in 0:7) {
    delivery.mask[row + 1L, column + 1L] <- is_occupied(decoded.rgba, row, column)
  }
  stopifnot(identical(delivery.mask, original.mask))
  for (i in seq_len(nrow(frame.map))) {
    frame <- frame.map[i, ]
    xx <- frame$column * 192L + seq_len(192L)
    yy <- frame$row * 208L + seq_len(208L)
    actual <- decoded.rgba[, xx, yy, drop = FALSE]
    expected <- image_data(cells[[i]], channels = "rgba")
    stopifnot(all(actual == expected))
    alpha <- matrix(as.integer(actual[4L, , ]), 192, 208)
    visible <- which(alpha > 32L, arr.ind = TRUE)
    padding <- c(min(visible[, 1]) - 1, 192 - max(visible[, 1]),
                 min(visible[, 2]) - 1, 208 - max(visible[, 2]))
    stopifnot(min(padding) >= 4L)
    frame.stats[[i]] <- data.frame(frame, visible.pixels = nrow(visible),
      left = padding[1], right = padding[2], top = padding[3], bottom = padding[4],
      exact.source.match = TRUE, exact.delivery.match = TRUE)
    # Every preview comes from the encoded delivery sheet.
    cells[[i]] <- image_crop(decoded,
      sprintf("192x208+%d+%d", frame$column * 192, frame$row * 208), repage = TRUE)
  }
  invisible <- decoded.rgba[4L, , ] == as.raw(0)
  stopifnot(all(vapply(1:3, function(channel) {
    all(decoded.rgba[channel, , ][invisible] == as.raw(0))
  }, logical(1))))

  manifest <- original.manifest
  manifest$id <- pet
  manifest$displayName <- if (pet == "momo") "Momo" else "Mimi"
  manifest$description <- if (pet == "momo") original.manifest$description else
    "A gentle silver tabby with soft fur and bright amber eyes, bringing calm company to every task."
  write_json(manifest, file.path(pet.dir, "pet.json"), auto_unbox = TRUE, pretty = TRUE)
  if (pet == "momo") stopifnot(identical(manifest, original.manifest))

  contact.rows <- list()
  for (row in 0:10) {
    strip <- image_blank(1536, 238, "#f1f3f7")
    strip <- image_annotate(strip,
      sprintf("%d  %s  (%d cells)", row, states[row + 1L], frame.counts[row + 1L]),
      location = "+8+22", size = 18, font = "Arial", color = "#26313d")
    indices <- which(frame.map$row == row)
    for (i in indices) strip <- image_composite(strip, cells[[i]], operator = "over",
      offset = sprintf("+%d+30", frame.map$column[i] * 192))
    contact.rows[[row + 1L]] <- strip
  }
  image_write(image_append(image_join(contact.rows), stack = TRUE),
               file.path(pet.dir, "contact-sheet.png"))
  image_write(cells[[1]], file.path(pet.dir, "preview.png"))

  all.frames <- list()
  for (row in 0:8) {
    indices <- which(frame.map$row == row)
    # Idle cell 6 is the original neutral pose, retained outside its six-frame loop.
    if (row == 0L) indices <- indices[1:6]
    preview.frames <- lapply(indices, function(i) {
      make_preview_frame(cells[[i]], paste(toupper(pet), states[row + 1L]))
    })
    animate_frames(preview.frames, file.path(preview.dir, paste0(states[row + 1L], ".gif")))
    all.frames <- c(all.frames, rep(preview.frames, 2L))
  }
  animate_frames(all.frames, file.path(preview.dir, "all-states.gif"))
  jump.indices <- c(which(frame.map$row == 0L)[1:6], which(frame.map$row == 4L),
                    which(frame.map$row == 0L)[1:6])
  animate_frames(lapply(jump.indices, function(i) {
    make_preview_frame(cells[[i]], paste(toupper(pet), "idle / jump / idle"))
  }), file.path(preview.dir, "idle-jump-idle.gif"))
  look.indices <- which(frame.map$row >= 9L)
  look.frames <- lapply(seq_along(look.indices), function(i) {
    make_preview_frame(cells[[look.indices[i]]],
      sprintf("%s look %05.1f", toupper(pet), (i - 1) * 22.5))
  })
  animate_frames(look.frames, file.path(preview.dir, "look-loop.gif"), fps = 5)
  look.panels <- c(list(make_preview_frame(cells[[7]], paste(toupper(pet), "neutral"))), look.frames)
  while (length(look.panels) %% 4L) look.panels <- c(look.panels, list(image_blank(288, 270, "#f1f3f7")))
  look.rows <- lapply(seq(1L, length(look.panels), by = 4L), function(i) {
    image_append(image_join(look.panels[i:(i + 3L)]))
  })
  image_write(image_append(image_join(look.rows), stack = TRUE),
              file.path(pet.dir, "look-directions.png"))

  report <- list(ok = TRUE, scope = "Local Codex v2 package; source-preservation checks",
    source = source.path, source_sha256 = hash_file(source.path),
    spritesheet_sha256 = hash_file(sheet.path),
    dimensions = c(width = 1536L, height = 2288L), cell = c(width = 192L, height = 208L),
    source_cell = c(width = 256L, height = 280L),
    resize = "190x208 with one transparent column on each side; same transform for all frames",
    frame_counts = frame.counts, standard_animation_frames = 57L,
    neutral_frames = 1L, look_frames = 16L, populated_cells = sum(delivery.mask),
    transparent_unused_cells = sum(!delivery.mask),
    original_occupancy_preserved = TRUE, all_74_cells_match_lossless_delivery = TRUE,
    hidden_transparent_rgb_zero = TRUE, unchanged_source_cells = 74L,
    edited_pose_cells = 0L, no_pose_redrawing = TRUE,
    final_artwork_decision = "Use the original released Offline artwork only; no head, face, expression or pose edits",
    original_manifest_preserved = pet == "momo",
    runtime_timing = "Controlled by Codex; unchanged by this artwork-only package",
    frames = do.call(rbind, frame.stats))
  write_json(report, file.path(pet.dir, "validation.json"), auto_unbox = TRUE, pretty = TRUE)
  write.csv(do.call(rbind, frame.stats), file.path(pet.dir, "frame-map.csv"), row.names = FALSE)
  writeLines(c(paste0("# ", manifest$displayName, " for Codex"), "",
    paste0("Artwork: the released ", toupper(pet), "-Offline 2.0.0 identity, without a collar."), "",
    "This is a local Codex pet package. Keep this folder together when installing it.",
    "The manifest uses spriteVersionNumber 2 and a transparent 1536 x 2288 WebP atlas.",
    "It retains the original nine animation rows, neutral cell, and sixteen look poses.",
    "All 74 cells are copied from the released Offline atlas with one shared transform.",
    "The original face, head angle, expression, pose and frame order are preserved.",
    "MOMO uses the existing collar-free artwork. MIMI uses its original released artwork.",
    "No regenerated or experimental idle artwork is included.", "",
    "The idle row contains six animation frames plus the original neutral frame in column 6.",
    "Animation selection, speed and interactions remain controlled by Codex.", "",
    "See validation.json for source hashes, lossless delivery checks and cell padding.",
    "See previews/ for nine state loops, all-states.gif, idle-jump-idle.gif and look-loop.gif.",
    "These checks verify source preservation and packaging; they are not a cloud upload test."),
    file.path(pet.dir, "README.md"))
  file.copy(file.path(project.root, paste0(toupper(pet), "-Offline"), "LICENSE"),
            file.path(pet.dir, "LICENSE"))

  zip.path <- file.path(output.root, paste0(pet, "-pet-v2.zip"))
  zip::zipr(zip.path, pet, root = output.root, include_directories = FALSE)
  zip.list <- zip::zip_list(zip.path)
  stopifnot(any(zip.list$filename == paste0(pet, "/pet.json")),
            any(zip.list$filename == paste0(pet, "/spritesheet.webp")),
            !any(grepl("\\\\", zip.list$filename)),
            all(zip.list$uncompressed_size > 0))
  report$zip_sha256 <- hash_file(zip.path)
  reports[[pet]] <- report
  cat(pet, ": all 74 original source cells preserved; delivery and ZIP checks passed.\n")
}
write_json(reports, file.path(output.root, "build-validation.json"),
           auto_unbox = TRUE, pretty = TRUE)
cat("Built packages in", normalizePath(output.root, winslash = "/"), "\n")
