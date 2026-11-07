# Cumba features

Everything Cumba does, one part at a time. Back to the [README](../README.md) · [Türkçe](features.tr.md)

## Media

Whatever any app plays (Safari, Chrome, YouTube, Spotify, Music, podcasts and more) shows up in one mini player with artwork, progress, seeking and controls, with no extension or setup. A small waveform beside the notch shows what's playing.

Cumba reads this from the system's Now Playing; [Media, brightness and private APIs](privacy.md#media-brightness-and-private-apis) explains how. If you turn off **Settings > Widgets > Media > Read media from every app**, it uses AppleScript for Spotify and Music and the YouTube extension below instead.

### YouTube extension (optional)

Not needed while Media reads from every app. A small Chrome extension (also works in other Chromium browsers) sends what plays in YouTube tabs to the app over a local connection, and the app sends play, pause, next and seek back.

1. In Cumba, open **Settings > Connections**, turn on **Connect the YouTube extension** and click **Show Extension Folder**.
2. In Chrome, open `chrome://extensions`, turn on **Developer mode** and click **Load unpacked**. Choose the folder from step 1.
3. Open the extension's **Details > Extension options**, paste the port and the token from **Settings > Connections**, and save.

Chrome will say the extension can read and change your data on `youtube.com` and `music.youtube.com`: it reads the player (title, artwork, progress) and presses play, pause, next and seek there. It runs on no other site, its only other permission is storage (for the port and token), and it talks only to `127.0.0.1`.

## Claude Code and Codex

The AI Agents widget shows what a session is doing right now ("Editing Notch.swift", "Running tests"), its title and last answer, and, for Claude Code, how full its context window is. A ring turns beside the notch while the agent works, and opening the panel then shows its tab.

When the agent asks a question, needs permission or finishes, a notification opens under the notch with what happened and **Open**, which brings the agent's app forward. You also see when a session fails. Permission requests from Claude Code (terminal, IDE extensions and the Claude desktop app) show up with **Allow**, **Deny** and **In Terminal**, and the card shows the full request with hidden characters made visible. Questions and plan approvals aren't permission requests: they stay in the agent, which asks them itself, and the notch shows that the session is waiting.

**Allow in the notch is the same as Allow in Claude Code: the tool runs right away.** By default, shell commands are answered in the terminal and everything else can be allowed from the notch; in Settings > Agents you can allow everything, or turn Allow off and keep only Deny and In Terminal. Requests with hidden characters never get an Allow button, and when a request is longer than its box, Allow waits until you've scrolled to its end.

Install the hooks in **Settings > Agents**; you review the change to `~/.claude/settings.json` first and a backup is made. Hooks reach the app through a private socket that only your user account can open, so nothing else can answer Claude Code in its place; they use their own token, separate from the extension's.

**Codex** works the same way: install its hooks in **Settings > Agents > Codex** (they go to `~/.codex/hooks.json`), then run `/hooks` in Codex once and trust them, since Codex runs new hooks only after that.

[Claude Code and Codex setup](claude-code-setup.md) has the details and manual setup.

## Widgets

Calendar with a Join button for video calls (scroll through the days to see any day's events), timer, Pomodoro, your Apple Notes (recent notes, and new ones from the panel), to-dos from Apple Reminders (tick them off, add new ones), clipboard history (text, links, images, files and new screenshots as cards), keep awake, teleprompter, battery, file tray with AirDrop, camera mirror, weather, Shortcuts and a CPU/memory graph.

Widgets live in tabs. Add them from a gallery in the panel or in Settings, and switch tabs with a two-finger swipe; a new installation starts with just three.

## A panel that fits

Tabs sit at the bottom or the top and are edited right in the panel (name, symbol, order, widgets). The panel is as wide as the open tab, and a widget alone in its tab shows a detailed view: weather with the next hours and days like Apple's widget, the whole month beside your events, large album art. Text size is adjustable, and so is how far the closed notch reaches past the camera.

## Themes

Eight built-in themes, from plain black and Liquid Glass to Neon Tokyo, Sakura, Synthwave and Citrus. Make your own: a glass, solid or tinted surface, a gradient background, a neon edge, colors, font, corner radius, shadow and animation. Panel size and text size stay the same whichever theme you pick. Import and export themes as JSON.

## Live activities

A running timer, a working AI agent, a pending request, charging, the current song or a volume or brightness change appear on both sides of the closed notch.

## Optional extras

These are off until you turn them on: show the panel on any display, the notch in place of the system volume and brightness indicators, a dot while the microphone or camera is in use, a countdown before meetings, a choice of media sources, and an [API for your own scripts](#scripts).

## Scripts

Turn on **Settings > Connections > Scripts** to let your own scripts, Shortcuts or build tools show a short status beside the notch. **Copy Example Command** copies a ready-to-run command with your token:

```bash
curl -s --unix-socket "$HOME/Library/Application Support/Cumba/hook.sock" \
  -H "X-Cumba-Token: <token>" -H "Content-Type: application/json" \
  -d '{"id":"build","title":"Build done","symbol":"hammer","duration":5}' \
  http://localhost/activity
```

Fields: `id` (letters, digits, `.`, `_` and `-`), `title` (up to 60 characters), `symbol` (an SF Symbol name), `progress` (0 to 1, shows a bar), `duration` (seconds, 1 to 3600), and `"remove": true` to take an activity away. Activities are text only, escaped like Claude Code requests, and nothing in them can be clicked.

## Stays out of the way

Clicks pass through to the menu bar, dragging windows past the notch doesn't open it, it works in full-screen apps too (or hides there, if you like), and it uses next to no CPU while idle. Right-click the notch for Settings.

## Languages

The interface is in English, Spanish (Spain and Latin America), French and Turkish.
