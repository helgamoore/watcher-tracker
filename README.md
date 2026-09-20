# WatcherTracker

WatcherTracker is a multi-platform project for working with DeviantArt watcher data and AI-assisted image generation.

The project began as a small macOS tool for cleaning and comparing manually copied DeviantArt watcher lists. It has since grown into a multi-part project with watcher tracking, report history, favourites, multiple image-generation providers, a local AI image-generation service, and an iPadOS client.

The project is also a practical learning project for Swift, SwiftUI, macOS and iPadOS development, Python, FastAPI, local networking, and local AI integration.

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

The local server currently runs on the Mac mini and can be accessed by trusted client devices on the same private LAN, including Watcher Tracker Mobile on iPadOS.

## Watcher Tracker Mobile

Watcher Tracker Mobile is the first iPadOS client for the project.

The initial version intentionally focuses on one feature: using the Local AI generator hosted on the Mac mini.

Current iPadOS features:

- Connect to the Local AI server over the private LAN
- Show server availability and live generation progress
- Enter a prompt and negative prompt
- Configure steps, guidance, and seed
- Generate 1024 × 1024 images using Juggernaut XL on the Mac mini
- Preview generated images directly on the iPad
- Open generated images in a full-screen preview
- Save generated images through the Files picker
- Export the generated image together with its Markdown metadata sidecar
- Save directly to iCloud Drive through the system Files interface

Current development server address:

```text
http://mini256.local:8765
```

The server currently listens on the local network and is intended for use on a private, trusted LAN. Authentication, authorization, and HTTPS are planned for a later server version.

The mobile architecture is deliberately thin:

```text
Watcher Tracker Mobile (SwiftUI / iPadOS)
                ↓ HTTP
        Local AI Server
                ↓
      Diffusers / PyTorch
                ↓
         Juggernaut XL
                ↓
       Apple Metal / MPS
```

This architecture keeps the heavy AI workload on the Mac mini while the iPad acts as a native client for prompting, monitoring, previewing, and exporting results.

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

### Apple client applications

- Swift
- SwiftUI
- AppKit on macOS
- UIKit interoperability on iPadOS
- Image Playground on macOS
- macOS App Sandbox
- Security-scoped bookmarks
- Local Network privacy support on iPadOS
- Files / iCloud Drive export through the system document picker

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

The project currently targets macOS on Apple Silicon and iPadOS.

## Project Structure

The project is divided into several cooperating components:

```text
WatcherTracker
├── WatcherTracker macOS app
│   ├── DeviantArt watcher tools
│   └── Image generator clients
│
├── Watcher Tracker Mobile
│   └── iPadOS Local AI client
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
- functional iPadOS Local AI client
- LAN-based generation from iPad to Mac mini
- full-screen mobile image preview
- image + Markdown export to Files / iCloud Drive

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
- Expand Watcher Tracker Mobile beyond Local AI generation
- iPhone support
- Shared data model across Apple platforms
- Provider-neutral generation server for macOS, iPadOS, iOS, and future Linux/Windows clients
- Authentication, authorization, and HTTPS for the generation server

## Cross-Platform Direction

The long-term direction is to move image-generation logic behind a shared server API so that native clients on different platforms can use the same generation service.

Planned client direction includes:

- macOS using SwiftUI
- iPadOS and iOS using SwiftUI
- a possible GNOME/Linux native client
- a possible native Windows client

The goal is to keep platform-specific user interfaces native while sharing the generation backend, provider integrations, job handling, model management, and metadata format through the server.

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
