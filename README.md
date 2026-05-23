# Codex Pet Screen Sounds

Small native workaround tool that watches the Codex desktop pet pixels and plays a sound when the pet changes visually. The Codex pet is parked near the bottom-left corner of the screen; this tool captures a tiny 16x16 rectangle in the pet sprite's upper-right area, offset 100 px from the screen's left edge and 116 px from the screen's bottom edge, compares pixels once per second, and rings when anything changes.

**Detection rectangle:** upper-right area of the bottom-left parked pet sprite; `SIZE=16x16`, `X=100 px` from the screen's left edge, `Y=116 px` from the screen's bottom edge.

The 16x16 rectangle keeps the same upper-right target area of the pet sprite while trimming the busier animated pixels from the old lower-left part of the sprite, so the default is usable on both macOS and Win32.

On macOS, the Codex pet/activity overlay can still ring when it shifts or updates while an agent is waiting for user input. That is expected and useful: it acts as a small "interaction needed" signal even when the main pet sprite is otherwise stable.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Windows

For most users, use the release binary. It does not require build tools:

- Download x64: [codex_pet_watch-win32-x64-v0.50.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.50/codex_pet_watch-win32-x64-v0.50.zip)
- Release notes: [v0.50](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.50)

The Windows app launches without args, lives in the system tray, watches a 16x16 DIP rectangle in the upper-right area of the bottom-left parked pet sprite, offset 100 px from the screen's left edge and 116 px from the screen's bottom edge, and plays the embedded default `ringout.wav` when the watched pixels change. Right-click the tray icon and choose `Exit` to stop it.

The release executable is unsigned, so Windows SmartScreen may show an "unrecognized app" warning the first time it runs. Use `More info` / `Run anyway` only if you trust this repository and release asset.

### Build On Windows

Source and build notes: [codex-pet-watch/win32](codex-pet-watch/win32)

From a fresh Windows clone, install/check tools, build, and launch from the repository root:

```bat
get-tools.cmd
build.cmd
run.cmd
```

To inspect the tool install command without changing the machine:

```bat
get-tools.cmd -DryRun
```

The root `.cmd` launchers call the PowerShell implementations in `tools\`.
`get-tools.cmd` uses `winget` to install Visual Studio 2022 Build Tools with
the C++ workload and Windows SDK. It does not install the full Visual Studio
IDE. `build.cmd` finds Visual Studio Build Tools, loads the MSVC environment,
and builds the Windows x64 app. `run.cmd` launches the rebuilt applet.

If `winget` is missing, install App Installer from Microsoft, or install Visual
Studio 2022 Build Tools manually with the `Desktop development with C++`
workload.

Manual fallback links:

- App Installer / winget: [apps.microsoft.com/detail/9nblggh4nns1](https://apps.microsoft.com/detail/9nblggh4nns1)
- Visual Studio 2022 Build Tools: [visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022)

## macOS Version

- Download: [codex_pet_watch-macosx-x64-v0.50.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.50/codex_pet_watch-macosx-x64-v0.50.zip)
- Release notes: [v0.50](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.50)
- Source and build notes: [codex-pet-watch/macosx](codex-pet-watch/macosx)

The macOS app is distributed as a zip containing `CodexPetWatch.app`. The app bundle includes `Contents/MacOS/CodexPetWatch` and the shared `ringout.wav` next to the executable. The app is ad-hoc signed and macOS will require Screen Recording permission on first launch.

### Build On macOS

From a fresh Monterey-style macOS clone, install/check tools, build, and launch
from the repository root:

```sh
./get-tools.sh
./build.sh
./run.sh
```

To inspect the tool install steps without changing the machine:

```sh
./get-tools.sh --dry-run
```

The root `.sh` launchers call the shell implementations in `tools/`. The macOS
helper uses Apple Command Line Tools for `git`, `clang`, and SDKs, and installs
GitHub CLI from GitHub's official `.pkg` release if `gh` is missing. It
intentionally avoids Homebrew because older Monterey setups can be awkward when
Homebrew needs newer source-built dependencies.

If Apple Command Line Tools are missing, `./build.sh --install-missing` runs
the Homebrew-free macOS tool helper first.

## Project Layout

- [codex-pet-watch](codex-pet-watch) - shared project notes
- [codex-pet-watch/win32](codex-pet-watch/win32) - working Windows 10/11 systray app
- [codex-pet-watch/macosx](codex-pet-watch/macosx) - Objective-C/AppKit macOS menu-bar app source
- [codex-pet-watch/shared/sounds](codex-pet-watch/shared/sounds) - shared default sound asset
