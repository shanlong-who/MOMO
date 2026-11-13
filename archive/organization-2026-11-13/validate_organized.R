library(jsonlite)
library(digest)
library(zip)

project.root <- normalizePath(".", winslash = "/")
allowed <- c("Releases", "archive", "Dragon-GPT", "Dragon-Offline", "MOMO-GPT",
             "MOMO-Offline", "MIMI-GPT", "MIMI-Offline")
top <- list.files(project.root, all.files = TRUE, no.. = TRUE, full.names = TRUE)
stopifnot(length(top) == 8L, all(dir.exists(top)), setequal(basename(top), allowed))

hash_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection))
  digest(readBin(connection, "raw", n = file.info(path)$size),
         algo = "sha256", serialize = FALSE)
}

checksum.files <- c("Releases/2.0.0/SHA256SUMS.txt", "MOMO-Offline/SHA256SUMS.txt",
  "MIMI-Offline/SHA256SUMS.txt", "Dragon-Offline/SHA256SUMS.txt",
  "MOMO-GPT/SHA256SUMS.txt", "MIMI-GPT/SHA256SUMS.txt")
checks <- list()
for (checksum.file in checksum.files) {
  for (line in readLines(checksum.file, warn = FALSE)) {
    if (!nzchar(trimws(line))) next
    expected <- sub("\\s+.*$", "", line)
    filename <- sub("^[^[:space:]]+[[:space:]]+", "", line)
    path <- file.path(dirname(checksum.file), filename)
    actual <- hash_file(path)
    stopifnot(tolower(expected) == actual)
    checks[[length(checks) + 1L]] <- list(path = path, sha256 = actual)
  }
}

for (folder in c("Dragon-GPT", "MOMO-GPT", "MIMI-GPT")) {
  pet <- tolower(sub("-GPT$", "", folder))
  path <- file.path(folder, pet, "pet.json")
  manifest <- read_json(path)
  stopifnot(manifest$id == pet, manifest$spriteVersionNumber == 2L,
            file.exists(file.path(dirname(path), manifest$spritesheetPath)))
  archive <- file.path(folder, paste0(pet, "-pet-v2.zip"))
  contents <- zip_list(archive)
  stopifnot(all(c(paste0(pet, "/pet.json"), paste0(pet, "/spritesheet.webp")) %in%
                  contents$filename))
}

readmes <- file.path(allowed, "README.md")
links <- list()
for (readme in readmes) {
  text <- paste(readLines(readme, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  matches <- regmatches(text, gregexpr("\\]\\(([^)]+)\\)", text, perl = TRUE))[[1]]
  if (!length(matches)) next
  for (match in matches) {
    target <- sub("^\\]\\((.*)\\)$", "\\1", match)
    target <- sub("^<", "", sub(">$", "", target))
    if (grepl("^(https?://|#|mailto:)", target)) next
    target <- URLdecode(sub("#.*$", "", target))
    resolved <- file.path(dirname(readme), target)
    stopifnot(file.exists(resolved) || dir.exists(resolved))
    links[[length(links) + 1L]] <- list(readme = readme, target = target)
  }
}

r.files <- list.files(project.root, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
for (path in r.files) invisible(parse(file = path, encoding = "UTF-8"))
files <- list.files(project.root, recursive = TRUE, all.files = TRUE, no.. = TRUE, full.names = TRUE)
stopifnot(all(file.info(files)$size < 100 * 1024^2))
result <- list(ok = TRUE, top_level_folders = allowed, checksum_checks = checks,
  gpt_manifests_and_archives = "passed for all three packages",
  active_readme_links = links, parsed_r_scripts = length(r.files),
  every_file_below_100_mib = TRUE)
write_json(result, "archive/organization-2026-11-13/validation-result.json",
           auto_unbox = TRUE, pretty = TRUE)
cat("PASS: exactly eight root folders; published ZIP/EXE checksums; three GPT packages;\n")
cat("active README links;", length(r.files), "R scripts parse; all files below 100 MiB.\n")
