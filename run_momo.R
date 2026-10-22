# Run with Rscript, or source this file in RStudio.
momo_entry_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(momo_entry_file)) {
  momo_file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(momo_file_arg)) stop("Run or source this saved file from the MOMO download.")
  momo_entry_file <- sub("^--file=", "", momo_file_arg[[1L]])
}
momo_app_dir <- dirname(normalizePath(momo_entry_file, winslash = "/", mustWork = TRUE))
source(file.path(momo_app_dir, "bootstrap.R"), local = TRUE)
momo_check_requirements(momo_app_dir)
source(file.path(momo_app_dir, "momo.R"), local = TRUE)
momo_cli_args <- if (sys.nframe() == 0L) commandArgs(trailingOnly = TRUE) else character()
tryCatch(momo_main(momo_app_dir, momo_cli_args), error = function(error) {
  momo_reports <- momo_runtime_paths()$reports
  momo_ensure_directory(momo_reports)
  writeLines(conditionMessage(error), file.path(momo_reports, "last-error.txt"))
  message("MOMO could not start: ", conditionMessage(error))
  if (interactive()) {
    try(tcltk::tkmessageBox(title = "MOMO", icon = "error", type = "ok",
                           message = paste("MOMO could not start.", conditionMessage(error), sep = "\n\n")), silent = TRUE)
  }
  stop(conditionMessage(error), call. = FALSE)
})
