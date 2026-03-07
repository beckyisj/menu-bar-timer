# Menu Bar Timer

A lightweight macOS menu bar app for tracking time per client and task. Optionally logs sessions to a Notion database.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Countdown timer** — preset durations (15/30/45/60 min) or custom
- **Open-ended stopwatch** — count up with no time limit
- **Notion integration** — auto-logs completed/stopped sessions to a Notion database
- **Client memory** — remembers recent clients for quick selection
- **Menu bar progress** — shows remaining/elapsed time and a progress ring in the menu bar
- **Pause/resume** — pause and pick up where you left off

## Install

### Option 1: Build from source

Requires Xcode 15+ and macOS 14+.

```bash
git clone https://github.com/beckyisj/menu-bar-timer.git
cd menu-bar-timer
open MenuBarTimer.xcodeproj
```

Hit **Cmd+R** to build and run. The app appears in your menu bar.

### Option 2: Download release

Check the [Releases](https://github.com/beckyisj/menu-bar-timer/releases) page for a pre-built `.app` download.

## Notion Setup (Optional)

The app can log every session to a Notion database. Here's how to set it up:

### 1. Create a Notion integration

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **New integration**
3. Name it something like "Menu Bar Timer"
4. Select your workspace
5. Click **Submit** and copy the **Internal Integration Secret** (starts with `ntn_`)

### 2. Create the database

Create a new database in Notion with these exact property names and types:

| Property | Type | Notes |
|---|---|---|
| **Name** | Title | Auto-filled as "[Task] for [Client]" |
| **Client** | Multi-select | Auto-populated with client names |
| **Planned (min)** | Number | Planned duration in minutes |
| **Actual (min)** | Number | Actual time spent in minutes |
| **Date** | Date | When the session ended |
| **Status** | Select | Options: `Completed`, `Stopped` |

### 3. Connect the integration to the database

1. Open your database page in Notion
2. Click the `...` menu (top right)
3. Go to **Connections** → **Connect to** → select your integration

### 4. Get the database ID

Copy the database URL from your browser. It looks like:
```
https://www.notion.so/your-workspace/abc123def456...?v=...
```
The database ID is the 32-character hex string in the URL (the `abc123def456...` part). You can paste the full URL or just the ID — the app handles both.

### 5. Configure in the app

1. Click the timer icon in your menu bar
2. Go to **Settings** tab
3. Paste your **API Key** and **Database ID**
4. Click **Save Settings**

Sessions will now auto-log to Notion whenever a timer completes or is stopped.

## Usage

1. Click the clock icon in your menu bar
2. Enter a client name and optional task description
3. Pick a duration (or **Open** for a stopwatch)
4. Click **Start Timer**
5. The menu bar shows your remaining/elapsed time
6. **Pause**, **Resume**, or **Stop** anytime

## Tech

- SwiftUI + AppKit (menu bar integration)
- No dependencies — pure Swift
- Notion API v2022-06-28
- Uses `UserDefaults` for local storage (last 200 sessions)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) project spec (`project.yml`)

## License

MIT
