momo_entry_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(momo_entry_file)) {
  momo_file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(momo_file_arg)) stop("Run or source this saved file from the MOMO download.")
  momo_entry_file <- sub("^--file=", "", momo_file_arg[[1L]])
}
momo_app_dir <- dirname(normalizePath(momo_entry_file, winslash = "/", mustWork = TRUE))
source(file.path(momo_app_dir, "bootstrap.R"), local = TRUE)
momo_stop()
