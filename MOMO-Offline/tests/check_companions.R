library(tcltk)
library(ps)

source_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(source_file)) source_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
app_dir <- dirname(dirname(dirname(normalizePath(source_file, winslash = "/", mustWork = TRUE))))
momo_env <- new.env()
mimi_env <- new.env()
source(file.path(app_dir, "MOMO-Offline", "bootstrap.R"), local = momo_env)
source(file.path(app_dir, "MIMI-Offline", "bootstrap.R"), local = mimi_env)
source(file.path(app_dir, "MOMO-Offline", "momo.R"), local = momo_env)
source(file.path(app_dir, "MIMI-Offline", "mimi.R"), local = mimi_env)

check_companions <- function() {
  path_variables <- c("MOMO_DATA_DIR", "MOMO_CACHE_DIR", "MIMI_DATA_DIR", "MIMI_CACHE_DIR")
  original_values <- Sys.getenv(path_variables, unset = NA_character_)
  on.exit({
    Sys.unsetenv(path_variables)
    present <- !is.na(original_values)
    if (any(present)) do.call(Sys.setenv, as.list(original_values[present]))
  }, add = TRUE)
  Sys.unsetenv(path_variables)
  stopifnot(!identical(momo_env$momo_runtime_paths()$data, mimi_env$mimi_runtime_paths()$data),
            !identical(momo_env$momo_runtime_paths()$cache, mimi_env$mimi_runtime_paths()$cache),
            identical(momo_env$momo_frame_counts, mimi_env$mimi_frame_counts),
            identical(momo_env$momo_sizes, mimi_env$mimi_sizes))

  test_root <- tempfile("companion-check-")
  dir.create(test_root)
  momo_state <- file.path(test_root, "momo")
  mimi_state <- file.path(test_root, "mimi")
  dir.create(momo_state)
  dir.create(mimi_state)
  Sys.setenv(MOMO_DATA_DIR = momo_state, MIMI_DATA_DIR = mimi_state)
  momo_instance <- momo_env$momo_acquire_instance(momo_state)
  on.exit(momo_env$momo_release_instance(momo_instance), add = TRUE)
  mimi_instance <- mimi_env$mimi_acquire_instance(mimi_state)
  on.exit(mimi_env$mimi_release_instance(mimi_instance), add = TRUE)
  stopifnot(momo_instance$owned, mimi_instance$owned)
  stopifnot(!mimi_env$mimi_acquire_instance(mimi_state)$owned)
  stopifnot(file.exists(mimi_instance$request_path), !file.exists(momo_instance$request_path))
  stopifnot(mimi_env$mimi_stop(), file.exists(mimi_instance$exit_path), !file.exists(momo_instance$exit_path))
  stopifnot(momo_env$momo_stop(), file.exists(momo_instance$exit_path))

  momo_prefs <- momo_env$momo_defaults()
  mimi_prefs <- mimi_env$mimi_defaults()
  momo_prefs$width <- 144L
  mimi_prefs$width <- 288L
  saveRDS(momo_prefs, file.path(momo_state, "preferences.rds"))
  saveRDS(mimi_prefs, file.path(mimi_state, "preferences.rds"))
  stopifnot(identical(momo_env$momo_read_preferences(file.path(momo_state, "preferences.rds")), momo_prefs),
            identical(mimi_env$mimi_read_preferences(file.path(mimi_state, "preferences.rds")), mimi_prefs))
  cat("PASS: separate default data/cache paths and independent instance, show and exit signals.\n")
  cat("PASS: independent preferences, matching animation layouts and four display sizes.\n")
}

check_companions()
