# codex-pet-watch

Tiny native pet pixel watcher applets.

The idea is intentionally simple: watch a small 24x24 bottom-left rectangle where the Codex pet sits, offset 56 px from the left edge and 72 px from the bottom edge, compare captured pixels, and play a sound when the pet changes visually.

Demo video: [Codex pet sounds watcher](https://www.youtube.com/watch?v=YI3Urzh145c)

## Platforms

- `win32/` - working Windows 10/11 systray app, implemented with Win32/GDI `BitBlt`
- `macosx/` - Objective-C/AppKit macOS menu-bar app source
- `shared/sounds/` - shared default sound asset

The Windows version is the current working workaround. It launches without args, watches a 24x24 DIP rectangle offset 56 px from the left edge and 72 px from the bottom edge, plays `C:\Windows\Media\ringout.wav`, and exits from the tray menu.

The macOS version is source-prepared for local build on a Mac. Its build script bundles `shared/sounds/ringout.wav` into the `.app`.

## Windows Download Note

The release executable is currently unsigned. Windows SmartScreen may show an "unrecognized app" warning the first time you run the downloaded `.exe`. This is expected for this small local-build tool; choose `More info` / `Run anyway` if you trust this repository and release asset. Later launches are usually normal after Windows has seen the file once.
