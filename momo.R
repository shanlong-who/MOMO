library(tcltk)
library(ps)

momo_frame_counts <- c(7L, 8L, 8L, 4L, 5L, 8L, 6L, 6L, 6L, 8L, 8L)
momo_sizes <- c(Small = 144L, Medium = 192L, Large = 240L, `Extra large` = 288L)

momo_defaults <- function() {
  list(x = NA_real_, y = NA_real_, width = 192L, paused = FALSE,
       wander = TRUE, follow_cursor = TRUE, topmost = TRUE)
}

momo_read_preferences <- function(path) {
  defaults <- momo_defaults()
  if (!file.exists(path)) return(defaults)
  saved <- tryCatch(readRDS(path), error = function(e) NULL)
  if (!is.list(saved)) return(defaults)
  for (name in c("x", "y")) {
    value <- saved[[name]]
    if (is.numeric(value) && length(value) == 1L && is.finite(value) && abs(value) < 100000) defaults[[name]] <- value
  }
  if (is.numeric(saved$width) && length(saved$width) == 1L && saved$width %in% momo_sizes) defaults$width <- as.integer(saved$width)
  for (name in c("paused", "wander", "follow_cursor", "topmost")) {
    if (is.logical(saved[[name]]) && length(saved[[name]]) == 1L && !is.na(saved[[name]])) defaults[[name]] <- saved[[name]]
  }
  defaults
}

momo_clamp <- function(x, y, width, height, screen_width, screen_height) {
  c(x = max(0, min(x, max(0, screen_width - width))),
    y = max(0, min(y, max(0, screen_height - height - 52))))
}

momo_direction <- function(dx, dy) {
  as.integer(round((atan2(dx, -dy) * 180 / pi + 360) / 22.5)) %% 16L
}

momo_process_matches <- function(record) {
  if (!is.list(record) || length(record$pid) != 1L || length(record$created) != 1L) return(FALSE)
  tryCatch({
    handle <- ps_handle(record$pid)
    ps_is_running(handle) && abs(ps_create_time(handle) - record$created) < 0.01
  }, error = function(e) FALSE)
}

momo_acquire_instance <- function(state_dir) {
  lock_path <- file.path(state_dir, "instance.lock")
  owner_path <- file.path(state_dir, "instance.rds")
  request_path <- file.path(state_dir, "show.request")
  exit_path <- file.path(state_dir, "exit.request")
  for (attempt in seq_len(2L)) {
    channel <- tryCatch(tcl("open", lock_path, "WRONLY CREAT EXCL"), error = function(e) NULL)
    if (!is.null(channel)) {
      tcl("close", channel)
      unlink(c(request_path, exit_path, file.path(state_dir, "ready.rds")), recursive = FALSE)
      record <- list(pid = Sys.getpid(), created = ps_create_time(ps_handle()))
      saveRDS(record, owner_path)
      return(list(owned = TRUE, record = record, lock_path = lock_path, owner_path = owner_path,
                  request_path = request_path, exit_path = exit_path))
    }
    owner <- if (file.exists(owner_path)) tryCatch(readRDS(owner_path), error = function(e) NULL) else NULL
    age <- as.numeric(difftime(Sys.time(), file.info(lock_path)$mtime, units = "secs"))
    if (momo_process_matches(owner) || (is.null(owner) && is.finite(age) && age < 5)) {
      writeLines("show", request_path)
      return(list(owned = FALSE))
    }
    # Only remove this app's stale instance marker, never a directory.
    unlink(lock_path, recursive = FALSE)
  }
  stop("MOMO could not acquire its local instance marker.")
}

momo_release_instance <- function(instance) {
  owner <- tryCatch(readRDS(instance$owner_path), error = function(e) NULL)
  if (identical(owner, instance$record)) {
    unlink(c(instance$lock_path, instance$owner_path, instance$request_path, instance$exit_path,
             file.path(dirname(instance$lock_path), "ready.rds")), recursive = FALSE)
  }
}

momo_self_test <- function(app_dir) {
  report_dir <- momo_runtime_paths()$reports
  momo_ensure_directory(report_dir)
  results <- character()
  source <- tkimage.create("photo")
  target <- tkimage.create("photo")
  on.exit({ tcl("image", "delete", source); tcl("image", "delete", target) }, add = TRUE)
  occupied <- 0L
  for (width in unname(momo_sizes)) {
    height <- as.integer(width * 208L / 192L)
    tcl(source, "configure", "-file", file.path(app_dir, "assets", sprintf("momo-%d.png", width)))
    stopifnot(as.integer(tclvalue(tcl("image", "width", source))) == width * 8L,
              as.integer(tclvalue(tcl("image", "height", source))) == height * 11L)
    tcl(target, "configure", "-width", width, "-height", height)
    for (row in seq_along(momo_frame_counts)) {
      for (column in seq_len(momo_frame_counts[[row]])) {
        x <- (column - 1L) * width
        y <- (row - 1L) * height
        tcl(target, "copy", source, "-from", x, y, x + width, y + height, "-to", 0, 0, "-compositingrule", "set")
        stopifnot(as.integer(tclvalue(tcl("image", "width", target))) == width)
        occupied <- occupied + 1L
      }
    }
  }
  stopifnot(occupied == 296L)
  results <- c(results, "PASS: Tk loaded all four local PNG atlases and copied all 74 occupied cells at each size (296 frame copies).")
  vectors <- rbind(c(0, -10), c(10, -10), c(10, 0), c(10, 10), c(0, 10), c(-10, 10), c(-10, 0), c(-10, -10))
  directions <- vapply(seq_len(nrow(vectors)), function(i) momo_direction(vectors[i, 1L], vectors[i, 2L]), integer(1))
  stopifnot(identical(directions, seq.int(0L, 14L, 2L)))
  stopifnot(identical(unname(momo_clamp(-100, 2000, 192, 208, 1920, 1080)), c(0, 820)))
  stopifnot(identical(unname(momo_clamp(900, -100, 288, 312, 160, 120)), c(0, 0)))
  results <- c(results, "PASS: cardinal and diagonal cursor directions; screen edge and oversized-window bounds.")
  preferences_path <- file.path(report_dir, "test-preferences.rds")
  prefs <- momo_defaults()
  prefs$width <- 240L
  prefs$paused <- TRUE
  saveRDS(prefs, preferences_path)
  stopifnot(identical(momo_read_preferences(preferences_path), prefs))
  saveRDS(list(width = 9000L, paused = "invalid", x = Inf), preferences_path)
  stopifnot(identical(momo_read_preferences(preferences_path), momo_defaults()))
  results <- c(results, "PASS: preferences round trip and malformed-value recovery.")
  instance_dir <- tempfile("instance-check-", tmpdir = report_dir)
  momo_ensure_directory(instance_dir)
  writeLines("stale", file.path(instance_dir, "instance.lock"))
  saveRDS(list(pid = -1L, created = as.POSIXct("2000-01-01", tz = "UTC")), file.path(instance_dir, "instance.rds"))
  writeLines("exit", file.path(instance_dir, "exit.request"))
  instance <- momo_acquire_instance(instance_dir)
  stopifnot(instance$owned, !file.exists(file.path(instance_dir, "exit.request")))
  second_instance <- momo_acquire_instance(instance_dir)
  stopifnot(!second_instance$owned, file.exists(instance$request_path))
  momo_release_instance(instance)
  stopifnot(!file.exists(instance$lock_path), !file.exists(instance$owner_path))
  results <- c(results, "PASS: stale instance recovery, stale exit cleanup and same-process single-instance requests.")
  results <- c(results, paste("R:", R.version.string), paste("Tk:", tclvalue(tcl("package", "require", "Tk"))))
  writeLines(results, file.path(report_dir, "self-test.txt"))
  cat(paste(results, collapse = "\n"), "\n")
  invisible(results)
}

momo_run <- function(app_dir, smoke_test = FALSE) {
  paths <- momo_runtime_paths()
  report_dir <- momo_ensure_directory(paths$reports)
  state_dir <- if (smoke_test) file.path(paths$cache, "smoke-state") else paths$data
  momo_ensure_directory(state_dir)
  instance <- momo_acquire_instance(state_dir)
  if (!instance$owned) return(invisible(NULL))
  on.exit(momo_release_instance(instance), add = TRUE)
  prefs_path <- file.path(state_dir, "preferences.rds")
  state <- new.env(parent = emptyenv())
  state$prefs <- momo_read_preferences(prefs_path)
  state$width <- state$prefs$width
  state$height <- as.integer(state$width * 208L / 192L)
  state$closing <- FALSE
  state$dragging <- FALSE
  state$drag_moved <- FALSE
  state$suppress_release <- FALSE
  state$roaming <- FALSE
  state$menu_open <- FALSE
  state$row <- 3L
  state$column <- 0L
  state$direction <- 1L
  state$now <- function() unname(proc.time()[["elapsed"]])
  now <- state$now()
  state$action_until <- now + 1.4
  state$next_action <- now + 8
  state$next_frame <- now
  state$last_tick <- now
  state$next_request_check <- now
  state$last_pointer <- c(0L, 0L)
  state$pointer_changed <- now - 10
  state$timer_id <- NULL
  state$frames_shown <- 0L
  state$smoke_step <- 0L
  state$smoke_next <- now
  state$smoke_cells <- integer()
  state$smoke_sizes <- integer()
  key_color <- "#01fe02"

  pet <- tktoplevel()
  tkwm.withdraw(pet)
  tkwm.title(pet, "MOMO R Offline")
  tkwm.overrideredirect(pet, TRUE)
  tcl("wm", "attributes", pet, "-transparentcolor", key_color,
      "-topmost", as.integer(state$prefs$topmost), "-toolwindow", 1)
  try(tkwm.iconbitmap(pet, default = file.path(app_dir, "assets", "momo.ico")), silent = TRUE)
  state$screen_width <- as.integer(tclvalue(tkwinfo("screenwidth", pet)))
  state$screen_height <- as.integer(tclvalue(tkwinfo("screenheight", pet)))
  state$x <- if (is.finite(state$prefs$x)) state$prefs$x else state$screen_width - state$width - 70
  state$y <- if (is.finite(state$prefs$y)) state$prefs$y else state$screen_height - state$height - 60
  state$atlas <- tkimage.create("photo")
  state$display <- tkimage.create("photo")
  label <- tklabel(pet, image = state$display, background = key_color,
                   borderwidth = 0, highlightthickness = 0, padx = 0, pady = 0, cursor = "hand2")
  tkpack(label)
  menu <- tkmenu(pet, tearoff = FALSE)
  size_var <- tclVar(state$width)
  option_vars <- lapply(state$prefs[c("paused", "wander", "follow_cursor", "topmost")], function(value) tclVar(as.integer(value)))

  save_preferences <- function() {
    state$prefs$x <- state$x
    state$prefs$y <- state$y
    try(saveRDS(state$prefs, prefs_path), silent = TRUE)
  }

  set_position <- function(x, y, clamp = TRUE) {
    if (clamp) {
      point <- momo_clamp(x, y, state$width, state$height, state$screen_width, state$screen_height)
      x <- point[[1L]]; y <- point[[2L]]
    }
    state$x <- round(x); state$y <- round(y)
    tkwm.geometry(pet, sprintf("%dx%d%+d%+d", state$width, state$height, as.integer(state$x), as.integer(state$y)))
  }

  draw_frame <- function() {
    x <- state$column * state$width
    y <- state$row * state$height
    tcl(state$display, "copy", state$atlas, "-from", x, y, x + state$width, y + state$height,
        "-to", 0, 0, "-compositingrule", "set")
    state$frames_shown <- state$frames_shown + 1L
  }

  resize_pet <- function(width) {
    bottom <- state$y + state$height
    state$width <- as.integer(width)
    state$height <- as.integer(width * 208L / 192L)
    state$prefs$width <- state$width
    tclvalue(size_var) <- state$width
    tcl(state$atlas, "configure", "-file", file.path(app_dir, "assets", sprintf("momo-%d.png", state$width)))
    tcl(state$display, "configure", "-width", state$width, "-height", state$height)
    set_position(state$x, bottom - state$height)
    draw_frame()
  }

  stop_roaming <- function() {
    if (state$roaming) { state$row <- 0L; state$column <- 0L; state$action_until <- 0 }
    state$roaming <- FALSE
  }

  act <- function(row, seconds = 1.8) {
    stop_roaming()
    state$row <- as.integer(row)
    state$column <- 0L
    now <- state$now()
    state$action_until <- now + seconds
    state$next_frame <- now + 0.17
    state$next_action <- state$action_until + runif(1L, 7, 15)
    draw_frame()
  }

  bring_home <- function() {
    stop_roaming()
    set_position(state$screen_width - state$width - 70, state$screen_height - state$height - 60)
    tkwm.deiconify(pet)
    tkraise(pet)
    act(3L)
    save_preferences()
  }

  close_pet <- function() {
    if (state$closing) return(invisible(NULL))
    state$closing <- TRUE
    if (!is.null(state$timer_id)) try(tcl("after", "cancel", state$timer_id), silent = TRUE)
    save_preferences()
    try(tkdestroy(pet), silent = TRUE)
  }

  add_action <- function(text, command) tkadd(menu, "command", label = text, command = command)
  add_action("Say hello", function() act(3L, 1.6))
  add_action("Jump!", function() act(4L, 1.3))
  add_action("Play", function() act(7L, 2.3))
  add_action("Stretch", function() act(8L, 2.3))
  add_action("Rest", function() act(5L, 3.2))
  tkadd(menu, "separator")
  for (option in names(option_vars)) {
    local({
      name <- option
      labels <- c(paused = "Pause animation", wander = "Wander around", follow_cursor = "Look at cursor", topmost = "Always on top")
      tkadd(menu, "checkbutton", label = labels[[name]], variable = option_vars[[name]], command = function() {
        state$prefs[[name]] <- identical(tclvalue(option_vars[[name]]), "1")
        if (name == "wander") stop_roaming()
        if (name == "topmost") tcl("wm", "attributes", pet, "-topmost", as.integer(state$prefs$topmost))
        state$next_action <- state$now() + 8
        save_preferences()
      })
    })
  }
  sizes_menu <- tkmenu(menu, tearoff = FALSE)
  for (size_name in names(momo_sizes)) {
    tkadd(sizes_menu, "radiobutton", label = size_name, variable = size_var, value = momo_sizes[[size_name]],
          command = function() { resize_pet(as.integer(tclvalue(size_var))); save_preferences() })
  }
  tkadd(menu, "cascade", label = "Size", menu = sizes_menu)
  add_action("Bring MOMO home", bring_home)
  tkadd(menu, "separator")
  add_action("About / Controls", function() {
    tkmessageBox(parent = pet, title = "MOMO R Offline", type = "ok", icon = "info", message = paste(
      "MOMO R Offline 1.0", "", "Drag: move MOMO", "Click: say hello", "Double-click: jump",
      "Right-click: actions, size, pause and exit", "Open the launcher again to bring the same MOMO home.", "",
      "Uses your installed R. No ChatGPT, account or internet connection is required.",
      "Preferences are saved in your local user data folder.", sep = "\n"))
  })
  add_action("Exit MOMO", close_pet)

  tkbind(label, "<ButtonPress-1>", function(X, Y) {
    stop_roaming()
    state$dragging <- TRUE
    state$drag_moved <- FALSE
    state$drag_start_pointer <- c(as.numeric(X), as.numeric(Y))
    state$drag_start_position <- c(state$x, state$y)
  })
  tkbind(label, "<B1-Motion>", function(X, Y) {
    if (!state$dragging) return(invisible(NULL))
    delta <- c(as.numeric(X), as.numeric(Y)) - state$drag_start_pointer
    state$drag_moved <- state$drag_moved || sum(abs(delta)) > 5
    set_position(state$drag_start_position[[1L]] + delta[[1L]], state$drag_start_position[[2L]] + delta[[2L]])
  })
  tkbind(label, "<ButtonRelease-1>", function() {
    if (state$suppress_release) { state$suppress_release <- FALSE; state$dragging <- FALSE; return(invisible(NULL)) }
    if (!state$dragging) return(invisible(NULL))
    state$dragging <- FALSE
    if (state$drag_moved) { save_preferences(); state$next_action <- state$now() + 10 }
    else if (!state$prefs$paused) act(3L, 1.6)
  })
  tkbind(label, "<Double-Button-1>", function() {
    state$dragging <- FALSE
    state$suppress_release <- TRUE
    if (!state$prefs$paused) act(4L, 1.4)
  })
  tkbind(label, "<ButtonRelease-3>", function(X, Y) {
    stop_roaming()
    state$menu_open <- TRUE
    tcl("tk_popup", menu, as.integer(X), as.integer(Y))
  })
  tkbind(menu, "<Unmap>", function() { state$menu_open <- FALSE; state$next_action <- state$now() + 7 })
  tkbind(pet, "<Escape>", close_pet)
  tkwm.protocol(pet, "WM_DELETE_WINDOW", close_pet)

  frame_delay <- function() {
    if (state$row %in% c(1L, 2L, 4L)) return(0.1)
    if (state$row == 0L) return(if (state$column == 0L) 0.9 else 0.16)
    0.19
  }

  smoke_step <- function(now) {
    if (now < state$smoke_next) return(invisible(NULL))
    state$smoke_next <- now + 0.14
    step <- state$smoke_step
    state$smoke_step <- step + 1L
    if (step < 74L) {
      row <- which(step < cumsum(momo_frame_counts))[[1L]]
      offset <- if (row == 1L) 0L else sum(momo_frame_counts[seq_len(row - 1L)])
      state$row <- row - 1L; state$column <- step - offset
      draw_frame()
      state$smoke_cells <- unique(c(state$smoke_cells, state$row * 8L + state$column))
    } else if (step < 78L) {
      width <- unname(momo_sizes)[[step - 73L]]
      resize_pet(width)
      state$smoke_sizes <- c(state$smoke_sizes, width)
    } else {
      stopifnot(length(state$smoke_cells) == 74L, identical(state$smoke_sizes, unname(momo_sizes)))
      writeLines(c("PASS: 74 occupied sprite cells displayed in a real transparent Tk window.",
                   "PASS: all four display sizes rendered.",
                   paste("Frame updates:", state$frames_shown),
                   "PASS: desktop event loop completed without a callback error."),
                 file.path(report_dir, "render-test.txt"))
      close_pet()
    }
  }

  tick <- function() {
    if (state$closing) return(invisible(NULL))
    tryCatch({
      now <- state$now()
      seconds <- min(0.15, now - state$last_tick)
      state$last_tick <- now
      if (now >= state$next_request_check) {
        state$next_request_check <- now + 0.5
        if (file.exists(instance$exit_path)) {
          close_pet()
          return(invisible(NULL))
        }
        if (file.exists(instance$request_path)) {
          unlink(instance$request_path, recursive = FALSE)
          bring_home()
        }
      }
      if (smoke_test) smoke_step(now)
      else if (!state$prefs$paused && !state$dragging && !state$menu_open) {
        pointer <- as.integer(strsplit(tclvalue(tkwinfo("pointerxy", pet)), " ", fixed = TRUE)[[1L]])
        if (!identical(pointer, state$last_pointer)) { state$last_pointer <- pointer; state$pointer_changed <- now }
        if (now >= state$action_until && state$row > 0L && state$row < 9L) {
          stop_roaming(); state$row <- 0L; state$column <- 0L; state$next_frame <- now
        }
        if (now >= state$next_action) {
          state$next_action <- now + runif(1L, 12, 22)
          if (state$prefs$wander && runif(1L) < 0.65) {
            state$direction <- sample(c(-1L, 1L), 1L)
            state$row <- if (state$direction == 1L) 1L else 2L
            state$column <- 0L; state$roaming <- TRUE
            state$action_until <- now + runif(1L, 2.2, 4.2); state$next_frame <- now
          } else act(sample(c(3L, 6L, 7L, 8L), 1L), 1.9)
        }
        if (state$roaming) {
          desired_x <- state$x + state$direction * seconds * 42
          bounded <- momo_clamp(desired_x, state$y, state$width, state$height, state$screen_width, state$screen_height)
          if (abs(bounded[[1L]] - desired_x) > 0.1) {
            state$direction <- -state$direction
            state$row <- if (state$direction == 1L) 1L else 2L
          }
          set_position(bounded[[1L]], bounded[[2L]])
        }
        is_looking <- FALSE
        if (state$row == 0L || state$row >= 9L) {
          dx <- pointer[[1L]] - state$x - state$width / 2
          dy <- pointer[[2L]] - state$y - state$height / 3
          distance <- sqrt(dx^2 + dy^2)
          is_looking <- state$prefs$follow_cursor && now - state$pointer_changed < 1.8 &&
            distance > state$width / 3 && distance < state$width * 4
          if (is_looking) {
            look <- momo_direction(dx, dy)
            look_row <- 9L + look %/% 8L; look_column <- look %% 8L
            if (state$row != look_row || state$column != look_column) {
              state$row <- look_row; state$column <- look_column; draw_frame()
            }
          } else if (state$row >= 9L) { state$row <- 0L; state$column <- 0L; state$next_frame <- now }
        }
        if (!is_looking && now >= state$next_frame) {
          draw_frame()
          state$next_frame <- now + frame_delay()
          count <- if (state$row == 0L) 6L else momo_frame_counts[[state$row + 1L]]
          state$column <- (state$column + 1L) %% count
        }
      }
    }, error = function(error) {
      writeLines(conditionMessage(error), file.path(report_dir, "last-error.txt"))
      close_pet()
      stop(conditionMessage(error), call. = FALSE)
    })
    if (!state$closing) state$timer_id <- tcl("after", 40L, tick)
    invisible(NULL)
  }

  resize_pet(state$width)
  tkwm.deiconify(pet)
  tkraise(pet)
  tcl("update", "idletasks")
  writeLines(c(paste("PID:", Sys.getpid()),
               paste("Mapped:", tclvalue(tkwinfo("ismapped", pet))),
               paste("Viewable:", tclvalue(tkwinfo("viewable", pet))),
               paste("Geometry:", tclvalue(tkwm.geometry(pet))),
               paste("Transparent color:", tclvalue(tcl("wm", "attributes", pet, "-transparentcolor")))),
             file.path(report_dir, "last-window-state.txt"))
  saveRDS(instance$record, file.path(state_dir, "ready.rds"))
  state$timer_id <- tcl("after", 40L, tick)
  on.exit({
    close_pet()
    try(tcl("image", "delete", state$atlas), silent = TRUE)
    try(tcl("image", "delete", state$display), silent = TRUE)
  }, add = TRUE)
  tkwait.window(pet)
  invisible(NULL)
}

momo_main <- function(app_dir, args = character()) {
  momo_ensure_directory(momo_runtime_paths()$reports)
  if ("--self-test" %in% args) momo_self_test(app_dir)
  else momo_run(app_dir, smoke_test = "--smoke-test" %in% args)
}
