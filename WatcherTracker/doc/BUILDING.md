# WatcherTracker — Command-Line Build Cheat Sheet

This file collects the command-line build commands used for the **WatcherTracker** macOS project.

The project is an Xcode project:

```text
WatcherTracker.xcodeproj
```

so use `xcodebuild` rather than `swift build`.

---

## 1. Select the Xcode Installation

Xcode is installed on the Samsung volume:

```bash
sudo xcode-select --switch /Volumes/Samsung/Applications/Xcode.app/Contents/Developer
```

Check the active developer directory:

```bash
xcode-select -p
```

Expected result:

```text
/Volumes/Samsung/Applications/Xcode.app/Contents/Developer
```

Check the Xcode version:

```bash
xcodebuild -version
```

---

## 2. Show Project Information

List the available targets, build configurations, and schemes:

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -list
```

This is useful for checking that the scheme name is really `WatcherTracker`.

---

## 3. Debug Build

Build the Debug configuration:

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Debug \
  build
```

By default, Xcode places the product somewhere under `DerivedData`, for example:

```text
~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/
```

---

## 4. Release Build

Build the Release configuration:

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Release \
  build
```

By default, this also goes under `DerivedData`.

---

## 5. Release Build to `dist`

Create the output folder:

```bash
mkdir -p ./dist
```

Build the Release app directly into it:

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="$PWD/dist" \
  build
```

The resulting application should be:

```text
dist/WatcherTracker.app
```

This is the closest simple equivalent to:

```text
dotnet publish -c Release -o ./dist
```

For a generated `dist` folder, add this to `.gitignore`:

```gitignore
dist/
```

---

## 6. Create an Xcode Archive

For a distributable build, create an `.xcarchive`:

```bash
mkdir -p ./dist

xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Release \
  -archivePath "$PWD/dist/WatcherTracker.xcarchive" \
  archive
```

The result is:

```text
dist/WatcherTracker.xcarchive
```

An archive contains the built application together with distribution metadata and other information used by Xcode for signing and export.

---

## 7. Export an Archive

To export an archive, an `ExportOptions.plist` is required:

```bash
xcodebuild \
  -exportArchive \
  -archivePath "$PWD/dist/WatcherTracker.xcarchive" \
  -exportPath "$PWD/dist/export" \
  -exportOptionsPlist ExportOptions.plist
```

The exact contents of `ExportOptions.plist` depend on how the application will be distributed, for example:

- local development
- Developer ID distribution
- notarized direct download
- Mac App Store

This step becomes important when WatcherTracker is distributed to other users.

---

## 8. Clean the Project

Remove Xcode build products for the selected scheme:

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  clean
```

---

## 9. Clean and Rebuild Debug

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Debug \
  clean build
```

---

## 10. Build and Show Only Errors or Warnings

`xcodebuild` output can be quite verbose.

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Debug \
  build 2>&1 | grep -E "error:|warning:"
```

This hides normal build output, so use the full `xcodebuild` command when investigating unusual build problems.

---

## `xcodebuild` vs `swift build`

WatcherTracker is currently an Xcode application project and contains:

```text
WatcherTracker.xcodeproj
```

Therefore use:

```bash
xcodebuild
```

`swift build` is for Swift Package Manager projects containing:

```text
Package.swift
```

If a reusable `WatcherCore` Swift package is added later, that package could use:

```bash
swift build
swift test
swift run
```

The main SwiftUI macOS application would still be built with `xcodebuild`.

---

## Quick Reference

### Debug

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Debug \
  build
```

### Release to `dist`

```bash
mkdir -p ./dist

xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="$PWD/dist" \
  build
```

### Archive

```bash
xcodebuild \
  -project WatcherTracker.xcodeproj \
  -scheme WatcherTracker \
  -configuration Release \
  -archivePath "$PWD/dist/WatcherTracker.xcarchive" \
  archive
```

### Export

```bash
xcodebuild \
  -exportArchive \
  -archivePath "$PWD/dist/WatcherTracker.xcarchive" \
  -exportPath "$PWD/dist/export" \
  -exportOptionsPlist ExportOptions.plist
```
