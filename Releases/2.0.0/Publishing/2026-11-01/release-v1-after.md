**Superseded by [MOMO & MIMI Lite 2.0.0](https://github.com/shanlong-who/MOMO/releases/tag/v2.0.0).** The old R-bundled Windows ZIPs have been replaced by the new native downloads, which are about 92% smaller. Use the v2.0.0 release for current desktop pets.

This page keeps the historical v1.0.0 notes, checksums, test report and corresponding R/ps source archives. The download links in the historical notes below refer to the retired v1.0.0 ZIP assets.

---

MOMO and MIMI portable packages now include their own cat-icon launch entries.
Extract the complete ZIP, then double-click **Start MOMO.exe** or **Start MIMI.exe**.
The existing v1.0.0 download URLs and ZIP filenames are unchanged.

- [Download MOMO](https://github.com/shanlong-who/MOMO/releases/download/v1.0.0/MOMO-Portable-1.0.0-windows-x64.zip)
- [Download MIMI](https://github.com/shanlong-who/MOMO/releases/download/v1.0.0/MIMI-Portable-1.0.0-windows-x64.zip)

The icon entries locate the existing launcher from their own directory. They
contain the matching cat artwork and do not contain a creator's local shortcut
path. Keep the EXE, app, scripts and runtime together when moving the folder.
To add a desktop icon, create a Windows shortcut to the EXE in its extracted
folder. The original Start CMD, Exit CMD and Check CMD entries remain available.

The packages include clean R 4.6.1, Tcl/Tk 8.6.17 and ps 1.9.3. No R installation,
RStudio, account or internet connection is needed to run the cats. The small
Windows icon entry uses the .NET Framework supplied with Windows 10/11; the
cats and their animation logic still run in the included R runtime.

Supported desktop target: Windows 10/11, Intel or AMD x64. Both cats can run
together. Settings and logs use the Windows user profile, separately from
the original source editions. MOMO-ChatGPT, MOMO-Offline and MIMI-Offline remain
available in the repository.

The updated packages passed local validation and an independent
[GitHub Windows build and test run](https://github.com/shanlong-who/MOMO/actions/runs/39805115984). Validation includes the icons
displayed by Windows, both EXE and CMD entry points, all 74 frames at four sizes,
real transparent windows, repeated Start, concurrent cats, independent Exit,
relocation, Chinese and space-containing paths, shell characters, missing files,
and isolation from system R and user startup profiles. Runtime tests use
unusable network proxies; the host network is not physically disconnected.
Windows ARM, macOS, Linux and every managed-device security policy are not certified.

`SHA256SUMS.txt` and `PORTABLE-TEST-RESULTS.txt` describe the refreshed downloads.
The matching `R-4.6.1.tar.gz` and `ps_1.9.3.tar.gz` source archives remain attached.
Code and cat artwork are MIT licensed; bundled components retain their upstream
licenses. See THIRD-PARTY-NOTICES.txt inside each portable ZIP.

Package revision: **cat-icon-launcher-1** (2026-10-22).
Updated package source: [57eaf9a533056e416260065b6dd012e5d73d9c7e](https://github.com/shanlong-who/MOMO/tree/57eaf9a533056e416260065b6dd012e5d73d9c7e).
The original v1.0.0 Git tag is retained; GitHub's automatic Source code downloads
refer to that original tag and do not include this icon update or the R runtime.

