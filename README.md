# MOMO & MIMI

Two small Windows desktop cats, made just for fun. **Lite 2.0.0** runs without
R, RStudio, a separately installed .NET runtime or an internet connection.

![MOMO and MIMI](Releases/2.0.0/MOMO-MIMI-preview.png)

## Download and run

For Windows 10/11 on Intel or AMD x64:

| Pet | Download | ZIP size |
| --- | --- | --- |
| MOMO | [MOMO-Lite-2.0.0-windows-x64.zip](https://github.com/shanlong-who/MOMO/releases/download/v2.0.0/MOMO-Lite-2.0.0-windows-x64.zip) | 6.62 MB |
| MIMI | [MIMI-Lite-2.0.0-windows-x64.zip](https://github.com/shanlong-who/MOMO/releases/download/v2.0.0/MIMI-Lite-2.0.0-windows-x64.zip) | 6.50 MB |

Extract the ZIP and double-click **MOMO.exe** or **MIMI.exe**. Each EXE contains
its artwork and icon and can be moved on its own. Both cats can run together.
The packages are about 92% smaller than the previous R-bundled downloads.

MOMO has no collar or pendant. MIMI has clearer fur, eyes and tabby markings.
Complete silhouettes and transparent margins prevent clipped paws or ears and
fragments from neighboring animation frames. The EXEs are unsigned.

Drag to move, click to say hello, double-click to jump, and right-click for
actions, sizes, preferences or exit. Opening the same EXE again brings that
cat home. Settings are separate under `%LOCALAPPDATA%\DesktopPetsLite\MOMO`
and `%LOCALAPPDATA%\DesktopPetsLite\MIMI`.

## Project folders

The current project has four product folders:

| Folder | Contents |
| --- | --- |
| [MOMO-GPT](MOMO-GPT/README.md) | Original chat-app pet package; hosted by the chat application |
| [MOMO-Offline](MOMO-Offline/README.md) | Current standalone MOMO executable, instructions and license notices |
| [MIMI-Offline](MIMI-Offline/README.md) | Current standalone MIMI executable, instructions and license notices |
| [Releases](Releases/README.md) | Release ZIPs, shared native source, artwork, checksums and publishing records |

```text
MOMO-GPT/
MOMO-Offline/
  MOMO.exe
MIMI-Offline/
  MIMI.exe
Releases/
  2.0.0/
    MOMO-Lite-2.0.0-windows-x64.zip
    MIMI-Lite-2.0.0-windows-x64.zip
    Source/
      src/
      scripts/
      tests/
      assets/aligned/
      artwork/remastered/
```

Old installers, duplicate downloads and trial builds are not part of the
current project. The [v1.0.0 source](https://github.com/shanlong-who/MOMO/tree/v1.0.0)
and Git history retain the older R editions and their portable build tools.
No local Archive folder is needed to run, build, test or package Lite 2.0.0.

## Source and validation

The current application uses C++17, Win32 and Windows GDI+.
[Source and build instructions](Releases/2.0.0/Source/README.md) cover both cats.
R is used for development scripts only; it is not required by the finished EXEs.
The source includes the final atlases, icons, artwork, tests and packaging script.

The [release validation](Releases/2.0.0/RELEASE-VALIDATION.txt) covers all 148
animation frames at four sizes, native windows, actions, settings, simultaneous
cats, repeated launches and relocated executables. The GitHub Windows workflow
checks the committed ZIP/EXE checksums and runs their native rendering tests.
It does not replace the full local source build and application test suite.

Code and generated artwork use the [MIT License](LICENSE). Each package includes
the compiler runtime notices and applicable license texts.
