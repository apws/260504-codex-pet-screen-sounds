# codex-pet-watch

Tiny Win32/GDI watcher for a `codex-pet-area` rectangle near the bottom-left of the active monitor, offset 56 px from the left edge and 72 px from the bottom edge.

It:

- enables best-effort Per-Monitor DPI Awareness v2
- measures the selected monitor's physical pixel bounds and logical DIP size
- creates a click-through, topmost, transparent overlay window with a thin green outline
- runs as a tray app with a status icon and an Exit menu
- captures that rectangle once per second using old Win32 GDI `BitBlt`
- compares raw BGRA bitmap bytes against the previous capture
- plays a sound when **any pixel changes**

## Platform

Windows 11 / Windows 10 desktop app.

The source is architecture-neutral C++ Win32 code. Build it as either:

- x64 / x86-64: recommended default
- x86 / Win32: also supported

## Sound file

The app uses Win32 `PlaySoundW`, so use a `.wav` file.

If no sound file is specified, the app uses `ringout.wav`.

Builds copy the shared default sound from:

```text
../shared/sounds/ringout.wav
```

to the executable output folder as:

```text
ringout.wav
```

Relative sound paths are resolved against the executable folder. For example, if you run:

```bat
codex_pet_watch.exe alert.wav
```

then the app tries to play `alert.wav` from the same folder as `codex_pet_watch.exe`.

## Build with CMake + MSVC

Open a **Developer Command Prompt for Visual Studio** in this folder.

For x64:

```bat
build_msvc_x64.bat
```

Output:

```text
build-x64\Release\codex_pet_watch.exe
build-x64\Release\ringout.wav
```

For x86:

```bat
build_msvc_x86.bat
```

Output:

```text
build-x86\Release\codex_pet_watch.exe
build-x86\Release\ringout.wav
```

## Build with plain `cl`

Open a VS Developer Command Prompt for the architecture you want, then run:

```bat
build_cl_current_prompt.bat
```

Output:

```text
build\codex_pet_watch.exe
build\ringout.wav
```

## Usage

```bat
codex_pet_watch.exe [sound.wav] [widthDip heightDip] [options]
```

## Windows SmartScreen

Release builds are currently unsigned. Windows may show an "unrecognized app" / SmartScreen warning the first time you run the downloaded `.exe`. This is expected for this small local-build watcher; choose `More info` / `Run anyway` if you trust this repository and release asset. Later launches are usually normal after Windows has seen the file once.

Examples:

```bat
codex_pet_watch.exe alert.wav
codex_pet_watch.exe --size=24x24
codex_pet_watch.exe alert.wav 24 24
codex_pet_watch.exe alert.wav --size=480x280 --poll-ms=1000 --work-area
codex_pet_watch.exe alert.wav --size=24x24 --follow-foreground
```

Options:

```text
--size=WxH              Rectangle size in logical DIP units. Default: 24x24
--poll-ms=N             Capture interval in milliseconds. Default: 1000
--work-area             Anchor to monitor work area instead of full monitor
--follow-foreground     Re-anchor if the foreground-window monitor changes
--cursor-monitor        Use monitor containing the cursor at launch
--primary-monitor       Use primary monitor at launch
--help                  Show help
```

## Coordinate behavior

The app accepts rectangle size in logical DIP units, then converts to physical pixels using the selected monitor DPI:

```text
physical_px = logical_dip * monitor_dpi / 96
```

Internally, the overlay position and GDI capture rectangle use physical desktop pixels, with the rectangle offset 56 px from the selected anchor area's left edge and 72 px from its bottom edge. This matters for multi-monitor setups, DPI scaling, and monitors with negative coordinates.

The default monitor selection is the monitor containing the foreground window at launch. If there is no foreground window, it falls back to the cursor monitor, then primary monitor.

## Notes / known limitations

- `BitBlt` captures the visible composited screen area. Hidden or occluded content is not captured.
- The green outline is itself part of the visible screen. Since it is constant, it becomes part of the baseline and normally does not retrigger.
- Mouse cursor pixels are typically not included by this capture path.
- Any bitmap difference triggers the sound, even a single pixel.
- The app runs without a console window. Right-click the tray icon and choose `Exit` to stop it.
