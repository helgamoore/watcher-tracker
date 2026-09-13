# WatcherTracker

WatcherTracker is a small macOS utility for tracking changes in your DeviantArt watcher list.

The current version works with watcher lists copied manually from the DeviantArt website. It cleans the copied text, stores dated snapshots, and compares the latest list with the previous one.

The project is also a learning project for Swift, SwiftUI, and macOS development.

## Features

- Import a watcher list copied from DeviantArt
- Remove empty lines and unwanted `avatar` entries
- Remove duplicate watcher names
- Sort watchers alphabetically
- Save a dated watcher snapshot
- Compare the current list with the previous snapshot
- Report:
  - new watchers
  - removed watchers
  - total watcher count

## Example

A raw list copied from DeviantArt may contain entries such as:

```text
SomeWatcher
AnotherWatcher's avatar
AnotherWatcher

ThirdWatcher
```

WatcherTracker converts it into:

```text
AnotherWatcher
SomeWatcher
ThirdWatcher
```

Snapshots are stored using names such as:

```text
watchers_2026-09-13.txt
```

A comparison report looks like:

```text
Report on watchers
Added Watchers 2:
+ NewWatcher
+ AnotherNewWatcher

Removed Watchers 1:
- FormerWatcher

Total Current Watchers: 1078
```

## Current Workflow

1. Copy the watcher list from DeviantArt.
2. Save or paste it into a text file.
3. Open the file in WatcherTracker.
4. The app cleans and sorts the watcher list.
5. The cleaned list is stored as a dated snapshot.
6. WatcherTracker compares it with the previous snapshot.
7. A report is generated showing watcher changes.

## Planned Features

The current text-file workflow is only the first version of WatcherTracker.

Possible future development includes:

- Direct integration with the DeviantArt API
- Automatic retrieval of watcher lists
- iCloud-based snapshot storage
- Watcher history and statistics
- macOS, iPadOS, and iOS versions
- A shared data model across Apple platforms
- Improved history and comparison views

## Technology

WatcherTracker is written in Swift using SwiftUI.

The project currently targets macOS.

## Project Status

Early development.

The first version focuses on the basic watcher import, cleanup, archiving, and comparison workflow.

The architecture is intended to allow the current text-file importer to be replaced later by direct DeviantArt API access without changing the core watcher comparison logic.

## Why This Project Exists

I originally created WatcherTracker as a small utility for my own DeviantArt workflow.

It is also a practical project for refreshing and developing my Swift and SwiftUI skills.

Other DeviantArt artists may find the utility useful as well, so the project is being developed publicly.

## Contributing

Suggestions, bug reports, and contributions are welcome.

The project is still evolving, so its structure and features may change significantly during development.

## License

This project is licensed under the MIT License.

See the `LICENSE` file for details.