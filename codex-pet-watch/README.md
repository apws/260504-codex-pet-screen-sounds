# codex-pet-watch

Tiny native pet pixel watcher applets.

The idea is intentionally simple: the Codex pet sits near the bottom-left corner of the screen, and the watcher observes a small 16x16 rectangle in the pet sprite's upper-right area, offset 100 px from the screen's left edge and 116 px from the screen's bottom edge. It compares captured pixels and plays a sound when the pet changes visually.

**Detection rectangle:** upper-right area of the bottom-left parked pet sprite; `SIZE=16x16`, `X=100 px` from the screen's left edge, `Y=116 px` from the screen's bottom edge.

The 16x16 rectangle keeps the same upper-right target area of the pet sprite while trimming the busier animated pixels from the old lower-left part of the sprite, so the default is usable on both macOS and Win32.

On macOS, the Codex pet/activity overlay can still ring when it shifts or updates while an agent is waiting for user input. That is expected and useful: it acts as a small "interaction needed" signal even when the main pet sprite is otherwise stable.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Platforms

- `win32/` - working Windows 10/11 systray app, implemented with Win32/GDI `BitBlt`
- `macosx/` - Objective-C/AppKit macOS menu-bar app source
- `shared/sounds/` - shared default sound asset

The Windows version is the current working workaround. It launches without args, watches a 16x16 DIP rectangle in the upper-right area of the bottom-left parked pet sprite, offset 100 px from the screen's left edge and 116 px from the screen's bottom edge, plays the embedded default `ringout.wav` resource, and exits from the tray menu.

The macOS version is source-prepared for local build on a Mac. Its build script bundles `shared/sounds/ringout.wav` into the `.app` resources folder.

## macOS Download Note

The macOS release asset is [codex_pet_watch-macosx-x64-v0.50.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.50/codex_pet_watch-macosx-x64-v0.50.zip). It contains `CodexPetWatch.app`, including the app executable and bundled shared `ringout.wav` in `Contents/Resources`.

The app is ad-hoc signed. On first launch, choose the option to allow/configure Screen Recording permission later rather than quitting, then enable `CodexPetWatch` in Screen Recording settings and relaunch.

## Windows Download Note

Latest Win32 release assets:

- x64: [codex_pet_watch-win32-x64-v0.50.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.50/codex_pet_watch-win32-x64-v0.50.zip)
- Release notes: [v0.50](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.50)

The release executable is currently unsigned. Windows SmartScreen may show an "unrecognized app" warning the first time you run the downloaded `.exe`. This is expected for this small local-build tool; choose `More info` / `Run anyway` if you trust this repository and release asset. Later launches are usually normal after Windows has seen the file once.
