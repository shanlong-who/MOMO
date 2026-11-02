library(processx)
library(digest)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("Usage: Rscript build.R TOOLCHAIN_BIN ASSET_DIR NEW_BUILD_DIR")
toolchain.dir <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
asset.dir <- normalizePath(args[[2]], winslash = "/", mustWork = TRUE)
output.dir <- args[[3]]
stopifnot(!dir.exists(output.dir))
dir.create(output.dir, recursive = TRUE)
output.dir <- normalizePath(output.dir, winslash = "/", mustWork = TRUE)
script.path <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
project.dir <- dirname(dirname(normalizePath(script.path, winslash = "/")))
compiler <- file.path(toolchain.dir, "g++.exe")
resource.compiler <- file.path(toolchain.dir, "windres.exe")
stopifnot(file.exists(compiler), file.exists(resource.compiler))
Sys.setenv(PATH = paste(toolchain.dir, Sys.getenv("PATH"), sep = .Platform$path.sep))
build.log <- character()

run_build <- function(command, arguments) {
  result <- run(command, arguments, error_on_status = FALSE, windows_hide_window = TRUE)
  build.log <<- c(build.log, paste(basename(command), paste(arguments, collapse = " ")),
                 result$stdout, result$stderr)
  writeLines(build.log, file.path(output.dir, "BUILD-LOG.txt"))
  if (result$status != 0L) stop(result$stderr)
  invisible(result)
}

for (pet in c("MOMO", "MIMI")) {
  stem <- tolower(pet)
  resource.path <- file.path(output.dir, paste0(stem, ".rc"))
  resource.object <- file.path(output.dir, paste0(stem, "-resources.o"))
  resource.text <- c(
    "#include <windows.h>",
    sprintf('1 ICON "%s"', file.path(asset.dir, paste0(stem, ".ico"))),
    sprintf('101 RCDATA "%s"', file.path(asset.dir, paste0(stem, "-atlas.png"))),
    sprintf('1 RT_MANIFEST "%s"', file.path(project.dir, "src", "pet.manifest")),
    '1 VERSIONINFO', 'FILEVERSION 2,0,0,0', 'PRODUCTVERSION 2,0,0,0',
    'FILEOS VOS_NT_WINDOWS32', 'FILETYPE VFT_APP', 'BEGIN',
    ' BLOCK "StringFileInfo" BEGIN', '  BLOCK "040904b0" BEGIN',
    sprintf('   VALUE "FileDescription", "%s Lite - Native Desktop Pet"', pet),
    sprintf('   VALUE "ProductName", "%s Lite"', pet),
    '   VALUE "FileVersion", "2.0.0"', '   VALUE "ProductVersion", "2.0.0"',
    '   VALUE "LegalCopyright", "Copyright (c) 2026 Shanlong Ding"',
    '  END', ' END', ' BLOCK "VarFileInfo" BEGIN',
    '  VALUE "Translation", 0x0409, 1200', ' END', 'END')
  writeLines(resource.text, resource.path, useBytes = TRUE)
  run_build(resource.compiler, c("--codepage=65001", "-i", resource.path, "-o", resource.object))
  exe.path <- file.path(output.dir, paste0(pet, ".exe"))
  flags <- c("-std=c++17", "-Os", "-Wall", "-Wextra", "-Wno-cast-function-type",
             "-municode", "-mwindows", "-static", "-s", "-Wl,--no-insert-timestamp")
  if (pet == "MIMI") flags <- c(flags, "-DMIMI")
  run_build(compiler, c(flags, file.path(project.dir, "src", "pet.cpp"), resource.object,
                       "-o", exe.path, "-lgdiplus", "-lole32", "-lshell32", "-luser32", "-lgdi32"))
  imports <- run_build(file.path(toolchain.dir, "objdump.exe"), c("-p", exe.path))$stdout
  import.lines <- grep("DLL Name:", strsplit(imports, "\n", fixed = TRUE)[[1]], value = TRUE)
  import.names <- trimws(sub(".*DLL Name:", "", import.lines))
  allowed <- c("advapi32.dll", "comdlg32.dll", "gdi32.dll", "gdiplus.dll", "kernel32.dll",
               "ole32.dll", "oleaut32.dll", "shell32.dll", "user32.dll", "ucrtbase.dll", "msvcrt.dll")
  stopifnot(all(tolower(import.names) %in% allowed | startsWith(tolower(import.names), "api-ms-win-crt-")))
  writeLines(import.names, file.path(output.dir, paste0(pet, "-SYSTEM-DLLS.txt")))
  cat(sprintf("%s.exe: %.2f MiB; only Windows system DLL imports.\n", pet, file.info(exe.path)$size / 1024^2))
}
exes <- file.path(output.dir, paste0(c("MOMO", "MIMI"), ".exe"))
checksums <- vapply(exes, function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  digest(bytes, algo = "sha256", serialize = FALSE)
}, character(1))
writeLines(paste(checksums, basename(exes), sep = "  "), file.path(output.dir, "SHA256SUMS.txt"))
