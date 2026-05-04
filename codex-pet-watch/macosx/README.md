# codex-pet-watch macOS

Planned native macOS version of the pet pixel watcher.

Expected shape:

- AppKit menu-bar app
- `Exit` menu item
- bottom-left 80x80 point watch rectangle by default
- CoreGraphics screen capture for the watched rectangle
- bitmap byte comparison once per second
- sound on pixel change

macOS notes:

- Newer macOS versions require Screen Recording permission for pixel capture.
- A local build should only need free Xcode Command Line Tools.
- This should be implemented as a separate native Swift/AppKit app rather than a port of the Win32 source.
