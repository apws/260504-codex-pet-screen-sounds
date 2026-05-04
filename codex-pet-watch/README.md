# codex-pet-watch

Tiny native pet pixel watcher applets.

The idea is intentionally simple: watch a small bottom-left rectangle where the Codex pet sits, compare captured pixels, and play a sound when the pet changes visually.

## Platforms

- `win32/` - working Windows 10/11 systray app, implemented with Win32/GDI `BitBlt`
- `macosx/` - planned macOS menu-bar version

The Windows version is the current working workaround. It launches without args, watches an 80x80 DIP rectangle, plays `C:\Windows\Media\ringout.wav`, and exits from the tray menu.

## Windows Download Note

The release executable is currently unsigned. Windows SmartScreen may show an "unrecognized app" warning the first time you run the downloaded `.exe`. This is expected for this small local-build tool; choose `More info` / `Run anyway` if you trust this repository and release asset. Later launches are usually normal after Windows has seen the file once.
