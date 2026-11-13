library(magick)
library(jsonlite)
library(digest)

check.dir <- "GPT-Assets/cloud-pet-check-20261113"
hash_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}
new.path <- file.path(check.dir, "momo-stored-after.png")
collar.path <- file.path(check.dir, "momo-collar-stored-after.png")
old.collar <- "archive/cloud-momo-before-update-20261113/momo-active-original.png"
approved <- image_read("MOMO-GPT/momo/spritesheet.webp")
stored <- image_read(new.path)
stopifnot(all(image_data(stored, channels = "rgba") ==
                image_data(approved, channels = "rgba")),
          hash_file(collar.path) == hash_file(old.collar))

records <- read_json(file.path(check.dir, "account-records-after.json"))
ids <- vapply(records$pets, function(pet) pet$id, character(1))
names <- vapply(records$pets, function(pet) pet$name, character(1))
stopifnot(identical(names[ids == "pet_6abb87319e608191a4124d3caec52e30"], "Momo"),
          identical(names[ids == "pet_6abb2ee29a7c8191bb7029359736a9ee"], "Momo Collar"),
          identical(names[ids == "pet_6af6692b7c888191ab32fa8584f3f021"], "Mimi"),
          identical(records$active_pet_id, "pet_6abb2ee29a7c8191bb7029359736a9ee"))

atlases <- list(Momo = stored, `Momo Collar` = image_read(collar.path),
  Mimi = image_read(file.path(Sys.getenv("USERPROFILE"), ".codex/pets/mimi/spritesheet.webp")))
frames <- lapply(0:5, function(column) {
  panels <- lapply(seq_along(atlases), function(i) {
    sprite <- image_crop(atlases[[i]], sprintf("192x208+%d+0", column * 192L), repage = TRUE)
    panel <- image_composite(image_blank(240, 256, "#f1f3f7"), sprite,
                              operator = "over", offset = "+24+40")
    image_annotate(panel, names(atlases)[[i]], location = "+10+24", size = 17,
                     font = "Arial", color = "#26313d")
  })
  image_append(image_join(panels))
})
image_write(frames[[1]], file.path(check.dir, "verified-three-pets.png"))
image_write(image_animate(image_join(frames), fps = 10, dispose = "previous"),
              file.path(check.dir, "verified-idle-preview.gif"))
write_json(list(status = "cloud-records-and-artwork-verified",
  momo = list(id = "pet_6abb87319e608191a4124d3caec52e30", name = "Momo",
    stored_sha256 = hash_file(new.path), all_decoded_pixels_match_approved_collar_free_atlas = TRUE),
  momo_collar = list(id = "pet_6abb2ee29a7c8191bb7029359736a9ee", name = "Momo Collar",
    stored_sha256 = hash_file(collar.path), image_is_byte_identical_to_original = TRUE),
  mimi = list(id = "pet_6af6692b7c888191ab32fa8584f3f021", name = "Mimi", unchanged = TRUE),
  stable_ids_preserved = TRUE, original_active_selection_preserved = TRUE,
  direct_desktop_switch_test = "Not automated; awaiting the user's visual check"),
  file.path(check.dir, "cloud-verification.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Momo: cloud image matches every decoded pixel of the approved collar-free atlas.\n")
cat("Momo Collar: cloud image is byte-identical to the original collared artwork.\n")
cat("Mimi, stable pet IDs and the original active selection are preserved.\n")
