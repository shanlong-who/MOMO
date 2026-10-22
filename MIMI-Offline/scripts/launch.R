# The Windows launcher finds R; helpers use that same installation.
mimi_file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (!length(mimi_file_arg)) stop("Run this helper with Rscript.")
mimi_launcher_file <- normalizePath(sub("^--file=", "", mimi_file_arg[[1L]]), winslash = "/", mustWork = TRUE)
mimi_app_dir <- dirname(dirname(mimi_launcher_file))
source(file.path(mimi_app_dir, "bootstrap.R"), local = TRUE)
mimi_args <- commandArgs(trailingOnly = TRUE)
mimi_action <- if (length(mimi_args)) mimi_args[[1L]] else "check"
if (!mimi_action %in% c("paths", "await", "stop", "check")) stop("Unknown MIMI action.")

tryCatch({
  if (mimi_action == "stop") {
    if (mimi_stop()) cat("MIMI has been asked to close.\n") else cat("MIMI is not running.\n")
  } else {
    mimi_check_requirements(mimi_app_dir)
    mimi_paths <- mimi_runtime_paths()
    if (mimi_action == "check") {
      cat("Ready:", R.version.string, "\n")
      cat("Rscript:", file.path(R.home("bin"), "Rscript.exe"), "\n")
      cat("Runtime packages: tcltk and ps are available.\n")
    } else if (mimi_action == "paths") {
      mimi_ensure_directory(mimi_paths$data)
      mimi_ensure_directory(mimi_paths$logs)
      mimi_error_file <- file.path(mimi_paths$reports, "last-error.txt")
      if (file.exists(mimi_error_file)) unlink(mimi_error_file, recursive = FALSE)
      writeLines(c(mimi_paths$data, mimi_paths$logs, mimi_paths$reports))
    } else {
      mimi_deadline <- Sys.time() + 12
      mimi_ready <- FALSE
      while (Sys.time() < mimi_deadline) {
        mimi_error_file <- file.path(mimi_paths$reports, "last-error.txt")
        if (file.exists(mimi_error_file)) stop(paste(readLines(mimi_error_file, warn = FALSE), collapse = "\n"))
        mimi_owner_path <- file.path(mimi_paths$data, "instance.rds")
        mimi_ready_path <- file.path(mimi_paths$data, "ready.rds")
        mimi_owner <- if (file.exists(mimi_owner_path)) tryCatch(readRDS(mimi_owner_path), error = function(e) NULL) else NULL
        mimi_ready_record <- if (file.exists(mimi_ready_path)) tryCatch(readRDS(mimi_ready_path), error = function(e) NULL) else NULL
        if (is.list(mimi_owner) && length(mimi_owner$pid) == 1L && length(mimi_owner$created) == 1L &&
            identical(mimi_owner, mimi_ready_record)) {
          mimi_ready <- tryCatch({
            mimi_handle <- ps::ps_handle(mimi_owner$pid)
            ps::ps_is_running(mimi_handle) && abs(ps::ps_create_time(mimi_handle) - mimi_owner$created) < 0.01
          }, error = function(e) FALSE)
        }
        if (mimi_ready) break
        Sys.sleep(0.15)
      }
      if (!mimi_ready) stop("MIMI did not become ready. Check local logs in: ", mimi_paths$logs)
      cat("MIMI is running. Right-click the cat for controls.\n")
    }
  }
}, error = function(error) {
  message("MIMI: ", conditionMessage(error))
  quit(save = "no", status = 1L)
})
