# Codex Pet Screen Sounds

Small native workaround tool that watches the Codex desktop pet pixels and plays a sound when the pet changes visually. It is intentionally simple: capture a tiny 16x16 bottom-left rectangle offset 64 px from the left edge and 80 px from the bottom edge, compare pixels once per second, and ring when anything changes.

**Detection rectangle:** `SIZE=16x16`, `X=64 px` from the left edge, `Y=80 px` from the bottom edge.

The 16x16 rectangle keeps the same top-right target area while trimming the busier animated pet pixels from the old bottom-left corner, so the default is usable on both macOS and Win32.

On macOS, the Codex pet/activity overlay can still ring when it shifts or updates while an agent is waiting for user input. That is expected and useful: it acts as a small "interaction needed" signal even when the main pet sprite is otherwise stable.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Win32 Version

- Download: [codex_pet_watch-win32-x64.exe](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.1.0/codex_pet_watch-win32-x64.exe)
- Release notes: [v0.1.0](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.1.0)
- Source and build notes: [codex-pet-watch/win32](codex-pet-watch/win32)

The Windows app launches without args, lives in the system tray, watches a 16x16 DIP rectangle near the bottom-left of the screen, offset 64 px from the left edge and 80 px from the bottom edge, and plays the bundled `ringout.wav` next to the executable when the watched pixels change. Right-click the tray icon and choose `Exit` to stop it.

The release executable is unsigned, so Windows SmartScreen may show an "unrecognized app" warning the first time it runs. Use `More info` / `Run anyway` only if you trust this repository and release asset.

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
