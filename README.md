# ClaudeCodeMenuBar

Swift menu bar app for launching and managing a local Claude Code workflow on macOS.

## What It Does

- Runs as a macOS menu bar app
- Launches Claude Code in Terminal
- Supports primary and backup key launch modes
- Reads and updates the default key selection in `~/.zshrc`
- Opens the local launcher app and related shell config files

## Requirements

- macOS 14 or later
- Swift 6.2 toolchain
- A local Claude Code CLI install

## Build

```bash
swift build
```

Build a release app bundle:

```bash
./Scripts/build-app.sh
```

This outputs the app bundle to:

```bash
dist/ClaudeCodeMenuBar.app
```

## Project Structure

- `Sources/ClaudeCodeMenuBar/`: main menu bar application
- `Launcher/`: launcher-specific executable source
- `Resources/`: app plist files and bundled assets
- `Scripts/`: local build scripts

## Notes

- The app currently targets a local Claude Code setup and shell configuration.
- It modifies `~/.zshrc` when switching the default key mode.
- AppleScript is used to open Terminal and start CLI commands.

## Release Process

1. Open the repository's `Actions` tab on GitHub.
2. Run the `Release Build` workflow manually.
3. Enter a version string such as `v0.1.0`.
4. Download the generated zip artifacts from the workflow run.
5. Create a GitHub Release with the same tag and attach the generated artifacts.

The repository also includes GitHub release category configuration in `.github/release.yml` for cleaner release notes.

## Repository Role

This repository contains the macOS utility app. The main Sleeepal website lives separately at [sleeepal.com](https://sleeepal.com).
