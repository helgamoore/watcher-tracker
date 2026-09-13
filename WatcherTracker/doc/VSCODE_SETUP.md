# WatcherTracker: VS Code Setup

This guide describes the current VS Code setup for developing and building WatcherTracker on macOS.

WatcherTracker is a SwiftUI macOS application managed by Xcode. VS Code is used for editing, running the configured build tasks, and launching the compiled app with LLDB. Xcode remains useful for project settings, signing, previews, and any workflow that VS Code does not expose.

## Project layout

The repository has two important levels:

```text
watcher-tracker/                 # repository root; open this folder in VS Code
  .vscode/
    tasks.json                   # Debug, Release, and Clean tasks
    launch.json                  # LLDB launch configuration
  WatcherTracker/
    WatcherTracker.xcodeproj/    # Xcode project
    WatcherTracker/              # Swift source and assets
    doc/
```

Open the repository root, not the nested `WatcherTracker` directory. The existing VS Code configurations use `${workspaceFolder}` and expect the following paths:

```text
${workspaceFolder}/WatcherTracker/WatcherTracker.xcodeproj
${workspaceFolder}/WatcherTracker/dist/WatcherTracker.app
```

## Prerequisites

Install or have access to the following:

- macOS
- Visual Studio Code
- Xcode
- The Xcode command-line tools
- The Swift language support and LLDB debugging support required by the installed VS Code setup

The repository currently selects this Xcode installation in its VS Code tasks:

```text
/Volumes/Samsung/Applications/Xcode.app/Contents/Developer
```

The project currently targets macOS 26.5 and uses Swift 5.0 settings. Use an Xcode version that supports these project settings. Check the installed tools from a VS Code terminal:

```bash
xcode-select -p
xcodebuild -version
swift --version
```

If the active developer directory is different from the path above, either install/use Xcode at the configured path or update the `DEVELOPER_DIR` value in `.vscode/tasks.json` and the corresponding documentation. Do not change the path only in one task.

## Open the workspace

1. Start VS Code.
2. Select **File > Open Folder...**.
3. Open the repository root:

   ```text
   /Volumes/Samsung/Users/helga/Projects/watcher-tracker
   ```

4. Trust the workspace if VS Code asks for confirmation.
5. Open the `WatcherTracker/WatcherTracker/` folder to edit Swift source files, or open `WatcherTracker/doc/` to edit documentation.

The repository already contains the relevant files under `.vscode`; no workspace settings file or Swift Package Manager manifest is currently required.

## VS Code configuration

### Build tasks

The current `.vscode/tasks.json` defines these tasks:

| Task | Purpose | Configuration | Output |
| --- | --- | --- | --- |
| `Build WatcherTracker (Debug)` | Development build with debug symbols | Debug | `WatcherTracker/dist/WatcherTracker.app` |
| `Build WatcherTracker (Release)` | Optimized local release build | Release | `WatcherTracker/dist/WatcherTracker.app` |
| `Clean WatcherTracker` | Remove build products for the scheme | N/A | No app output |

All three tasks run from `${workspaceFolder}/WatcherTracker`, which is the directory containing `WatcherTracker.xcodeproj`. They use `xcodebuild` and set `DEVELOPER_DIR` to the Xcode path described above.

To run a task:

1. Open the Command Palette with `Cmd+Shift+P`.
2. Run **Tasks: Run Task**.
3. Select the desired WatcherTracker task.
4. Review the result in the integrated terminal.

The Debug task is also the default test task in the current configuration. The build problem matcher converts lines in the form `file:line:column: error|warning: message` into clickable VS Code diagnostics.

### Launch and debugging

The current `.vscode/launch.json` contains one configuration named `Debug WatcherTracker`.

It launches this executable:

```text
${workspaceFolder}/WatcherTracker/dist/WatcherTracker.app/Contents/MacOS/WatcherTracker
```

Before launch, VS Code runs `Build WatcherTracker (Debug)` automatically through `preLaunchTask`.

To launch the app under the debugger:

1. Open **Run and Debug** in the Activity Bar, or press `Cmd+Shift+D`.
2. Select `Debug WatcherTracker` if it is not already selected.
3. Press the green start button or `F5`.
4. Set breakpoints by clicking beside a Swift source line.
5. Use the Debug toolbar to continue, pause, step over, step into, or stop.

The current launch configuration uses `lldb-dap`, starts with `stopOnEntry: false`, and sets the working directory to `${workspaceFolder}/WatcherTracker`.

If `lldb-dap` is not recognized, install or enable the Swift/LLDB debugging support supported by the installed VS Code environment. The repository does not currently pin a VS Code extension list, so extension availability is machine-specific.

### Keyboard shortcuts

The repository does not currently include a project-specific `keybindings.json`. The following built-in macOS shortcuts are useful for the WatcherTracker workflow:

| Shortcut | Command | Use |
| --- | --- | --- |
| `Cmd+Shift+P` | Show Command Palette | Run tasks and VS Code commands |
| `Cmd+Shift+D` | Run and Debug | Open the debugging view |
| `F5` | Start Debugging | Run `Debug WatcherTracker` and its pre-launch build |
| `Shift+F5` | Stop Debugging | Stop the current LLDB session |
| `F9` | Toggle Breakpoint | Add or remove a breakpoint on the current line |
| `F10` | Step Over | Execute the next source line without entering a function |
| `F11` | Step Into | Enter the function called on the current line |
| `Shift+F11` | Step Out | Continue until the current function returns |
| ``Ctrl+` `` | Toggle Terminal | Open or hide the integrated terminal |

On Mac keyboards, function keys may control hardware features such as brightness or volume. If `F5` or another function-key shortcut does not work, hold `Fn` while pressing it, or enable **Use F1, F2, etc. keys as standard function keys** in macOS **System Settings > Keyboard > Keyboard Shortcuts > Function Keys**.

#### Optional task shortcuts

For faster repeated builds, add workspace keybindings through **Code > Settings > Keyboard Shortcuts**, then select the document icon in the upper-right corner to open `keybindings.json`. Add entries such as:

```json
[
  {
    "key": "cmd+shift+b",
    "command": "workbench.action.tasks.runTask",
    "args": "Build WatcherTracker (Debug)"
  },
  {
    "key": "cmd+shift+alt+b",
    "command": "workbench.action.tasks.runTask",
    "args": "Build WatcherTracker (Release)"
  },
  {
    "key": "cmd+shift+alt+k",
    "command": "workbench.action.tasks.runTask",
    "args": "Clean WatcherTracker"
  }
]
```

If `keybindings.json` already contains entries, add these objects inside its existing array and keep the surrounding brackets. These shortcuts are user-specific and are not currently committed to the repository. The task names in the `args` values must exactly match the labels in `.vscode/tasks.json`.

## First verification

After opening the repository, verify the complete setup in this order.

### 1. Check Xcode

From the VS Code integrated terminal:

```bash
cd WatcherTracker
DEVELOPER_DIR=/Volumes/Samsung/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project WatcherTracker.xcodeproj -scheme WatcherTracker -list
```

The output should include the `WatcherTracker` scheme.

### 2. Run the Debug task

Run `Build WatcherTracker (Debug)` from **Tasks: Run Task**. A successful build should create:

```text
WatcherTracker/dist/WatcherTracker.app
```

The `dist/` directory is ignored by Git and contains local build output.

### 3. Start the debugger

Run `Debug WatcherTracker` from **Run and Debug** or press `F5`. The app should open and VS Code should attach LLDB to the executable.

## Terminal build commands

The same commands can be run manually from the repository root:

```bash
cd WatcherTracker

DEVELOPER_DIR=/Volumes/Samsung/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
    -project WatcherTracker.xcodeproj \
    -scheme WatcherTracker \
    -configuration Debug \
    CONFIGURATION_BUILD_DIR="$PWD/dist" \
    build
```

For a Release build:

```bash
cd WatcherTracker

DEVELOPER_DIR=/Volumes/Samsung/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
    -project WatcherTracker.xcodeproj \
    -scheme WatcherTracker \
    -configuration Release \
    CONFIGURATION_BUILD_DIR="$PWD/dist" \
    build
```

To clean the scheme:

```bash
cd WatcherTracker

DEVELOPER_DIR=/Volumes/Samsung/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
    -project WatcherTracker.xcodeproj \
    -scheme WatcherTracker \
    clean
```

For the full command-line build and archive reference, see [BUILDING.md](BUILDING.md).

## When to use Xcode

Open `WatcherTracker/WatcherTracker.xcodeproj` in Xcode when you need to:

- Change signing or team settings.
- Inspect target and build settings.
- Work with SwiftUI previews.
- Select a run destination or manage scheme settings.
- Create archives or prepare distribution exports.
- Diagnose an issue that is specific to Xcode rather than the source code.

The target currently uses automatic signing, the development team configured in the project, the bundle identifier `com.musesofmagic.WatcherTracker`, and a macOS application target. Signing changes should be made deliberately because they can affect other developers and local builds.

## Common problems

### `xcodebuild: error: Unable to find a destination`

Confirm that the active Xcode installation supports the project's macOS deployment target and that the command is using the intended developer directory:

```bash
DEVELOPER_DIR=/Volumes/Samsung/Applications/Xcode.app/Contents/Developer xcodebuild -version
```

### `WatcherTracker.xcodeproj` cannot be found

The command is being run from the wrong directory. The project file is inside `WatcherTracker/`, so either run the VS Code task or use:

```bash
cd WatcherTracker
```

### F5 cannot find the executable

Run `Build WatcherTracker (Debug)` first and confirm that this file exists:

```text
WatcherTracker/dist/WatcherTracker.app/Contents/MacOS/WatcherTracker
```

If the app was built somewhere else, the launch configuration will not find it because it intentionally uses `CONFIGURATION_BUILD_DIR=.../WatcherTracker/dist`.

### The task uses the wrong Xcode

The tasks set `DEVELOPER_DIR` explicitly. Check `/Volumes/Samsung/Applications/Xcode.app/Contents/Developer`, or update the path consistently in `.vscode/tasks.json`, this guide, and any local shell setup.

### Build warnings or errors do not appear in Problems

The task problem matcher expects the standard `xcodebuild` diagnostic format. Open the task terminal and inspect the complete build output. The command-line build guide also contains a filtered errors-and-warnings command.

## Updating this setup

When changing the VS Code workflow, keep these items synchronized:

- `.vscode/tasks.json`
- `.vscode/launch.json`
- The output path used by the build tasks and launch configuration
- The Xcode developer directory
- This guide and [BUILDING.md](BUILDING.md)

Do not commit `dist/`, `DerivedData/`, user-specific Xcode data, or local environment files. The repository's `.gitignore` already excludes these generated or machine-specific files.
