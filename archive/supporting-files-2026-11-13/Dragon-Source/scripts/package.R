library(zip)
library(digest)
library(jsonlite)

stopifnot(file.exists("../Dragon-Offline/Dragon-Offline.exe"),
          file.exists("../Dragon-Offline/TEST-RESULTS.txt"),
          read_json("../Dragon-GPT/dragon/validation.json")$ok,
          read_json("qa/direction-semantics.json")$cardinals_pass)
native <- readLines("../Dragon-Offline/TEST-RESULTS.txt")
sha256 <- function(path) digest(readBin(path, "raw", file.info(path)$size), algo = "sha256", serialize = FALSE)
stopifnot(length(native) >= 8, all(startsWith(native, "PASS:")))
file.copy("../Dragon-Offline/LICENSE", "../Dragon-GPT/dragon/LICENSE", overwrite = TRUE)
file.copy("artwork/PROMPTS.md", "../Dragon-GPT/dragon/GENERATION.md", overwrite = TRUE)
file.copy("../Dragon-GPT/README.md", "../Dragon-GPT/dragon/README.md", overwrite = TRUE)
file.copy("qa/direction-semantics.json", "../Dragon-GPT/dragon/direction-semantics.json", overwrite = TRUE)
file.copy("qa/look-continuity.json", "../Dragon-GPT/dragon/look-continuity.json", overwrite = TRUE)
file.copy("qa/visual-review.json", "../Dragon-GPT/dragon/visual-review.json", overwrite = TRUE)
release.dir <- normalizePath("..", winslash = "/")
zipr(file.path(release.dir, "Dragon-GPT/dragon-pet-v2.zip"), files = "dragon", root = "../Dragon-GPT", compression_level = 9)
zipr(file.path(release.dir, "Dragon-Offline-windows-x64.zip"), files = "Dragon-Offline", root = "..", compression_level = 9)
source.files <- c("README.md", "LICENSE", "THIRD-PARTY-NOTICES.txt", "licenses", "src", "scripts", "tests", "artwork",
                  "assets/spritesheet.png", "assets/dragon.ico", "assets/preview.png", "qa/atlas-validation.json",
                  "qa/direction-semantics.json", "qa/visual-review.json", "qa/look-continuity.json",
                  "qa/preview-timing.json", "qa/final-contact-sheet.png", "qa/final-frame-metrics.csv",
                  "qa/blind-cardinals.png", "qa/look-registration.csv", "qa/cardinal-check.png", "qa/look-first-check.png")
source.package.files <- c(file.path("Dragon-Source", source.files), "Dragon-GPT/README.md", "Dragon-GPT/dragon/pet.json",
                           "Dragon-Offline/README.md", "Dragon-Offline/LICENSE", "Dragon-Offline/THIRD-PARTY-NOTICES.txt",
                           "Dragon-Offline/licenses")
zipr(file.path(release.dir, "Dragon-Source.zip"), files = source.package.files, root = "..",
     mode = "mirror", compression_level = 9)
paths <- c("../Dragon-GPT/dragon-pet-v2.zip", "../Dragon-Offline-windows-x64.zip", "../Dragon-Source.zip")
checksums <- vapply(paths, sha256, character(1))
writeLines(paste(checksums, basename(paths), sep = "  "), "../Dragon-SHA256SUMS.txt")

verify.dir <- file.path("qa", paste0("package-", format(Sys.time(), "%Y%m%d-%H%M%S")))
dir.create(verify.dir)
unzip(paths[[1]], exdir = file.path(verify.dir, "gpt"))
unzip(paths[[2]], exdir = file.path(verify.dir, "offline"))
stopifnot(identical(sha256(file.path(verify.dir, "gpt/dragon/spritesheet.webp")),
                    sha256("../Dragon-GPT/dragon/spritesheet.webp")),
          identical(sha256(file.path(verify.dir, "offline/Dragon-Offline/Dragon-Offline.exe")),
                    sha256("../Dragon-Offline/Dragon-Offline.exe")))
writeLines(c("PASS: both delivery ZIPs extract and match tested original files by SHA-256.", native),
           "../Dragon-RELEASE-VALIDATION.txt")
print(data.frame(file = basename(paths), MiB = round(file.info(paths)$size / 1024^2, 2)))
