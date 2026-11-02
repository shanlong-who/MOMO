# MOMO and MIMI releases

The current release is **Lite 2.0.0**, published on 2026-11-01.

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
| `../MOMO-GPT` | Original MOMO export for the chat application |
| `../MOMO-Offline` | Current standalone MOMO application; run `MOMO.exe` |
| `../MIMI-Offline` | Current standalone MIMI application; run `MIMI.exe` |
| `Releases` | Current release ZIPs, checksums, source, artwork and publishing records |

The project was organized on 2026-11-02. The published release ZIPs and active
EXEs retain their original checksums. The local Archive folder is no longer
needed: old installers, duplicate downloads and trial builds can be removed.
The [earlier public source](https://github.com/shanlong-who/MOMO/tree/v1.0.0)
remains available in GitHub history. Current source can be built and packaged
without those old files.

Application preferences remain in `%LOCALAPPDATA%\DesktopPetsLite\MOMO` and
`%LOCALAPPDATA%\DesktopPetsLite\MIMI`, independently of the project folder.
