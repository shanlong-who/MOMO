# Shared startup and path helpers. Runtime state stays outside the download.
momo_runtime_paths <- function() {
  data_dir <- Sys.getenv("MOMO_DATA_DIR", unset = "")
  cache_dir <- Sys.getenv("MOMO_CACHE_DIR", unset = "")
  if (!nzchar(data_dir)) data_dir <- tools::R_user_dir("momo", "data")
  if (!nzchar(cache_dir)) cache_dir <- tools::R_user_dir("momo", "cache")
  data_dir <- path.expand(data_dir)
  cache_dir <- path.expand(cache_dir)
  list(data = data_dir, cache = cache_dir, reports = file.path(cache_dir, "diagnostics"),
       logs = file.path(cache_dir, "logs"))
}

momo_ensure_directory <- function(path) {
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE, showWarnings = FALSE)) {
    stop("MOMO could not create its local data directory: ", path, call. = FALSE)
  }
  invisible(path)
}

momo_check_requirements <- function(app_dir) {
  if (.Platform$OS.type != "windows") {
    stop("This version of MOMO supports Windows only. macOS and Linux are not supported.", call. = FALSE)
  }
  if (getRversion() < "4.2.0") stop("MOMO requires R 4.2 or later.", call. = FALSE)
  if (!capabilities("tcltk") || !requireNamespace("tcltk", quietly = TRUE)) {
    stop("Your R installation needs Tcl/Tk support. Use an R for Windows installation that includes Tcl/Tk.", call. = FALSE)
  }
  if (!requireNamespace("ps", quietly = TRUE)) {
    stop("The ps package is missing from this R installation. In that R, run install.packages(\"ps\"), then try again.", call. = FALSE)
  }
  required <- file.path(app_dir, "assets", paste0("momo-", c(144L, 192L, 240L, 288L), ".png"))
  if (any(!file.exists(required))) {
    stop("MOMO's artwork is missing. Extract the entire download before starting it.", call. = FALSE)
  }
  invisible(TRUE)
}

momo_stop <- function() {
  state_dir <- momo_runtime_paths()$data
  if (file.exists(file.path(state_dir, "instance.lock"))) {
    writeLines("exit", file.path(state_dir, "exit.request"))
    return(invisible(TRUE))
  }
  invisible(FALSE)
}
