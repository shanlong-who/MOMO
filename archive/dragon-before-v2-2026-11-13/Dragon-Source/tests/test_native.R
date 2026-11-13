library(processx)
library(ps)

Sys.setlocale("LC_CTYPE", "English_United States.utf8")
test.dir <- file.path("qa", paste0("native-", format(Sys.time(), "%Y%m%d-%H%M%S")))
dir.create(test.dir, recursive = TRUE)
test.dir <- normalizePath(test.dir, winslash = "/")
pet.dir <- file.path(test.dir, "Dragon space \u4e2d\u6587 & 100%")
dir.create(pet.dir)
exe <- file.path(pet.dir, "Dragon-Offline.exe")
stopifnot(file.copy("../Dragon-Offline/Dragon-Offline.exe", exe))
data.dir <- file.path(pet.dir, "settings")
test.env <- c(PATH = "C:/Windows/System32", R_HOME = "Z:/no-r", R_LIBS = "Z:/no-r-library",
              HTTP_PROXY = "http://127.0.0.1:1", HTTPS_PROXY = "http://127.0.0.1:1")
report <- character()
record_pass <- function(text) {
  report <<- c(report, paste0("PASS: ", text))
  writeLines(report, file.path(test.dir, "NATIVE-TEST-RESULTS.txt"))
  cat(tail(report, 1), "\n")
}
run_app <- function(arguments, expected = 0L) {
  result <- run(exe, arguments, env = test.env, error_on_status = FALSE,
                windows_hide_window = TRUE, timeout = 20000)
  stopifnot(result$status == expected)
}
read_state <- function() {
  lines <- readLines(file.path(data.dir, "state.txt"), warn = FALSE)
  values <- strsplit(lines, "=", fixed = TRUE)
  setNames(vapply(values, function(x) as.numeric(x[[2]]), numeric(1)),
           vapply(values, `[`, character(1), 1))
}
test_all <- function() {
  process <- NULL
  on.exit(if (!is.null(process) && process$is_alive()) process$kill(), add = TRUE)
  self.report <- file.path(test.dir, "embedded-frame-test.txt")
  run_app(c("--self-test", self.report))
  stopifnot(length(grep("^PASS", readLines(self.report))) == 4L)
  record_pass("73 embedded frames at four sizes: alpha, smooth edges, transparent borders and monitor bounds.")
  smoke.report <- file.path(test.dir, "window-smoke-test.txt")
  run_app(c("--smoke-test", smoke.report))
  stopifnot(length(grep("^PASS", readLines(smoke.report))) == 2L)
  record_pass("All 73 frames and four sizes rendered through a real transparent native Windows window.")
  process <- processx::process$new(exe, c("--data-dir", data.dir), env = test.env, windows_hide_window = TRUE)
  deadline <- Sys.time() + 10
  while (!file.exists(file.path(data.dir, "state.txt")) && process$is_alive() && Sys.time() < deadline) Sys.sleep(0.1)
  stopifnot(process$is_alive(), file.exists(file.path(data.dir, "state.txt")))
  run_app(c("--data-dir", data.dir))
  run_app(c("--data-dir", data.dir, "--snapshot"))
  stopifnot(read_state()[["pid"]] == process$get_pid())
  record_pass("Reopening the EXE reuses the same instance and brings Dragon home.")
  for (action in 101:105) {
    run_app(c("--data-dir", data.dir, "--command", as.character(action)))
    run_app(c("--data-dir", data.dir, "--snapshot"))
    stopifnot(read_state()[["row"]] == c(3, 4, 7, 8, 5)[action - 100])
  }
  record_pass("Hello, jump, thinking, review and disappointment commands select the intended animation rows.")
  for (size in 201:204) {
    run_app(c("--data-dir", data.dir, "--command", as.character(size)))
    run_app(c("--data-dir", data.dir, "--snapshot"))
    stopifnot(read_state()[["size"]] == c(144, 192, 240, 288)[size - 200])
  }
  for (toggle in 106:109) run_app(c("--data-dir", data.dir, "--command", as.character(toggle)))
  run_app(c("--data-dir", data.dir, "--snapshot"))
  state <- read_state()
  stopifnot(state[["paused"]] == 1, state[["wander"]] == 0, state[["follow"]] == 0, state[["topmost"]] == 0)
  record_pass("Four sizes, pause, wandering, cursor tracking and always-on-top controls work.")
  run_app(c("--data-dir", data.dir, "--exit"))
  process$wait(5000)
  stopifnot(!process$is_alive(), process$get_exit_status() == 0)
  process <- processx::process$new(exe, c("--data-dir", data.dir), env = test.env, windows_hide_window = TRUE)
  deadline <- Sys.time() + 10
  repeat {
    Sys.sleep(0.1)
    state <- read_state()
    if (state[["pid"]] == process$get_pid() || Sys.time() >= deadline) break
  }
  stopifnot(process$is_alive(), state[["pid"]] == process$get_pid(), state[["size"]] == 288,
            state[["paused"]] == 1, state[["wander"]] == 0, state[["follow"]] == 0, state[["topmost"]] == 0)
  memory.mib <- ps_memory_info(ps_handle(process$get_pid()))[["rss"]] / 1024^2
  record_pass(sprintf("Clean exit and restored settings after restart; paused working set %.1f MiB.", memory.mib))
  run_app(c("--data-dir", data.dir, "--exit"))
  process$wait(5000)
  stopifnot(process$get_exit_status() == 0)
  record_pass("Relocated EXE alone works in a path containing spaces, Chinese, ampersand and percent.")
  record_pass("Runtime verification uses system-only PATH, invalid R paths and unusable HTTP/HTTPS proxies.")
  file.copy(file.path(test.dir, "NATIVE-TEST-RESULTS.txt"), "../Dragon-Offline/TEST-RESULTS.txt", overwrite = TRUE)
  writeLines(test.dir, "qa/latest-native-test.txt")
}
test_all()
