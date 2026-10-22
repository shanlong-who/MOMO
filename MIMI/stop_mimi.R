mimi_entry_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(mimi_entry_file)) {
  mimi_file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(mimi_file_arg)) stop("Run or source this saved file from the MIMI download.")
  mimi_entry_file <- sub("^--file=", "", mimi_file_arg[[1L]])
}
mimi_app_dir <- dirname(normalizePath(mimi_entry_file, winslash = "/", mustWork = TRUE))
source(file.path(mimi_app_dir, "bootstrap.R"), local = TRUE)
mimi_stop()
