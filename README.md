# love-uwp

LÖVE 11.5 built as a UWP app, mainly so LÖVE games can run on an Xbox in Developer Mode.

This repo does not contain LÖVE itself. It holds the build files, a few patches and the CI workflow. GitHub Actions downloads pinned upstream sources, builds everything for UWP x64 and packages the result as a sideloadable, test-signed `.appx`.

The package ships with no game in it. You bring your own `game.love`.

## Status

Work in progress. The goal is a package that boots on Xbox Series consoles in Dev Mode and runs regular LÖVE 11.5 games with a controller. Check the Releases page for the latest build; if there is none yet, the CI is still being sorted out.

## What is in the build

| Piece | Version | Notes |
| --- | --- | --- |
| LÖVE | 11.5 | patched for UWP (see `patches/`), linked into a single love.exe |
| SDL2 | 2.30.9 | WinRT backend, gamepads through Windows.Gaming.Input |
| ANGLE | ANGLE.WindowsStore 2.1.13 (NuGet) | OpenGL ES 2 on top of Direct3D 11 |
| LuaJIT | 2.1 (megasource 11.5 snapshot) | built with `_UWP`, JIT compiler turned off, interpreter only |
| OpenAL Soft | 1.24.3 | WASAPI backend (the first release with UWP support) |
| FreeType, zlib, libogg, libvorbis, libtheora | from megasource 11.5 | |

Not included on UWP: libmodplug and mpg123 (LÖVE already disables them for UWP builds), so tracker modules and MP3 files will not play. Ogg Vorbis and WAV work.

Things LÖVE games can't do in a UWP sandbox: `os.execute`, `io.popen`, loading native Lua modules from disk, and writing anywhere outside the app's own folders.

## Running a game

The app looks for a game in this order:

1. `game.love` (or a folder named `game`) in the app's LocalState folder
2. a `game.love` packed into the app package next to the executable

If it finds nothing, it shows a screen explaining where to put the file.

On Xbox, the easiest way to get `game.love` into LocalState is the Device Portal: open `https://<console-ip>:11443`, go to File explorer, find the app under LocalAppData, open `LocalState` and upload the file there.

The game runs in fused mode, so save files go to `LocalState/<identity>`, next to `game.love`.

## Installing on an Xbox in Dev Mode

1. Download the `.appx`, the `.cer` and the dependency packages from the latest release.
2. In Device Portal, go to Home > Add, pick the `.appx`, and add the dependency packages (VCLibs) on the next page.
3. In Dev Home, select the app, press the View button, choose View details and set the app type to Game. Without that the app runs with the much smaller App resource budget.
4. Upload your `game.love` as described above and launch the app.

On Windows 10/11 desktop you can sideload the same package: install the `.cer` into Local Machine > Trusted People, then double click the `.appx` (or use `Add-AppxPackage`). Developer mode needs to be on.

## Building

Builds happen on GitHub Actions (`.github/workflows/build.yml`) on a `windows-2022` runner. To build locally you need Visual Studio 2022 with the Universal Windows Platform workload and a Windows 10 SDK, then from a Developer PowerShell:

```powershell
./scripts/fetch-sources.ps1
./scripts/build.ps1
./scripts/package.ps1
```

`fetch-sources.ps1` downloads everything into `deps/`, `build.ps1` builds LuaJIT and then the CMake project for `WindowsStore` x64 Release, and `package.ps1` lays out the package, makes a throwaway signing certificate and runs `makeappx` and `signtool`.

## Licenses

LÖVE is under the zlib license, see `LICENSE`. The license of every library that ends up in the package is in `licenses/`. The build scripts in this repo are under the zlib license too.
