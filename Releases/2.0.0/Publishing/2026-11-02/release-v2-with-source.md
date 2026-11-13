MOMO and MIMI Lite 2.0.0 are small native Windows desktop pets. These packages replace the older portable editions that bundled R.

| Download | ZIP size |
| --- | --- |
| [MOMO-Lite-2.0.0-windows-x64.zip](https://github.com/shanlong-who/MOMO/releases/download/v2.0.0/MOMO-Lite-2.0.0-windows-x64.zip) | 6.62 MB |
| [MIMI-Lite-2.0.0-windows-x64.zip](https://github.com/shanlong-who/MOMO/releases/download/v2.0.0/MIMI-Lite-2.0.0-windows-x64.zip) | 6.50 MB |

Extract the ZIP and double-click **MOMO.exe** or **MIMI.exe**. Each EXE contains its artwork and icon and can be moved on its own. Both cats can run together. Windows 10/11 on Intel or AMD x64 is the target platform. No R, RStudio, separately installed .NET runtime, account or internet connection is needed.

### Changes

- Packages are about **92% smaller** than the previous R-bundled downloads.
- MOMO's collar and pendant have been removed.
- MIMI has clearer fur, eyes and tabby markings.
- Complete silhouettes are extracted and aligned before animation packing. Transparent margins prevent clipped paws or ears and fragments appearing in neighboring frames.
- Dragging, hello, jumping, playing, stretching, resting, wandering, cursor tracking, pause, always on top and four sizes are retained.
- Each cat saves its own preferences under `%LOCALAPPDATA%\DesktopPetsLite`.

### Validation

The final packages passed local Windows validation: 148 frames at four sizes (592 rendered-frame checks), full transparency and empty frame borders, real desktop windows, actions and settings, repeated launches, concurrent cats, independent exits, preference recovery and relocation into paths containing spaces, Chinese characters, `&` and `%`. Each packaged EXE matches the tested build's SHA-256. Tests used invalid R paths and unusable network proxies; the host network was not physically disconnected.

See **SHA256SUMS.txt** for the two ZIP checksums and **RELEASE-VALIDATION.txt** for the test results. These are local validation results; the older R-edition CI run does not validate the new native binaries. The EXEs are unsigned.

Use the two named ZIP assets for the native pets. The [native source, artwork, build scripts and tests](https://github.com/shanlong-who/MOMO/tree/6f4f2b723c8e54532765a4f35fe4a17be2ccf407/Releases/2.0.0/Source) are now available, with [build and packaging instructions](https://github.com/shanlong-who/MOMO/blob/6f4f2b723c8e54532765a4f35fe4a17be2ccf407/Releases/2.0.0/Source/README.md). The organized repository has four product folders: MOMO-GPT, MOMO-Offline, MIMI-Offline and Releases. Older editions remain in Git history; no Archive folder is required.

The v2.0.0 tag is unchanged. Its automatic **Source code** downloads reflect the repository at the original publication date, before the native source was synchronized. Use the source link above for the complete native edition. Code and generated artwork retain the MIT License; compiler runtime notices are included in each package.

