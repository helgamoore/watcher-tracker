# WatcherTracker

WatcherTracker is a macOS utility for working with DeviantArt watcher data and AI-assisted image generation.

The project began as a small tool for cleaning and comparing manually copied DeviantArt watcher lists. It has since grown into a multi-part macOS project with watcher tracking, report history, favourites, multiple image-generation providers, and a local AI image-generation service.

The project is also a practical learning project for Swift, SwiftUI, macOS development, Python, FastAPI, and local AI integration.

## Features

### DeviantArt Watcher Tracking

- Import watcher lists copied from DeviantArt
- Remove empty lines and unwanted `avatar` entries
- Remove duplicate watcher names
- Sort watchers alphabetically
- Save dated watcher snapshots
- Compare the current list with the previous snapshot
- Report:
  - new watchers
  - removed watchers
  - total watcher count
- View the current watcher list
- Mark artists as favourites
- Browse favourites independently
- Open DeviantArt artist profiles
- Browse report history using a calendar view
- Automatically restore selected folders and application state
- Watch the source folder for changes

### Image Generation

WatcherTracker now includes a dedicated image-generation workspace with separate provider windows.

Current providers:

- **Local AI** — local Stable Diffusion XL generation using Juggernaut XL
- **Apple Image Playground** — Apple image-generation integration
- **Gemini** — provider window prepared for future Google Gemini integration
- **ChatGPT** — provider window prepared for future OpenAI image-generation integration

The Local AI and Apple generators use a shared workflow:

- Prompt entry
- Provider-specific settings
- Image preview
- Clickable full-size preview window
- Save generated image
- Automatically save generation metadata in a Markdown sidecar file

For example, saving:

```text
Forest-party.png
```

also creates:

```text
Forest-party.md
```

with information such as:

```markdown
# Forest-party.png

## Parameters

- Provider: Local AI
- Model: juggernaut-xl-v9
- Size: 1024 × 1024
- Steps: 30
- Guidance: 5.5
- Seed: 123456789

## Prompt

Forest party at night, cinematic lighting

## Image

![Forest-party.png](Forest-party.png)
```

## Local AI Server

The local image generator runs as a separate Python service.

Architecture:

```text
WatcherTracker (SwiftUI)
        ↓ HTTP
FastAPI local server
        ↓
Diffusers / PyTorch
        ↓
Juggernaut XL
        ↓
Apple Metal / MPS
```

The server currently provides:

- Health and status endpoints
- Model status
- Generation progress
- Local image generation
- Generated image access
- Temporary generated-image storage
- Image deletion
- Model unload support

The local server is currently intended to run on the same Mac as WatcherTracker.

## AI Server Manager

The repository also contains a separate macOS menu-bar utility for managing the local AI server.

It can:

- Start and stop the Python server
- Show server status
- Show model status
- Display live generation progress
- Display the active prompt and generation parameters
- Open Swagger documentation
- Browse generated images
- Preview and delete generated images
- View server logs
- Run a small test generation
- Prevent multiple instances of the manager from running

The Server Manager uses the existing Bash scripts as the server lifecycle layer.

## Example Watcher Import

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

## Current DeviantArt Workflow

1. Copy the watcher list from DeviantArt.
2. Save or paste it into a text file.
3. Place the file in the configured source folder.
4. WatcherTracker detects the available file.
5. Select the file and process it.
6. The app cleans and sorts the watcher list.
7. The cleaned list is stored as a dated snapshot.
8. WatcherTracker compares it with the previous snapshot.
9. A report is generated showing watcher changes.

## Technology

WatcherTracker uses several languages and technologies:

### macOS applications

- Swift
- SwiftUI
- AppKit
- Image Playground
- macOS App Sandbox
- Security-scoped bookmarks

### Local AI service

- Python 3.11
- FastAPI
- Uvicorn
- PyTorch
- Diffusers
- Stable Diffusion XL
- Juggernaut XL
- Apple Metal Performance Shaders (MPS)

### Server lifecycle

- Bash

### Communication

- HTTP / JSON

The project currently targets macOS on Apple Silicon.

## Project Structure

The project is divided into several cooperating components:

```text
WatcherTracker
├── WatcherTracker macOS app
│   ├── DeviantArt watcher tools
│   └── Image generator clients
│
├── AI Server Manager
│   └── macOS menu-bar utility
│
└── ai-server
    ├── FastAPI service
    ├── local image generator
    └── Bash lifecycle scripts
```

## Project Status

Active development.

The original watcher-import workflow is working and has expanded significantly beyond the initial prototype.

The project currently includes:

- functional watcher import and comparison
- watcher history
- favourites
- multiple macOS utility windows
- Apple Image Playground integration
- functional local Juggernaut XL generation
- shared image preview and export workflow
- Markdown generation metadata
- standalone local AI server
- standalone server manager

## Planned Features

Possible future development includes:

- Direct integration with the DeviantArt API
- Automatic retrieval of watcher lists
- iCloud-based snapshot storage
- Watcher statistics and trends
- Watchlist support
- Artwork favourites, tags, and folders
- Gemini image-generation integration
- OpenAI image-generation integration
- More local AI models
- iPadOS and iOS versions
- Shared data model across Apple platforms

## Why This Project Exists

WatcherTracker started as a small utility for a personal DeviantArt workflow.

It is also a practical project for refreshing and extending Swift and SwiftUI skills while experimenting with modern local AI architecture.

Other DeviantArt artists may find parts of the utility useful as well, so the project is being developed publicly.

## Contributing

Suggestions, bug reports, and contributions are welcome.

The project is evolving quickly, so its structure and features may still change significantly during development.

## License

This project is licensed under the MIT License.

See the `LICENSE` file for details.
