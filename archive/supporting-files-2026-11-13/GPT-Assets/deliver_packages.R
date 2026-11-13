library(magick)
library(jsonlite)
library(zip)
library(digest)

build.dir <- "GPT-Assets/build/2026-11-13-original-art"
validation <- read_json(file.path(build.dir, "build-validation.json"))
hash_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}

stopifnot(hash_file("archive/momo-pet-v2.zip") ==
  "3dc9ac11f501944c509bb1c6bb1903a03c00b3f286c91ca13035e9ac5bc3e8ee")

for (pet in c("momo", "mimi")) {
  target.dir <- paste0(toupper(pet), "-GPT")
  package.dir <- file.path(target.dir, pet)
  zip.name <- paste0(pet, "-pet-v2.zip")
  stopifnot(validation[[pet]]$ok,
            validation[[pet]]$unchanged_source_cells == 74L,
            validation[[pet]]$edited_pose_cells == 0L,
            !dir.exists(package.dir), !file.exists(file.path(target.dir, zip.name)))
  dir.create(target.dir, showWarnings = FALSE)
  stopifnot(file.copy(file.path(build.dir, pet), target.dir, recursive = TRUE),
            file.copy(file.path(build.dir, zip.name), file.path(target.dir, zip.name)))
  for (file in list.files(file.path(build.dir, pet), recursive = TRUE)) {
    stopifnot(hash_file(file.path(build.dir, pet, file)) == hash_file(file.path(package.dir, file)))
  }
  stopifnot(hash_file(file.path(target.dir, zip.name)) == validation[[pet]]$zip_sha256)
  check.dir <- file.path("GPT-Assets/work/delivery-check", pet)
  dir.create(check.dir, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(file.path(target.dir, zip.name), exdir = check.dir)
  for (file in list.files(package.dir, recursive = TRUE)) {
    stopifnot(hash_file(file.path(check.dir, pet, file)) == hash_file(file.path(package.dir, file)))
  }
  writeLines(paste(validation[[pet]]$zip_sha256, zip.name),
             file.path(target.dir, "SHA256SUMS.txt"))
  cat(toupper(pet), ": copied package and verified every unpacked file.\n")
}

momo.idle <- image_read("MOMO-GPT/momo/previews/idle.gif")
mimi.idle <- image_read("MIMI-GPT/mimi/previews/idle.gif")
stopifnot(length(momo.idle) == 6L, length(mimi.idle) == 6L)
paired.frames <- lapply(1:6, function(i) image_append(c(momo.idle[i], mimi.idle[i])))
image_write(paired.frames[[1]], "GPT-Assets/final-preview.png")
image_write(image_animate(image_join(paired.frames), fps = 10, dispose = "previous"),
             "GPT-Assets/final-preview.gif")
still.strip <- image_append(image_join(paired.frames[c(1, 3, 4, 6)]))
image_write(still.strip, "GPT-Assets/final-idle-sequence.png")
cat("Original archive hash, both ZIPs, all files, and paired idle preview verified.\n")
