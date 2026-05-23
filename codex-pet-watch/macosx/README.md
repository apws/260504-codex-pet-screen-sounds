# codex-pet-watch macOS

Native macOS menu-bar version of the pet pixel watcher.

**Detection rectangle:** upper-right area of the bottom-left parked pet sprite; `SIZE=16x16`, `X=100 px` from the screen's left edge, `Y=116 px` from the screen's bottom edge.

The Codex pet is parked near the bottom-left corner of the screen. This keeps the same upper-right target area of the pet sprite while trimming the busier animated pixels from the old lower-left part of the sprite; the default matches the Win32 watcher.

This mirrors the Win32 workaround:

- runs as a menu-bar app with no Dock icon
- shows a small `C` status icon with a green marker for the watched pet area
- watches a 16x16 physical-pixel rectangle in the upper-right area of the bottom-left parked pet sprite, offset 100 px from the screen's left edge and 116 px from the screen's bottom edge
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

If a rebuilt app launches but does not ring even though the watched pixels are changing, refresh the Screen Recording entry: remove `CodexPetWatch` with the `-` button, add the rebuilt `build/CodexPetWatch.app` again with the `+` button, enable it, then quit and relaunch the app.

## Sound File

The build script copies the shared default sound:

```text
../shared/sounds/ringout.wav
```

into:

```text
build/CodexPetWatch.app/Contents/Resources/ringout.wav
```

You can replace that bundle resource after building, replace the shared file before building, or pass an explicit sound path when launching the app binary directly. Relative custom sound paths are resolved against `Contents/MacOS`, the same folder as the `CodexPetWatch` executable.

## Build

From the repository root, install/check tools, build, and launch:

```sh
./get-tools.sh
./build.sh
./run.sh
```

To inspect the tool install steps without changing the machine:

```sh
./get-tools.sh --dry-run
```

The root `.sh` launchers call the shell implementations in `tools/`. The helper
uses Apple Command Line Tools for `git`, `clang`, and SDKs, and installs GitHub
CLI from GitHub's official `.pkg` release if `gh` is missing. It intentionally
avoids Homebrew because older Monterey setups can be awkward when Homebrew needs
newer source-built dependencies.

If Apple Command Line Tools are missing, `./build.sh --install-missing` runs
the Homebrew-free macOS tool helper first.

Install Xcode Command Line Tools:

```sh
xcode-select --install
```

The preferred path is the repository-root `./build.sh` launcher. This folder's
`build.sh` remains available as a compatibility launcher:

```sh
./build.sh
```

Output:

```text
build/CodexPetWatch.app
build/codex_pet_watch-macosx-x64-v0.50.zip
```

The build script ad-hoc signs the app:

```sh
codesign --force --deep --sign - build/CodexPetWatch.app
```

Keep this signing step in place. It helps macOS keep Screen Recording permission across rebuilds of the local app.

The release zip contains `CodexPetWatch.app`; inside the bundle, `Contents/MacOS/CodexPetWatch` is the executable and `Contents/Resources/ringout.wav` is the bundled default sound.

## Download

- Release asset: [codex_pet_watch-macosx-x64-v0.50.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.50/codex_pet_watch-macosx-x64-v0.50.zip)
- Release notes: [v0.50](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.50)

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
--size=WxH       Watch rectangle size in physical pixels. Default: 16x16
--poll-ms=N      Capture interval in milliseconds. Default: 1000
--help           Show help
```

Examples:

```sh
open build/CodexPetWatch.app
build/CodexPetWatch.app/Contents/MacOS/CodexPetWatch --size=16x16
build/CodexPetWatch.app/Contents/MacOS/CodexPetWatch /path/to/custom.wav --poll-ms=1000
```

## Notes

- This watches pixels, not Codex state. Pet animation can produce multiple rings.
- The Codex pet/activity overlay can also ring when it shifts or updates while an agent is waiting for user input. This is expected and useful as a small interaction-needed signal.
- The app watches the upper-right area of the bottom-left parked pet sprite. Its screen anchor is offset 100 physical pixels from the left edge and 116 physical pixels from the bottom edge of the main display at launch. On Retina displays, the green overlay converts those pixel dimensions and offsets to AppKit screen points so it matches the captured pixels.
- macOS menu-bar apps normally show their menu on click; choose `Exit` to quit.
