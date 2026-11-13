library(processx)
library(digest)

toolchain.dir <- "D:/R/rtools45/x86_64-w64-mingw32.static.posix/bin"
Sys.setenv(PATH = paste(toolchain.dir, Sys.getenv("PATH"), sep = .Platform$path.sep))
root.dir <- normalizePath(".", winslash = "/")
dir.create("../Dragon-Offline", recursive = TRUE, showWarnings = FALSE)
output.dir <- normalizePath("../Dragon-Offline", winslash = "/")
resource.path <- file.path(root.dir, "assets/dragon.rc")
resource.object <- file.path(root.dir, "assets/dragon-resources.o")
resource.text <- c("#include <windows.h>",
  sprintf('1 ICON "%s"', file.path(root.dir, "assets/dragon.ico")),
  sprintf('101 RCDATA "%s"', file.path(root.dir, "assets/spritesheet.png")),
  sprintf('1 RT_MANIFEST "%s"', file.path(root.dir, "src/pet.manifest")),
  '1 VERSIONINFO', 'FILEVERSION 2,0,0,0', 'PRODUCTVERSION 2,0,0,0',
  'FILEOS VOS_NT_WINDOWS32', 'FILETYPE VFT_APP', 'BEGIN',
  ' BLOCK "StringFileInfo" BEGIN', '  BLOCK "040904b0" BEGIN',
  '   VALUE "FileDescription", "Dragon Offline - Native Desktop Companion"',
  '   VALUE "ProductName", "Dragon Offline"',
  '   VALUE "FileVersion", "2.0.0"', '   VALUE "ProductVersion", "2.0.0"',
  '   VALUE "LegalCopyright", "Copyright (c) 2026 Shanlong Ding"',
  '  END', ' END', ' BLOCK "VarFileInfo" BEGIN',
  '  VALUE "Translation", 0x0409, 1200', ' END', 'END')
writeLines(resource.text, resource.path)
build.log <- character()
run_build <- function(command, arguments) {
  result <- run(command, arguments, error_on_status = FALSE, windows_hide_window = TRUE)
  build.log <<- c(build.log, paste(basename(command), paste(arguments, collapse = " ")),
                  result$stdout, result$stderr)
  writeLines(build.log, "qa/BUILD-LOG.txt")
  if (result$status != 0L) stop(result$stderr)
  result
}
run_build(file.path(toolchain.dir, "windres.exe"), c("--codepage=65001", "-i", resource.path, "-o", resource.object))
exe.path <- file.path(output.dir, "Dragon-Offline.exe")
run_build(file.path(toolchain.dir, "g++.exe"), c("-std=c++17", "-Os", "-Wall", "-Wextra",
  "-Wno-cast-function-type", "-municode", "-mwindows", "-static", "-s", "-Wl,--no-insert-timestamp",
  "src/pet.cpp", resource.object, "-o", exe.path, "-lgdiplus", "-lole32", "-lshell32", "-luser32", "-lgdi32"))
imports <- run_build(file.path(toolchain.dir, "objdump.exe"), c("-p", exe.path))$stdout
import.lines <- grep("DLL Name:", strsplit(imports, "\n", fixed = TRUE)[[1]], value = TRUE)
import.names <- trimws(sub(".*DLL Name:", "", import.lines))
allowed <- c("advapi32.dll", "comdlg32.dll", "gdi32.dll", "gdiplus.dll", "kernel32.dll", "ole32.dll",
             "oleaut32.dll", "shell32.dll", "user32.dll", "ucrtbase.dll", "msvcrt.dll")
stopifnot(all(tolower(import.names) %in% allowed | startsWith(tolower(import.names), "api-ms-win-crt-")))
writeLines(import.names, "qa/SYSTEM-DLLS.txt")
sha <- digest(readBin(exe.path, "raw", file.info(exe.path)$size), algo = "sha256", serialize = FALSE)
writeLines(paste(sha, basename(exe.path), sep = "  "), file.path(output.dir, "SHA256SUMS.txt"))
cat(sprintf("Built %s: %.2f MiB; Windows system DLLs only.\n", basename(exe.path), file.info(exe.path)$size / 1024^2))
