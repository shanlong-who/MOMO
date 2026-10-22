# This entry point uses only the runtime and packages shipped in this ZIP.
library(utils)

pet.name <- "@PET@"
pet.id <- tolower(pet.name)
file.argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (!length(file.argument)) stop("Run this helper with the bundled Rscript.")
pet.root <- dirname(dirname(normalizePath(sub("^--file=", "", file.argument[[1L]]),
                                         winslash = "/", mustWork = TRUE)))
pet.app <- file.path(pet.root, "app")
runtime.home <- normalizePath(file.path(pet.root, "runtime", "R"), winslash = "/", mustWork = TRUE)
if (!identical(tolower(normalizePath(R.home(), winslash = "/")), tolower(runtime.home))) {
  stop("Use the bundled R runtime through the Start or Check launcher.")
}
.libPaths(file.path(runtime.home, "library"), include.site = FALSE)
if (any(!startsWith(tolower(.libPaths()), paste0(tolower(runtime.home), "/")))) {
  stop("An external R package library was detected.")
}

test.root <- Sys.getenv("PET_TEST_ROOT", unset = "")
data.directory <- if (nzchar(test.root)) file.path(test.root, pet.id, "data") else
  tools::R_user_dir(paste0(pet.id, "-portable"), "data")
cache.directory <- if (nzchar(test.root)) file.path(test.root, pet.id, "cache") else
  tools::R_user_dir(paste0(pet.id, "-portable"), "cache")
path.variables <- setNames(list(data.directory, cache.directory),
                          paste0(pet.name, c("_DATA_DIR", "_CACHE_DIR")))
do.call(Sys.setenv, path.variables)
source(file.path(pet.app, "bootstrap.R"), local = TRUE)
pet.paths <- get(paste0(pet.id, "_runtime_paths"))()
ensure_directory <- get(paste0(pet.id, "_ensure_directory"))
pet.arguments <- commandArgs(TRUE)
pet.action <- if (length(pet.arguments)) pet.arguments[[1L]] else "check"

read_record <- function(path) {
  if (file.exists(path)) tryCatch(readRDS(path), error = function(e) NULL) else NULL
}

instance_ready <- function() {
  owner <- read_record(file.path(pet.paths$data, "instance.rds"))
  ready <- read_record(file.path(pet.paths$data, "ready.rds"))
  if (!is.list(owner) || length(owner$pid) != 1L || length(owner$created) != 1L ||
      !identical(owner, ready)) return(FALSE)
  tryCatch({
    handle <- ps::ps_handle(owner$pid)
    ps::ps_is_running(handle) && abs(ps::ps_create_time(handle) - owner$created) < 0.01
  }, error = function(e) FALSE)
}

tryCatch({
  if (!pet.action %in% c("paths", "await", "run", "check", "self-test", "smoke-test", "stop")) {
    stop("Unknown portable action: ", pet.action)
  }
  get(paste0(pet.id, "_check_requirements"))(pet.app)
  if (pet.action == "stop") {
    if (get(paste0(pet.id, "_stop"))()) cat(pet.name, "has been asked to close.\n") else
      cat(pet.name, "is not running.\n")
  } else if (pet.action == "paths") {
    invisible(lapply(pet.paths[c("data", "logs", "reports")], ensure_directory))
    error.file <- file.path(pet.paths$reports, "last-error.txt")
    if (file.exists(error.file)) unlink(error.file, recursive = FALSE)
    writeLines(unlist(pet.paths[c("data", "logs", "reports")], use.names = FALSE))
  } else if (pet.action == "await") {
    deadline <- Sys.time() + 30
    while (Sys.time() < deadline && !instance_ready()) {
      error.file <- file.path(pet.paths$reports, "last-error.txt")
      if (file.exists(error.file)) stop(paste(readLines(error.file, warn = FALSE), collapse = "\n"))
      Sys.sleep(0.15)
    }
    if (!instance_ready()) stop("Startup did not finish. Run Check ", pet.name, ".cmd and inspect: ", pet.paths$logs)
    cat(pet.name, "Portable is running. Right-click the cat for controls.\n")
  } else {
    if (pet.action == "check") {
      manifest <- read.delim(file.path(pet.root, "MANIFEST.tsv"), stringsAsFactors = FALSE)
      actual <- unname(tools::md5sum(file.path(pet.root, manifest$file)))
      failed <- is.na(actual) | actual != manifest$md5
      if (any(failed)) stop("Missing or changed release files: ", paste(manifest$file[failed], collapse = ", "))
      cat("PASS: all", nrow(manifest), "release files match the integrity manifest.\n")
      cat("Runtime:", R.version.string, "\n")
      cat("R home:", runtime.home, "\n")
      cat("Package libraries:", paste(.libPaths(), collapse = "; "), "\n")
      cat("ps:", as.character(packageVersion("ps")), "\n")
      cat("Settings:", pet.paths$data, "\n")
      cat("Diagnostics:", pet.paths$reports, "\n")
    }
    source(file.path(pet.app, paste0(pet.id, ".R")), local = TRUE)
    run.arguments <- switch(pet.action, check = "--self-test", `self-test` = "--self-test",
                            `smoke-test` = "--smoke-test", character())
    get(paste0(pet.id, "_main"))(pet.app, run.arguments)
  }
}, error = function(error) {
  if (pet.action == "run") {
    try({ ensure_directory(pet.paths$reports)
      writeLines(conditionMessage(error), file.path(pet.paths$reports, "last-error.txt")) }, silent = TRUE)
  }
  message(pet.name, " Portable: ", conditionMessage(error))
  quit(save = "no", status = 1L)
})
