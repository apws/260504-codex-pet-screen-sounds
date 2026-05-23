# Codex Pet Screen Sounds

Small native workaround tool that watches the Codex desktop pet pixels and plays a sound when the pet changes visually. The Codex pet is parked near the bottom-left corner of the screen; this tool captures a tiny 16x16 rectangle in the pet sprite's upper-right area, offset 96 px from the screen's left edge and 120 px from the screen's bottom edge, compares pixels once per second, and rings when anything changes.

**Detection rectangle:** upper-right area of the bottom-left parked pet sprite; `SIZE=16x16`, `X=96 px` from the screen's left edge, `Y=120 px` from the screen's bottom edge.

The 16x16 rectangle keeps the same upper-right target area of the pet sprite while trimming the busier animated pixels from the old lower-left part of the sprite, so the default is usable on both macOS and Win32.

On macOS, the Codex pet/activity overlay can still ring when it shifts or updates while an agent is waiting for user input. That is expected and useful: it acts as a small "interaction needed" signal even when the main pet sprite is otherwise stable.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Windows

For most users, use the release binary. It does not require build tools:

- Download x64: [codex_pet_watch-win32-x64-v0.40.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.40/codex_pet_watch-win32-x64-v0.40.zip)
- Release notes: [v0.40](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.40)

The Windows app launches without args, lives in the system tray, watches a 16x16 DIP rectangle in the upper-right area of the bottom-left parked pet sprite, offset 96 px from the screen's left edge and 120 px from the screen's bottom edge, and plays the embedded default `ringout.wav` when the watched pixels change. Right-click the tray icon and choose `Exit` to stop it.

The release executable is unsigned, so Windows SmartScreen may show an "unrecognized app" warning the first time it runs. Use `More info` / `Run anyway` only if you trust this repository and release asset.

### Build On Windows

Source and build notes: [codex-pet-watch/win32](codex-pet-watch/win32)

From a fresh Windows clone:

```powershell
.\build.ps1
```

The build script finds Visual Studio Build Tools, loads the MSVC environment,
and builds the Windows x64 app. To launch the rebuilt applet:

```powershell
.\run.ps1
```

If the headless Microsoft C++ toolchain is missing, install it with:

```powershell
.\tools\get-tools.ps1
```

To inspect the install command without changing the machine:

```powershell
.\tools\get-tools.ps1 -DryRun
```

`get-tools.ps1` uses `winget` to install Visual Studio 2022 Build Tools with
the C++ workload and Windows SDK. It does not install the full Visual Studio
IDE. If `winget` is missing, install App Installer from Microsoft, or install
Visual Studio 2022 Build Tools manually with the `Desktop development with C++`
workload.

Manual fallback links:

- App Installer / winget: [apps.microsoft.com/detail/9nblggh4nns1](https://apps.microsoft.com/detail/9nblggh4nns1)
- Visual Studio 2022 Build Tools: [visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022)

## macOS Version

- Download: [codex_pet_watch-macosx-x64-v0.30.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.30/codex_pet_watch-macosx-x64-v0.30.zip)
- Release notes: [v0.30](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.30)
- Source and build notes: [codex-pet-watch/macosx](codex-pet-watch/macosx)

The macOS app is distributed as a zip containing `CodexPetWatch.app`. The app bundle includes `Contents/MacOS/CodexPetWatch` and the shared `ringout.wav` next to the executable. The app is ad-hoc signed and macOS will require Screen Recording permission on first launch.

## Project Layout

- [codex-pet-watch](codex-pet-watch) - shared project notes
- [codex-pet-watch/win32](codex-pet-watch/win32) - working Windows 10/11 systray app
- [codex-pet-watch/macosx](codex-pet-watch/macosx) - Objective-C/AppKit macOS menu-bar app source
- [codex-pet-watch/shared/sounds](codex-pet-watch/shared/sounds) - shared default sound asset
