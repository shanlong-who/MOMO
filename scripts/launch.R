# The Windows launcher finds R; helpers use that same installation.
momo_file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (!length(momo_file_arg)) stop("Run this helper with Rscript.")
momo_launcher_file <- normalizePath(sub("^--file=", "", momo_file_arg[[1L]]), winslash = "/", mustWork = TRUE)
momo_app_dir <- dirname(dirname(momo_launcher_file))
source(file.path(momo_app_dir, "bootstrap.R"), local = TRUE)
momo_args <- commandArgs(trailingOnly = TRUE)
momo_action <- if (length(momo_args)) momo_args[[1L]] else "check"
if (!momo_action %in% c("paths", "await", "stop", "check")) stop("Unknown MOMO action.")

tryCatch({
  if (momo_action == "stop") {
    if (momo_stop()) cat("MOMO has been asked to close.\n") else cat("MOMO is not running.\n")
  } else {
    momo_check_requirements(momo_app_dir)
    momo_paths <- momo_runtime_paths()
    if (momo_action == "check") {
      cat("Ready:", R.version.string, "\n")
      cat("Rscript:", file.path(R.home("bin"), "Rscript.exe"), "\n")
      cat("Runtime packages: tcltk and ps are available.\n")
    } else if (momo_action == "paths") {
      momo_ensure_directory(momo_paths$data)
      momo_ensure_directory(momo_paths$logs)
      momo_error_file <- file.path(momo_paths$reports, "last-error.txt")
      if (file.exists(momo_error_file)) unlink(momo_error_file, recursive = FALSE)
      writeLines(c(momo_paths$data, momo_paths$logs, momo_paths$reports))
    } else {
      momo_deadline <- Sys.time() + 12
      momo_ready <- FALSE
      while (Sys.time() < momo_deadline) {
        momo_error_file <- file.path(momo_paths$reports, "last-error.txt")
        if (file.exists(momo_error_file)) stop(paste(readLines(momo_error_file, warn = FALSE), collapse = "\n"))
        momo_owner_path <- file.path(momo_paths$data, "instance.rds")
        momo_ready_path <- file.path(momo_paths$data, "ready.rds")
        momo_owner <- if (file.exists(momo_owner_path)) tryCatch(readRDS(momo_owner_path), error = function(e) NULL) else NULL
        momo_ready_record <- if (file.exists(momo_ready_path)) tryCatch(readRDS(momo_ready_path), error = function(e) NULL) else NULL
        if (is.list(momo_owner) && length(momo_owner$pid) == 1L && length(momo_owner$created) == 1L &&
            identical(momo_owner, momo_ready_record)) {
          momo_ready <- tryCatch({
            momo_handle <- ps::ps_handle(momo_owner$pid)
            ps::ps_is_running(momo_handle) && abs(ps::ps_create_time(momo_handle) - momo_owner$created) < 0.01
          }, error = function(e) FALSE)
        }
        if (momo_ready) break
        Sys.sleep(0.15)
      }
      if (!momo_ready) stop("MOMO did not become ready. Check local logs in: ", momo_paths$logs)
      cat("MOMO is running. Right-click the cat for controls.\n")
    }
  }
}, error = function(error) {
  message("MOMO: ", conditionMessage(error))
  quit(save = "no", status = 1L)
})
