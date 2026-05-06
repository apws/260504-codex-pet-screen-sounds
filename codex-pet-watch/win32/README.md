# codex-pet-watch

Tiny Win32/GDI watcher for a `codex-pet-area` rectangle in the upper-right area of the Codex pet sprite. The pet itself is parked near the bottom-left of the active monitor; the watched rectangle is offset 64 px from the screen's left edge and 80 px from the screen's bottom edge.

**Detection rectangle:** upper-right area of the bottom-left parked pet sprite; `SIZE=16x16`, `X=64 px` from the screen's left edge, `Y=80 px` from the screen's bottom edge.

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

The normal build target is x64 / x86-64. Codex Desktop on Windows is expected
on modern 64-bit Windows, so x86 is not part of the default repo build path.

## Sound file

The app uses Win32 `PlaySoundW`, so use a `.wav` file.

If no sound file is specified, the app uses the embedded default `ringout.wav` resource inside `codex_pet_watch.exe`.

Builds embed the shared default sound from:

```text
../shared/sounds/ringout.wav
```

Relative custom sound paths are still resolved against the executable folder. For example, if you run:

```bat
codex_pet_watch.exe alert.wav
```

then the app tries to play `alert.wav` from the same folder as `codex_pet_watch.exe`.

## Download

For most users, use the x64 release binary instead of installing build tools:

- [codex_pet_watch-win32-x64-v0.40.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.40/codex_pet_watch-win32-x64-v0.40.zip)
- [v0.40 release notes](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.40)

## Build With MSVC

From the repository root:

```powershell
.\build.ps1
```

This builds the Windows x64 executable:

```powershell
codex-pet-watch\win32\build-x64\Release\codex_pet_watch.exe
```

The script detects Visual Studio Build Tools and loads `VsDevCmd.bat` for you,
so `cl`, `rc`, `link`, `msbuild`, and `cmake` do not need to be on the global
PATH.

If a repo-built `codex_pet_watch.exe` is already running, the build script stops
it before rebuilding so the linker can overwrite the executable.

To launch the rebuilt x64 applet from the repository root:

```powershell
.\run.ps1
```

If the executable is missing, `run.ps1` builds it first. If it is already
running, `run.ps1` leaves the existing applet alone; use `.\run.ps1 -Restart`
to stop and relaunch it.

If the required headless Microsoft C++ toolchain is missing, install it with:

```powershell
.\tools\get-tools.ps1
```

That uses `winget` to install Visual Studio 2022 Build Tools with the C++
workload and Windows SDK. It does not install the full Visual Studio IDE.

To inspect the exact install command without changing the machine:

```powershell
.\tools\get-tools.ps1 -DryRun
```

If `winget` is missing, install App Installer from Microsoft:

```text
https://apps.microsoft.com/detail/9nblggh4nns1
```

Or install Visual Studio 2022 Build Tools manually:

```text
https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
```

Required workload:

```text
Desktop development with C++
```

Manual build scripts are also available from this folder after opening a
**Developer Command Prompt for Visual Studio**.

For x64:

```bat
build_msvc_x64.bat
```

Output:

```text
build-x64\Release\codex_pet_watch.exe
```

## Build with plain `cl`

Open a VS Developer Command Prompt for the architecture you want, then run:

```bat
build_cl_current_prompt.bat
```

Output:

```text
build\codex_pet_watch.exe
```

## Usage

```bat
codex_pet_watch.exe [sound.wav] [widthDip heightDip] [options]
```

## Windows SmartScreen

Release builds are currently unsigned. Windows may show an "unrecognized app" / SmartScreen warning the first time you run the downloaded `.exe`. This is expected for this small local-build watcher; choose `More info` / `Run anyway` if you trust this repository and release asset. Later launches are usually normal after Windows has seen the file once.

Latest release assets:

- x64: [codex_pet_watch-win32-x64-v0.40.zip](https://github.com/apws/260504-codex-pet-screen-sounds/releases/download/v0.40/codex_pet_watch-win32-x64-v0.40.zip)
- Release notes: [v0.40](https://github.com/apws/260504-codex-pet-screen-sounds/releases/tag/v0.40)

Examples:

```bat
codex_pet_watch.exe alert.wav
codex_pet_watch.exe --size=16x16
codex_pet_watch.exe alert.wav 16 16
codex_pet_watch.exe alert.wav --size=480x280 --poll-ms=1000 --work-area
codex_pet_watch.exe alert.wav --size=16x16 --follow-foreground
```

Options:

```text
--size=WxH              Rectangle size in logical DIP units. Default: 16x16
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

Internally, the overlay position and GDI capture rectangle use physical desktop pixels, with the rectangle offset 64 px from the selected anchor area's left edge and 80 px from its bottom edge. This matters for multi-monitor setups, DPI scaling, and monitors with negative coordinates.

The default monitor selection is the monitor containing the foreground window at launch. If there is no foreground window, it falls back to the cursor monitor, then primary monitor.

## Notes / known limitations

- `BitBlt` captures the visible composited screen area. Hidden or occluded content is not captured.
- The green outline is itself part of the visible screen. Since it is constant, it becomes part of the baseline and normally does not retrigger.
- On macOS, the Codex pet/activity overlay may ring when it shifts or updates while an agent is waiting for user input; that is expected there and useful as a small interaction-needed signal. Windows has generally appeared more static in the same area.
- Mouse cursor pixels are typically not included by this capture path.
- Any bitmap difference triggers the sound, even a single pixel.
- The app runs without a console window. Right-click the tray icon and choose `Exit` to stop it.
