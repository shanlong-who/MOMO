# Companion collection 2.1.0

This collection bundles the existing GPT and Offline packages for MOMO,
MIMI and Dragon. Native executable versions remain 2.0.0. All six ZIPs are
copied unchanged from their previously verified project packages.

The [GitHub Release](https://github.com/shanlong-who/MOMO/releases/tag/v2.1.0)
provides these downloads as individual attachments:

| Character | GPT package | Offline Windows x64 package |
| --- | --- | --- |
| MOMO | [momo-pet-v2.zip](momo-pet-v2.zip) | [MOMO-Lite-2.0.0-windows-x64.zip](MOMO-Lite-2.0.0-windows-x64.zip) |
| MIMI | [mimi-pet-v2.zip](mimi-pet-v2.zip) | [MIMI-Lite-2.0.0-windows-x64.zip](MIMI-Lite-2.0.0-windows-x64.zip) |
| Dragon | [dragon-pet-v2.zip](dragon-pet-v2.zip) | [Dragon-Offline-windows-x64.zip](Dragon-Offline-windows-x64.zip) |

[SHA256SUMS.txt](SHA256SUMS.txt) covers the six archives and
[RELEASE-VALIDATION.txt](RELEASE-VALIDATION.txt). The validation report records
extraction checks and confirms that packaged GPT files and native executables
match the approved project files.

[Release notes](RELEASE-NOTES.md) describe the contents and versioning.
`release-manifest.json` records the source, byte size and SHA-256 of every ZIP.
`prepare_release.R` reproduces the bundle and validation from the project root.
