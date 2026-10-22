# Run with Rscript, or source this file in RStudio.
mimi_entry_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(mimi_entry_file)) {
  mimi_file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(mimi_file_arg)) stop("Run or source this saved file from the MIMI download.")
  mimi_entry_file <- sub("^--file=", "", mimi_file_arg[[1L]])
}
mimi_app_dir <- dirname(normalizePath(mimi_entry_file, winslash = "/", mustWork = TRUE))
source(file.path(mimi_app_dir, "bootstrap.R"), local = TRUE)
mimi_check_requirements(mimi_app_dir)
source(file.path(mimi_app_dir, "mimi.R"), local = TRUE)
mimi_cli_args <- if (sys.nframe() == 0L) commandArgs(trailingOnly = TRUE) else character()
tryCatch(mimi_main(mimi_app_dir, mimi_cli_args), error = function(error) {
  mimi_reports <- mimi_runtime_paths()$reports
  mimi_ensure_directory(mimi_reports)
  writeLines(conditionMessage(error), file.path(mimi_reports, "last-error.txt"))
  message("MIMI could not start: ", conditionMessage(error))
  if (interactive()) {
    try(tcltk::tkmessageBox(title = "MIMI", icon = "error", type = "ok",
                           message = paste("MIMI could not start.", conditionMessage(error), sep = "\n\n")), silent = TRUE)
  }
  stop(conditionMessage(error), call. = FALSE)
})
