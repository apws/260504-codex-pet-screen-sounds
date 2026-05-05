# codex-pet-watch

Tiny native pet pixel watcher applets.

The idea is intentionally simple: watch a small 16x16 bottom-left rectangle where the Codex pet sits, offset 64 px from the left edge and 80 px from the bottom edge, compare captured pixels, and play a sound when the pet changes visually.

**Detection rectangle:** `SIZE=16x16`, `X=64 px` from the left edge, `Y=80 px` from the bottom edge.

The 16x16 rectangle keeps the same top-right target area while trimming the busier animated pet pixels from the old bottom-left corner, so the default is usable on both macOS and Win32.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Platforms

- `win32/` - working Windows 10/11 systray app, implemented with Win32/GDI `BitBlt`
- `macosx/` - Objective-C/AppKit macOS menu-bar app source
- `shared/sounds/` - shared default sound asset

The Windows version is the current working workaround. It launches without args, watches a 16x16 DIP rectangle offset 64 px from the left edge and 80 px from the bottom edge, plays the bundled `ringout.wav` next to the executable, and exits from the tray menu.

The macOS version is source-prepared for local build on a Mac. Its build script bundles `shared/sounds/ringout.wav` into the `.app`.

## macOS Download Note

The macOS release asset is [codex_pet_watch-macosx-x64-v0.30.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.30/codex_pet_watch-macosx-x64-v0.30.zip). It contains `CodexPetWatch.app`, including the app executable and bundled shared `ringout.wav` next to it in `Contents/MacOS`.

The app is ad-hoc signed. On first launch, choose the option to allow/configure Screen Recording permission later rather than quitting, then enable `CodexPetWatch` in Screen Recording settings and relaunch.

## Windows Download Note

The release executable is currently unsigned. Windows SmartScreen may show an "unrecognized app" warning the first time you run the downloaded `.exe`. This is expected for this small local-build tool; choose `More info` / `Run anyway` if you trust this repository and release asset. Later launches are usually normal after Windows has seen the file once.
