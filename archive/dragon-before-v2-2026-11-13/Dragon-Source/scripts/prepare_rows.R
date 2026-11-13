library(magick)
library(png)
library(processx)
library(jsonlite)

args <- commandArgs(trailingOnly = TRUE)
states <- if (length(args)) args else c("idle", "running-right", "running-left", "waving", "jumping",
                                      "failed", "waiting", "running", "review", "cardinals", "look-first", "look-second")
source("scripts/component_helpers.R")
toolchain.dir <- "D:/R/rtools45/x86_64-w64-mingw32.static.posix/bin"
Sys.setenv(PATH = paste(toolchain.dir, Sys.getenv("PATH"), sep = .Platform$path.sep))
helper.path <- normalizePath("assets", winslash = "/")
helper.path <- file.path(helper.path, "components.dll")
if (!file.exists(helper.path)) {
  r.bin <- R.home("bin")
  if (!file.exists(file.path(r.bin, "R.dll"))) r.bin <- file.path(r.bin, "x64")
  run(file.path(toolchain.dir, "g++.exe"), c("-O2", "-shared", "-static-libgcc", "-static-libstdc++",
      paste0("-I", R.home("include")), "scripts/components_native.cpp", paste0("-L", r.bin), "-lR",
      "-o", helper.path), windows_hide_window = TRUE)
}
dyn.load(helper.path)
counts <- c(idle = 6, `running-right` = 8, `running-left` = 8, waving = 4, jumping = 5,
            failed = 8, waiting = 6, running = 6, review = 6, cardinals = 4,
            `look-first` = 8, `look-second` = 8)
for (state in states) {
  path <- file.path("artwork/rows", paste0(state, ".png"))
  if (!file.exists(path)) next
  rgba <- readPNG(path)
  stopifnot(length(dim(rgba)) == 3L)
  if (dim(rgba)[3] == 3L) {
    rgb <- rgba
    rgba <- array(1, dim = c(dim(rgb)[1:2], 4L))
    rgba[, , 1:3] <- rgb
  }
  # Generated green staging is removed in RGB space, including its soft edge.
  green <- rgba[, , 2] - pmax(rgba[, , 1], rgba[, , 3])
  keyed <- green > 0.08 & rgba[, , 2] > 0.3
  rgba[, , 4][keyed] <- rgba[, , 4][keyed] * pmax(0, 1 - green[keyed] / 0.32)
  rgba[, , 4][green > 0.32] <- 0
  edge <- keyed & rgba[, , 4] > 0
  rgba[, , 2][edge] <- pmin(rgba[, , 2][edge], pmax(rgba[, , 1][edge], rgba[, , 3][edge]))
  labelled <- label_components(rgba[, , 4], 0.1)
  objects <- labelled$components
  # Find complete connected figures; small alpha residue is excluded, never redrawn.
  objects <- objects[objects$area > 1200, ]
  if (nrow(objects) != counts[[state]]) {
    write.csv(objects, file.path("qa", paste0(state, "-components.csv")), row.names = FALSE)
    stop(sprintf("%s: expected %s connected figures, found %s", state, counts[[state]], nrow(objects)))
  }
  lanes <- if (state %in% c("waving", "jumping", "cardinals")) 1 else 2
  objects$lane <- pmin(lanes, floor(objects$cy / (dim(rgba)[1] / lanes)) + 1L)
  objects <- objects[order(objects$lane, objects$cx), ]
  objects$frame <- seq_len(nrow(objects))
  output.dir <- file.path("qa/rows", state)
  dir.create(output.dir, recursive = TRUE, showWarnings = FALSE)
  figures <- vector("list", nrow(objects))
  for (i in seq_len(nrow(objects))) {
    object <- objects[i, ]
    xx <- seq.int(max(0, object$xmin - 3), min(dim(rgba)[2] - 1, object$xmax + 3)) + 1L
    yy <- seq.int(max(0, object$ymin - 3), min(dim(rgba)[1] - 1, object$ymax + 3)) + 1L
    crop <- rgba[yy, xx, , drop = FALSE]
    core <- labelled$labels[yy, xx, drop = FALSE] == object$id
    allowed <- matrix(FALSE, nrow(core), ncol(core))
    for (dx in -2:2) for (dy in -2:2) {
      target.x <- seq.int(max(1, 1 + dx), min(ncol(core), ncol(core) + dx))
      target.y <- seq.int(max(1, 1 + dy), min(nrow(core), nrow(core) + dy))
      allowed[target.y, target.x] <- allowed[target.y, target.x] | core[target.y - dy, target.x - dx]
    }
    crop[, , 4][!allowed | crop[, , 4] < 3 / 255] <- 0
    for (channel in 1:3) crop[, , channel][crop[, , 4] == 0] <- 0
    file <- file.path(output.dir, sprintf("frame-%02d.png", i))
    writePNG(crop, file)
    figures[[i]] <- list(path = file, width = length(xx), height = length(yy),
                         source.bottom = object$ymax, lane = object$lane)
  }
  objects$height <- objects$ymax - objects$ymin + 1
  objects$width <- objects$xmax - objects$xmin + 1
  stopifnot(max(objects$height) / min(objects$height) < if (state == "jumping") 1.35 else 1.22)
  write.csv(objects, file.path(output.dir, "source-bounds.csv"), row.names = FALSE)
  saveRDS(figures, file.path(output.dir, "figures.rds"))
  write_json(list(state = state, expected.frames = counts[[state]], connected.figures = nrow(objects),
                  method = "connected component extraction with two-pixel edge retention",
                  source = path, source.width = dim(rgba)[2], source.height = dim(rgba)[1],
                  min.height = min(objects$height), max.height = max(objects$height)),
             file.path(output.dir, "extraction.json"), auto_unbox = TRUE, pretty = TRUE)
  cat(sprintf("%s: extracted %d complete figures; height range %d-%d.\n", state, nrow(objects),
              min(objects$height), max(objects$height)))
}
