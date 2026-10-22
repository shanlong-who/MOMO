# Test the actual ZIPs in an isolated directory, using only bundled runtimes.
library(processx)
library(ps)
library(zip)

if (.Platform$OS.type == "windows" && !l10n_info()[["UTF-8"]]) {
  invisible(Sys.setlocale("LC_CTYPE", ".UTF-8"))
  if (!l10n_info()[["UTF-8"]]) stop("The Unicode-path tests require a UTF-8 Windows R locale.")
}

test.arguments <- commandArgs(TRUE)
if (length(test.arguments) != 3L) stop("Usage: Rscript test_portable.R ZIP_DIR TEST_DIR REPORT_FILE")
archive.directory <- normalizePath(test.arguments[[1L]], winslash = "/", mustWork = TRUE)
test.directory <- normalizePath(test.arguments[[2L]], winslash = "/", mustWork = FALSE)
report.file <- normalizePath(test.arguments[[3L]], winslash = "/", mustWork = FALSE)
if (dir.exists(test.directory)) stop("Use a new test directory; existing files are never overwritten.")
dir.create(test.directory, recursive = TRUE)
test.directory <- normalizePath(test.directory, winslash = "/", mustWork = TRUE)

test_portable <- function() {
  results <- c("Portable release validation", paste("Platform:", Sys.info()[["sysname"]], Sys.info()[["release"]]),
               "Tests use the final ZIPs extracted into a path with spaces and Chinese characters.")
  pet.directories <- list()
  launcher.processes <- list()
  state.root <- file.path(test.directory, "isolated-state")
  profile.path <- file.path(test.directory, "forbidden-profile.R")
  writeLines('stop("An external user profile was unexpectedly loaded.")', profile.path)
  system.root <- Sys.getenv("SystemRoot")
  clean.path <- paste(file.path(system.root, c("System32", "System32/WindowsPowerShell/v1.0")), collapse = ";")
  test.environment <- c("current", PATH = clean.path, R_HOME = "Z:/not-installed/R", R_LIBS = "Z:/not-installed/library",
                        R_LIBS_USER = "Z:/not-installed/library", R_LIBS_SITE = "Z:/not-installed/library",
                        R_PROFILE_USER = profile.path, R_ENVIRON_USER = profile.path,
                        MOMO_RSCRIPT = "Z:/not-installed/Rscript.exe", MIMI_RSCRIPT = "Z:/not-installed/Rscript.exe",
                        R_DEFAULT_PACKAGES = "invalid_external_package", PET_TEST_ROOT = state.root,
                        HTTP_PROXY = "http://127.0.0.1:9", HTTPS_PROXY = "http://127.0.0.1:9",
                        ALL_PROXY = "http://127.0.0.1:9")

  run_launcher <- function(pet.name, action, public = FALSE, timeout = 90) {
    pet.directory <- pet.directories[[pet.name]]
    launcher <- if (public) file.path(pet.directory, paste(if (action == "start") "Start" else "Exit", paste0(pet.name, ".cmd"))) else
      file.path(pet.directory, "scripts", "portable.cmd")
    launcher <- normalizePath(launcher, winslash = "\\", mustWork = TRUE)
    command <- normalizePath(file.path(system.root, "System32", "cmd.exe"), winslash = "\\")
    if (action != "start") {
      return(processx::run(command, c("/d", "/c", "call", shQuote(launcher, type = "cmd"), if (!public) action),
        env = test.environment, wd = test.directory, timeout = timeout,
        error_on_status = FALSE, windows_hide_window = TRUE, windows_verbatim_args = TRUE))
    }
    stdout.file <- tempfile("launcher-", tmpdir = test.directory, fileext = ".out.txt")
    stderr.file <- tempfile("launcher-", tmpdir = test.directory, fileext = ".err.txt")
    status.file <- tempfile("launcher-", tmpdir = test.directory, fileext = ".status.txt")
    wrapper.file <- tempfile("invoke-", tmpdir = test.directory, fileext = ".cmd")
    writeLines(c("@echo off",
                 'call "%PET_TEST_LAUNCHER%" %PET_TEST_ACTION% > "%PET_TEST_STDOUT%" 2> "%PET_TEST_STDERR%"',
                 'set "PET_TEST_EXIT=%ERRORLEVEL%"',
                 '> "%PET_TEST_STATUS%" echo PORTABLE_TEST_EXIT=%PET_TEST_EXIT%',
                 'exit /b %PET_TEST_EXIT%'), wrapper.file)
    wrapper.file <- normalizePath(wrapper.file, winslash = "\\")
    # Windows job objects may outlive the launcher while its detached pet runs.
    # The wrapper records the real launcher exit status before that wait.
    process <- processx::process$new(command, c("/d", "/c", shQuote(wrapper.file, type = "cmd")),
      env = c(test.environment, PET_TEST_LAUNCHER = launcher, PET_TEST_ACTION = if (public) "" else action,
              PET_TEST_STDOUT = stdout.file, PET_TEST_STDERR = stderr.file, PET_TEST_STATUS = status.file),
      wd = test.directory, windows_hide_window = TRUE, windows_verbatim_args = TRUE,
      stdout = NULL, stderr = NULL, cleanup = FALSE, cleanup_tree = FALSE)
    launcher.processes[[length(launcher.processes) + 1L]] <<- process
    deadline <- Sys.time() + timeout
    repeat {
      status.lines <- if (file.exists(status.file)) readLines(status.file, warn = FALSE) else character()
      completed <- grep("^PORTABLE_TEST_EXIT=-?[0-9]+$", status.lines, value = TRUE)
      if (length(completed)) break
      if (Sys.time() > deadline) {
        process$kill_tree()
        stop("Timed out waiting for ", pet.name, " ", action)
      }
      Sys.sleep(0.1)
    }
    output <- readLines(stdout.file, warn = FALSE, encoding = "UTF-8")
    list(status = as.integer(sub("^PORTABLE_TEST_EXIT=", "", tail(completed, 1L))),
         stdout = paste(output[!grepl("^PORTABLE_TEST_EXIT=", output)], collapse = "\n"),
         stderr = paste(readLines(stderr.file, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
  }

  require_success <- function(result, label) {
    if (result$status != 0L) {
      writeLines(c(label, result$stdout, result$stderr), file.path(test.directory, "failure-log.txt"))
      cat(result$stdout, result$stderr, "\n")
      stop(label, " failed with exit status ", result$status)
    }
    invisible(result)
  }

  read_owner <- function(pet.name) {
    path <- file.path(state.root, tolower(pet.name), "data", "instance.rds")
    if (file.exists(path)) tryCatch(readRDS(path), error = function(e) NULL) else NULL
  }

  owner_running <- function(record) {
    if (is.null(record)) return(FALSE)
    tryCatch({
      handle <- ps::ps_handle(record$pid)
      ps::ps_is_running(handle) && abs(ps::ps_create_time(handle) - record$created) < 0.01
    }, error = function(e) FALSE)
  }

  await_closed <- function(record) {
    deadline <- Sys.time() + 8
    while (owner_running(record) && Sys.time() < deadline) Sys.sleep(0.1)
    if (owner_running(record)) stop("A test pet did not close after its Exit launcher.")
  }

  on.exit({
    for (pet.name in names(pet.directories)) {
      record <- read_owner(pet.name)
      if (owner_running(record)) {
        try(run_launcher(pet.name, "stop"), silent = TRUE)
        Sys.sleep(0.6)
        if (owner_running(record)) try(ps::ps_kill(ps::ps_handle(record$pid)), silent = TRUE)
      }
    }
  }, add = TRUE)

  for (pet.name in c("MOMO", "MIMI")) {
    cat("Validating", pet.name, "release ZIP...\n")
    archive <- list.files(archive.directory, pattern = paste0("^", pet.name, "-Portable-.*-windows-x64\\.zip$"), full.names = TRUE)
    stopifnot(length(archive) == 1L)
    extraction.directory <- file.path(test.directory, paste0(pet.name, " path with spaces ", intToUtf8(c(36335, 24452))))
    dir.create(extraction.directory)
    zip::unzip(archive, exdir = extraction.directory)
    pet.directories[[pet.name]] <- file.path(extraction.directory, paste0(pet.name, "-Portable"))
    check <- require_success(run_launcher(pet.name, "check"), paste(pet.name, "integrity and self-test"))
    self.report <- readLines(file.path(state.root, tolower(pet.name), "cache", "diagnostics", "self-test.txt"))
    stopifnot(any(grepl("296 frame copies", self.report, fixed = TRUE)),
              any(grepl("R version 4.6.1", self.report, fixed = TRUE)))
    results <- c(results, paste0("PASS: ", pet.name, " complete ZIP integrity, bundled R 4.6.1 / ps 1.9.3, all 296 frame copies,"),
                 "      preferences, cursor directions, screen bounds and stale-instance recovery.")
    require_success(run_launcher(pet.name, "smoke-test"), paste(pet.name, "window smoke test"))
    render.report <- file.path(state.root, tolower(pet.name), "cache", "diagnostics", "render-test.txt")
    stopifnot(file.exists(render.report))
    results <- c(results, paste0("PASS: ", pet.name, " 74 frames and all four sizes rendered in a real transparent Tk window."))
    require_success(run_launcher(pet.name, "start", public = TRUE), paste(pet.name, "public Start launcher"))
    first.owner <- read_owner(pet.name)
    stopifnot(owner_running(first.owner))
    process.path <- normalizePath(ps::ps_exe(ps::ps_handle(first.owner$pid)), winslash = "/")
    stopifnot(startsWith(tolower(process.path), paste0(tolower(pet.directories[[pet.name]]), "/runtime/r/")))
    require_success(run_launcher(pet.name, "start", public = TRUE), paste(pet.name, "repeat Start"))
    stopifnot(identical(first.owner, read_owner(pet.name)))
    window.report <- readLines(file.path(state.root, tolower(pet.name), "cache", "diagnostics", "last-window-state.txt"))
    stopifnot("Mapped: 1" %in% window.report, "Viewable: 1" %in% window.report)
    results <- c(results, paste0("PASS: ", pet.name, " public Start launcher, visible window and one process after repeated Start."))
  }
  momo.owner <- read_owner("MOMO")
  mimi.owner <- read_owner("MIMI")
  stopifnot(owner_running(momo.owner), owner_running(mimi.owner), momo.owner$pid != mimi.owner$pid)
  require_success(run_launcher("MOMO", "stop", public = TRUE), "MOMO public Exit")
  await_closed(momo.owner)
  stopifnot(owner_running(mimi.owner))
  require_success(run_launcher("MIMI", "stop", public = TRUE), "MIMI public Exit")
  await_closed(mimi.owner)
  results <- c(results, "PASS: both cats run concurrently; exiting MOMO leaves MIMI running; both public Exit launchers work.")

  for (pet.name in names(pet.directories)) {
    previous.directory <- pet.directories[[pet.name]]
    relocated.directory <- file.path(dirname(previous.directory), paste0("Moved ", pet.name, " Portable"))
    stopifnot(startsWith(previous.directory, paste0(test.directory, "/")),
              startsWith(relocated.directory, paste0(test.directory, "/")))
    stopifnot(file.rename(previous.directory, relocated.directory))
    pet.directories[[pet.name]] <- relocated.directory
    require_success(run_launcher(pet.name, "start", public = TRUE), paste(pet.name, "relocated Start"))
    record <- read_owner(pet.name)
    stopifnot(owner_running(record))
    require_success(run_launcher(pet.name, "stop", public = TRUE), paste(pet.name, "relocated Exit"))
    await_closed(record)

    check_missing_file <- function(relative.path, expected.message) {
      target <- file.path(relocated.directory, relative.path)
      saved <- paste0(target, ".test-saved")
      stopifnot(startsWith(target, paste0(test.directory, "/")), !file.exists(saved))
      stopifnot(file.rename(target, saved))
      on.exit(stopifnot(file.rename(saved, target)))
      result <- run_launcher(pet.name, "check")
      stopifnot(result$status != 0L, grepl(expected.message, paste(result$stdout, result$stderr), fixed = TRUE))
    }
    check_missing_file(paste0("app/assets/", tolower(pet.name), "-192.png"), "artwork is missing")
    check_missing_file("runtime/R/bin/x64/Rscript.exe", "bundled R runtime is missing")
    results <- c(results, paste0("PASS: ", pet.name, " runs after relocation; missing artwork/runtime gives a clear failure without system-R fallback."))
  }
  results <- c(results,
               "PASS: launchers work with no R on PATH, invalid system-R overrides, invalid external libraries and a failing user profile.",
               "PASS: launchers and animation tests work with unusable HTTP/HTTPS proxy settings; no dependency download is required.",
               "Scope: the host network was not disconnected. This is isolation testing, not a claim that R was uninstalled from the host.",
               "Scope: Windows x64 only. Managed-device security policies and Windows ARM were not certified.")
  dir.create(dirname(report.file), recursive = TRUE, showWarnings = FALSE)
  writeLines(results, report.file)
  cat(paste(results, collapse = "\n"), "\n")
}

test_portable()
