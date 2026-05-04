# codex-pet-watch macOS

Native macOS menu-bar version of the pet pixel watcher.

**Detection rectangle:** `SIZE=24x24`, `X=56 px` from the left edge, `Y=72 px` from the bottom edge.

This mirrors the Win32 workaround:

- runs as a menu-bar app with no Dock icon
- shows a small `C` status icon with a green bottom-left square
- watches a 24x24 physical-pixel rectangle near the bottom-left of the main display, offset 56 px from the left edge and 72 px from the bottom edge
- captures that rectangle once per second with CoreGraphics
- compares bitmap bytes against the previous capture
- plays a sound when any pixel changes
- has a menu with `Exit`

## Platform

Designed as a small Objective-C/AppKit app. The intended minimum target is macOS High Sierra 10.13, while Monterey also works and is easier to develop on.

Newer macOS versions require Screen Recording permission for pixel capture:

```text
System Settings -> Privacy & Security -> Screen Recording
```

On older macOS:

```text
System Preferences -> Security & Privacy -> Privacy -> Screen Recording
```

If capture is blocked, the app can run but will not see the real screen pixels.

On the first launch on a Mac, macOS may ask for Screen Recording permission. Choose the option to allow/configure it later, not `Quit`, then enable `CodexPetWatch` in Screen Recording settings and relaunch the app. After the app is allowed once, the ad-hoc signing step in `build.sh` lets that permission survive normal rebuilds.

## Sound File

The build script copies the shared default sound:

```text
../shared/sounds/ringout.wav
```

into:

```text
build/CodexPetWatch.app/Contents/MacOS/ringout.wav
```

You can replace that executable-adjacent `.wav` after building, replace the shared file before building, or pass an explicit sound path when launching the app binary directly. Relative sound paths are resolved against `Contents/MacOS`, the same folder as the `CodexPetWatch` executable.

## Build

Install Xcode Command Line Tools:

```sh
xcode-select --install
```

Then from this folder:

```sh
chmod +x build.sh
./build.sh
```

Output:

```text
build/CodexPetWatch.app
```

The build script ad-hoc signs the app:

```sh
codesign --force --deep --sign - build/CodexPetWatch.app
```

Keep this signing step in place. It helps macOS keep Screen Recording permission across rebuilds of the local app.

## Run

```sh
open build/CodexPetWatch.app
```

To run with options:

```sh
build/CodexPetWatch.app/Contents/MacOS/CodexPetWatch [sound.wav] [width height] [options]
```

Options:

```text
--size=WxH       Watch rectangle size in physical pixels. Default: 24x24
--poll-ms=N      Capture interval in milliseconds. Default: 1000
--help           Show help
```

Examples:

```sh
open build/CodexPetWatch.app
build/CodexPetWatch.app/Contents/MacOS/CodexPetWatch --size=24x24
build/CodexPetWatch.app/Contents/MacOS/CodexPetWatch /path/to/custom.wav --poll-ms=1000
```

## Notes

- This watches pixels, not Codex state. Pet animation can produce multiple rings.
- The app anchors near the bottom-left of the main display at launch, offset 56 physical pixels from the left edge and 72 physical pixels from the bottom edge. On Retina displays, the green overlay converts those pixel dimensions and offsets to AppKit screen points so it matches the captured pixels.
- macOS menu-bar apps normally show their menu on click; choose `Exit` to quit.
