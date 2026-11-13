# Companion releases

The current collection release is **2.1.0**, with GPT and Offline ZIPs for
MOMO, MIMI and Dragon. The native applications retain internal version 2.0.0.

- [Download the combined GitHub Release](https://github.com/shanlong-who/MOMO/releases/tag/v2.1.0)
- [Six-package download index](2.1.0/README.md)
- [Combined checksums](2.1.0/SHA256SUMS.txt)
- [Distribution validation](2.1.0/RELEASE-VALIDATION.txt)

## Earlier MOMO and MIMI Lite release

**Lite 2.0.0** was published on 2026-11-01. Its files are retained unchanged.

- [MOMO release ZIP](2.0.0/MOMO-Lite-2.0.0-windows-x64.zip)
- [MIMI release ZIP](2.0.0/MIMI-Lite-2.0.0-windows-x64.zip)
- [Release checksums](2.0.0/SHA256SUMS.txt)
- [Validation results](2.0.0/RELEASE-VALIDATION.txt)
- [Shared source and artwork](2.0.0/Source/README.md)
- [Published GitHub release](https://github.com/shanlong-who/MOMO/releases/tag/v2.0.0)

Both Windows applications run without R, .NET, installation or an internet
connection. Each EXE contains its artwork and icon.

## Project folders

| Folder | Purpose |
| --- | --- |
| `../Dragon-GPT` | Dragon 2.0 package for the desktop chat application |
| `../Dragon-Offline` | Standalone Dragon 2.0 application |
| `../MOMO-GPT` | Collar-free MOMO package for the desktop chat application |
| `../MOMO-Offline` | Current standalone MOMO application; run `MOMO.exe` |
| `../MIMI-GPT` | MIMI package for the desktop chat application |
| `../MIMI-Offline` | Current standalone MIMI application; run `MIMI.exe` |
| `Releases` | Current release ZIPs, checksums, source, artwork and publishing records |
| `../archive` | Original packages, previous editions, source and verification records |

The project was reorganized on 2026-11-13 to retain only these eight top-level
folders. The published release ZIPs and active EXEs retain their original
checksums. Temporary builds and duplicate extraction checks were removed;
unique supporting files and original packages are preserved in `archive`.
The [earlier public source](https://github.com/shanlong-who/MOMO/tree/v1.0.0)
remains available in GitHub history. Current source can be built and packaged
without those old files. Dragon's current source ZIP and validation records
are in [the supporting-file archive](../archive/supporting-files-2026-11-13/).

Application preferences remain in `%LOCALAPPDATA%\DesktopPetsLite\MOMO` and
`%LOCALAPPDATA%\DesktopPetsLite\MIMI`, independently of the project folder.
