# Validate the public repository after a layout change. Writes no source-tree files.
source_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(source_file)) source_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
repo_dir <- dirname(dirname(dirname(normalizePath(source_file, winslash = "/", mustWork = TRUE))))
root_entries <- setdiff(list.files(repo_dir, all.files = TRUE, no.. = TRUE), ".git")
expected_entries <- c(".gitattributes", ".gitignore", ".github", "LICENSE", "README.md",
                      "MOMO-ChatGPT", "MOMO-Offline", "MIMI-Offline", "portable")
stopifnot(setequal(root_entries, expected_entries))
relative_files <- list.files(repo_dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
relative_files <- relative_files[!grepl("^\\.git(/|$)", relative_files)]
forbidden <- "(^|/)(maintenance|state|verification|logs|diagnostics|\\.Rproj\\.user)/|\\.(lnk|bundle|log|rds|request|lock)$|(^|/)\\.(Rhistory|RData|Ruserdata|Renviron|Rprofile|env)(\\.|/|$)"
stopifnot(!any(grepl(forbidden, relative_files, ignore.case = TRUE)))
archives <- relative_files[grepl("\\.(zip|tar|gz|7z)$", relative_files, ignore.case = TRUE)]
stopifnot(identical(archives, "MOMO-ChatGPT/momo-pet-v2.zip"))

check_text <- function(text, label) {
  normalized <- gsub(intToUtf8(92L), "/", text, fixed = TRUE)
  normalized <- gsub("/+", "/", normalized)
  if (any(grepl("[A-Za-z]:/(Users|Documents and Settings)/", normalized, ignore.case = TRUE))) {
    stop("A personal Windows path was found in: ", label)
  }
}
text_files <- relative_files[grepl("\\.(R|cmd|md|txt|json)$|(^|/)(LICENSE|\\.gitignore|\\.gitattributes)$", relative_files)]
for (relative_file in text_files) {
  check_text(readLines(file.path(repo_dir, relative_file), warn = FALSE, encoding = "UTF-8"), relative_file)
}
r_files <- relative_files[grepl("\\.R$", relative_files)]
invisible(lapply(file.path(repo_dir, r_files), parse))

for (relative_file in relative_files[grepl("\\.md$", relative_files)]) {
  text <- paste(readLines(file.path(repo_dir, relative_file), warn = FALSE), collapse = "\n")
  markdown_links <- regmatches(text, gregexpr("\\]\\([^\\)]+\\)", text, perl = TRUE))[[1L]]
  markdown_targets <- sub("^\\]\\((.*)\\)$", "\\1", markdown_links)
  images <- regmatches(text, gregexpr('src="[^"]+"', text, perl = TRUE))[[1L]]
  image_targets <- sub('^src="(.*)"$', "\\1", images)
  targets <- c(markdown_targets, image_targets)
  targets <- targets[!grepl("^(https?://|#)", targets)]
  targets <- sub("#.*$", "", targets)
  if (length(targets) && any(!file.exists(file.path(dirname(file.path(repo_dir, relative_file)), targets)))) {
    stop("A local documentation link is missing in: ", relative_file)
  }
}

package_path <- file.path(repo_dir, "MOMO-ChatGPT", "momo-pet-v2.zip")
package_entries <- unzip(package_path, list = TRUE)
required_members <- paste0("momo/", c("pet.json", "spritesheet.webp", "README.md", "LICENSE"))
stopifnot(setequal(package_entries$Name, required_members), nrow(package_entries) == 4L)
read_member <- function(member, binary = FALSE) {
  connection <- unz(package_path, member, open = "rb")
  on.exit(close(connection), add = TRUE)
  if (binary) {
    size <- package_entries$Length[match(member, package_entries$Name)]
    return(readBin(connection, "raw", n = size))
  }
  readLines(connection, warn = FALSE, encoding = "UTF-8")
}
for (member in setdiff(required_members, "momo/spritesheet.webp")) {
  check_text(read_member(member), paste("chat-app package:", member))
}
manifest <- paste(read_member("momo/pet.json"), collapse = "\n")
stopifnot(grepl('"spriteVersionNumber"[[:space:]]*:[[:space:]]*2', manifest),
          grepl('"spritesheetPath"[[:space:]]*:[[:space:]]*"spritesheet.webp"', manifest))
sprite <- read_member("momo/spritesheet.webp", binary = TRUE)
stopifnot(length(sprite) > 1000L, identical(rawToChar(sprite[1:4]), "RIFF"),
          identical(rawToChar(sprite[9:12]), "WEBP"))
stopifnot(!length(grepRaw("[A-Za-z]:[/\\\\]+Users[/\\\\]", sprite, ignore.case = TRUE, all = TRUE)))
cat("PASS: three public product folders, portable build tooling and valid documentation links.\n")
cat("PASS: no personal paths, local shortcuts, runtime logs or recovery archives.\n")
cat("PASS: sanitized chat-app package contains its v2 manifest, WebP artwork, guide and license.\n")
