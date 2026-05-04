# codex-pet-watch

Tiny native pet pixel watcher applets.

The idea is intentionally simple: watch a small bottom-left rectangle where the Codex pet sits, compare captured pixels, and play a sound when the pet changes visually.

## Platforms

- `win32/` - working Windows 10/11 systray app, implemented with Win32/GDI `BitBlt`
- `macosx/` - planned macOS menu-bar version

The Windows version is the current working workaround. It launches without args, watches an 80x80 DIP rectangle, plays `C:\Windows\Media\ringout.wav`, and exits from the tray menu.
