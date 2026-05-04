# Codex Pet Screen Sounds

Small native workaround tool that watches the Codex desktop pet pixels and plays a sound when the pet changes visually. It is intentionally simple: capture a tiny 40x32 bottom-left rectangle offset 32 px from the left edge and 64 px from the bottom edge, compare pixels once per second, and ring when anything changes.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Win32 Version

- Download: [codex_pet_watch-win32-x64.exe](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.1.0/codex_pet_watch-win32-x64.exe)
- Release notes: [v0.1.0](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.1.0)
- Source and build notes: [codex-pet-watch/win32](codex-pet-watch/win32)

The Windows app launches without args, lives in the system tray, watches a 40x32 DIP rectangle near the bottom-left of the screen, offset 32 px from the left edge and 64 px from the bottom edge, and plays `C:\Windows\Media\ringout.wav` when the watched pixels change. Right-click the tray icon and choose `Exit` to stop it.

The release executable is unsigned, so Windows SmartScreen may show an "unrecognized app" warning the first time it runs. Use `More info` / `Run anyway` only if you trust this repository and release asset.

## Project Layout

- [codex-pet-watch](codex-pet-watch) - shared project notes
- [codex-pet-watch/win32](codex-pet-watch/win32) - working Windows 10/11 systray app
- [codex-pet-watch/macosx](codex-pet-watch/macosx) - Objective-C/AppKit macOS menu-bar app source
- [codex-pet-watch/shared/sounds](codex-pet-watch/shared/sounds) - shared default sound asset
