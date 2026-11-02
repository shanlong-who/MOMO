library(processx)
library(ps)

if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript test_native.R BUILD_DIR NEW_TEST_DIR")
build.dir <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
test.dir <- args[[2]]
stopifnot(!dir.exists(test.dir))
dir.create(test.dir, recursive = TRUE)
test.dir <- normalizePath(test.dir, winslash = "/", mustWork = TRUE)
report <- character()
processes <- list()
test.env <- c(PATH = "C:/Windows/System32", R_HOME = "Z:/no-r", R_LIBS = "Z:/no-r-library",
              HTTP_PROXY = "http://127.0.0.1:1", HTTPS_PROXY = "http://127.0.0.1:1")

record_pass <- function(text) {
  report <<- c(report, paste0("PASS: ", text))
  writeLines(report, file.path(test.dir, "NATIVE-TEST-RESULTS.txt"))
  cat(tail(report, 1), "\n")
}
run_app <- function(exe, arguments, expected = 0L) {
  result <- run(exe, arguments, env = test.env, error_on_status = FALSE,
                windows_hide_window = TRUE, timeout = 20000)
  stopifnot(result$status == expected)
  invisible(result)
}
wait_ready <- function(path, process) {
  deadline <- Sys.time() + 15
  while (!file.exists(path) && process$is_alive() && Sys.time() < deadline) Sys.sleep(0.1)
  stopifnot(file.exists(path), process$is_alive())
}
read_state <- function(path) {
  lines <- readLines(path, warn = FALSE)
  values <- strsplit(lines, "=", fixed = TRUE)
  setNames(vapply(values, function(x) as.numeric(x[[2]]), numeric(1)),
           vapply(values, `[`, character(1), 1))
}

test_all <- function() {
  on.exit(for (process in processes) if (process$is_alive()) process$kill(), add = TRUE)
  paths <- list()
  for (pet in c("MOMO", "MIMI")) {
    pet.dir <- file.path(test.dir, paste0(pet, " space \u4e2d\u6587 & 100%"))
    dir.create(pet.dir)
    exe <- file.path(pet.dir, paste0(pet, ".exe"))
    stopifnot(file.copy(file.path(build.dir, paste0(pet, ".exe")), exe))
    data.dir <- file.path(pet.dir, "settings")
    paths[[pet]] <- list(exe = exe, data = data.dir)
    self.report <- file.path(pet.dir, "self-test.txt")
    run_app(exe, c("--self-test", self.report))
    stopifnot(length(grep("^PASS", readLines(self.report))) == 4L)
    record_pass(paste(pet, "embedded frames, alpha, sizes, directions and screen bounds."))
    smoke.report <- file.path(pet.dir, "smoke-test.txt")
    run_app(exe, c("--smoke-test", smoke.report))
    stopifnot(length(grep("^PASS", readLines(smoke.report))) == 2L)
    record_pass(paste(pet, "all frames and sizes in a real transparent native window."))
    process <- processx::process$new(exe, c("--data-dir", data.dir), env = test.env, windows_hide_window = TRUE)
    processes[[pet]] <<- process
    wait_ready(file.path(data.dir, "state.txt"), process)
    run_app(exe, c("--data-dir", data.dir))
    run_app(exe, c("--data-dir", data.dir, "--snapshot"))
    state <- read_state(file.path(data.dir, "state.txt"))
    stopifnot(state[["pid"]] == process$get_pid())
    record_pass(paste(pet, "single-instance launch and home request from relocated EXE alone."))
    for (action in 101:105) {
      run_app(exe, c("--data-dir", data.dir, "--command", as.character(action)))
      run_app(exe, c("--data-dir", data.dir, "--snapshot"))
      state <- read_state(file.path(data.dir, "state.txt"))
      stopifnot(state[["row"]] == c(3, 4, 7, 8, 5)[action - 100])
    }
    run_app(exe, c("--data-dir", data.dir, "--command", "204"))
    for (toggle in 106:109) run_app(exe, c("--data-dir", data.dir, "--command", as.character(toggle)))
    run_app(exe, c("--data-dir", data.dir, "--snapshot"))
    state <- read_state(file.path(data.dir, "state.txt"))
    stopifnot(state[["size"]] == 288, state[["paused"]] == 1,
              state[["wander"]] == 0, state[["follow"]] == 0, state[["topmost"]] == 0)
    record_pass(paste(pet, "five actions, resize, pause, wandering, cursor tracking and topmost settings."))
  }
  stopifnot(all(vapply(processes, function(process) process$is_alive(), logical(1))))
  record_pass("MOMO and MIMI run concurrently with separate settings and instance locks.")
  for (pet in c("MOMO", "MIMI")) {
    info <- paths[[pet]]
    run_app(info$exe, c("--data-dir", info$data, "--exit"))
    processes[[pet]]$wait(5000)
    stopifnot(!processes[[pet]]$is_alive(), processes[[pet]]$get_exit_status() == 0)
    if (pet == "MOMO") stopifnot(processes[["MIMI"]]$is_alive())
    process <- processx::process$new(info$exe, c("--data-dir", info$data), env = test.env, windows_hide_window = TRUE)
    processes[[pet]] <<- process
    # A previous snapshot may exist, so require the new process ID.
    deadline <- Sys.time() + 15
    repeat {
      Sys.sleep(0.1)
      state <- read_state(file.path(info$data, "state.txt"))
      if (state[["pid"]] == process$get_pid() || Sys.time() >= deadline) break
    }
    stopifnot(process$is_alive(), state[["pid"]] == process$get_pid(), state[["size"]] == 288,
              state[["paused"]] == 1, state[["wander"]] == 0, state[["follow"]] == 0, state[["topmost"]] == 0)
    handle <- ps_handle(process$get_pid())
    memory.mib <- ps_memory_info(handle)[["rss"]] / 1024^2
    record_pass(sprintf("%s clean exit and preference recovery; paused working set %.1f MiB.", pet, memory.mib))
    run_app(info$exe, c("--data-dir", info$data, "--exit"))
    process$wait(5000)
    stopifnot(process$get_exit_status() == 0)
  }
  record_pass("EXEs run from paths with spaces, Chinese, ampersand and percent characters, without external assets.")
  record_pass("Runtime tests use a system-only PATH, invalid R paths and unusable HTTP/HTTPS proxies.")
}
test_all()
