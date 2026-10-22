# Check the source tree before publishing. No report is written into the tree.
source_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(source_file)) source_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
app_dir <- dirname(dirname(normalizePath(source_file, winslash = "/", mustWork = TRUE)))
relative_files <- list.files(app_dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
relative_files <- relative_files[!grepl("^\\.git(/|$)", relative_files)]
stopifnot(!any(grepl("(^|/)(state|verification|logs|diagnostics)/|\\.(lnk|log|rds|request|lock)$", relative_files, ignore.case = TRUE)))
stopifnot(!any(grepl("(^|/)\\.(Rhistory|RData|Ruserdata|Rproj\\.user)(/|$)", relative_files, ignore.case = TRUE)))
text_files <- relative_files[grepl("\\.(R|cmd|md)$|(^|/)(LICENSE|\\.gitignore|\\.gitattributes)$", relative_files)]
for (relative_file in text_files) {
  lines <- readLines(file.path(app_dir, relative_file), warn = FALSE, encoding = "UTF-8")
  if (any(grepl("[A-Za-z]:[/\\\\](Users|Documents and Settings)[/\\\\]", lines, ignore.case = TRUE))) {
    stop("A personal Windows path was found in: ", relative_file)
  }
}
stopifnot(all(file.exists(file.path(app_dir, c("README.md", "LICENSE", "bootstrap.R", "run_momo.R", "momo.R",
                                            "Start MOMO.cmd", "Exit MOMO.cmd", "scripts/launch.R", "scripts/launch.cmd")))))
stopifnot(all(file.exists(file.path(app_dir, "assets", paste0("momo-", c(144L, 192L, 240L, 288L), ".png")))))
cat("PASS: no personal Windows paths, shortcuts, runtime state or logs in the public source tree.\n")
cat("PASS: required source, artwork, launchers, English README and license are present.\n")
