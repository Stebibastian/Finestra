# Finestra

[![Download the latest release](https://img.shields.io/github/v/release/Stebibastian/Finestra?label=Download&color=orange&style=for-the-badge)](https://github.com/Stebibastian/Finestra/releases/latest/download/Finestra.zip)

A tiny macOS menu-bar app that **automatically places new Finder windows** at the size,
position and monitor you choose. Open a Finder window - it lands exactly where you want it.

Built as a notarized, standalone successor to a small SwiftBar script.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Stebibastian/Finestra/main/web-install.sh | bash
```

Downloads the latest notarized release, installs it to `/Applications` and launches it.
On first launch, grant **Accessibility** (System Settings → Privacy & Security →
Accessibility) - Finestra then relaunches itself and is ready.

## What it does

- **Watches the Finder** and places every newly opened window automatically.
- **Visual monitor map** - see all connected displays to scale, with a live preview of
  where the window will land.
- **Target monitor** - keep windows on the screen where they open, or always send them to
  a specific display.
- **Size** - a fixed pixel size (with handy presets) or a percentage of the screen.
- **Position** - a 3×3 grid (corners, edges, centre).
- **Launch at login**, automatic update checks, lives quietly in the menu bar.

## Why Accessibility?

macOS only lets an app move another app's windows once you grant Accessibility. Finestra
uses it solely to read and set Finder window frames - nothing else leaves your Mac.

## Build from source

Requires Xcode command-line tools.

```bash
git clone https://github.com/Stebibastian/Finestra.git
cd Finestra
./install.sh          # builds, signs locally, installs to /Applications, launches
```

- `./make-app.sh` - build the `.app` bundle (locally signed)
- `./make-release.sh` - Developer ID signing + Apple notarization → `Finestra.zip`
- `./uninstall.sh` - remove the app, its settings and the local signing keychain

## Notes

- macOS 13 (Ventura) or newer.
- The App Store is not an option (the sandbox forbids moving other apps' windows), so
  Finestra ships Developer-ID-signed and Apple-notarized for warning-free distribution.
