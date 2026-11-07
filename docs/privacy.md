# Privacy and permissions

Back to the [README](../README.md) · [Türkçe](privacy.tr.md)

## What goes online

Cumba sends no telemetry. Only these features make network requests:

| Feature | Request |
|---|---|
| Media widget with Spotify | Album artwork from Spotify's image server (`i.scdn.co`), for the panel and the closed notch |
| Media widget with YouTube | Thumbnails from YouTube's image servers (`*.ytimg.com`, `*.googleusercontent.com`, `*.ggpht.com`; the URL the page itself uses), for the panel and the closed notch |
| Weather widget | Your location rounded to about 10 km (or the coordinates of the city you choose) to `api.open-meteo.com`; with your location, the same rounded coordinates to Apple Maps for the city name; a city you search for, with your language, to `geocoding-api.open-meteo.com`. Only while the widget is on screen, at most every 15 minutes |
| Update check | The list of releases from `api.github.com` at launch and once a day, with Cumba's version as the user agent; turn it off in Settings > General |

## What stays on your Mac

The camera (Mirror widget) runs only while the panel shows it, and nothing is recorded. The Tray keeps only file paths on your Mac. Notes and To-dos read and write Apple Notes and Apple Reminders on your Mac; nothing is copied or sent anywhere. The note from earlier versions (`notes.txt`) is imported into Apple Notes once; the file itself stays where it was.

Clipboard History keeps your last 20 copies (text, links, images and files) in memory only and skips items apps mark as passwords; while it's in one of your tabs it checks once a second whether the clipboard changed, even with the panel closed, so it doesn't miss a copy. With "Add new screenshots" on, it watches the screenshot folder for new screenshots and keeps only their location. The microphone and camera indicator reads only whether a device is in use, never audio or video.

When turned on, the extension server listens only on `127.0.0.1`, accepts only the Cumba extension and requires its own token, stored in your Keychain.

## Permissions and what runs

Except for the Now Playing helper and the update check, everything below is off or unused until you turn on the feature that needs it. Settings > Permissions shows the current state of each.

| What | Why | When |
|---|---|---|
| System Now Playing helper | Media from every app, and its controls | Runs while the app runs; turn off "Read media from every app" to use AppleScript instead. See [below](#media-brightness-and-private-apis) |
| Automation (Apple Events) for Spotify and Music | Read the current track; play, pause, skip, seek | Only with "Read media from every app" off; asked from Settings, scripts are sent only while that app is already running |
| Automation (Apple Events) for Notes | Notes widget: list your recent notes, open one, make new ones | Asked when you connect Notes in the widget or in Settings; Cumba starts Notes in the background and never changes an existing note |
| Calendar (full access) | Calendar widget | Asked when you click Allow in the widget or in Settings |
| Reminders (full access) | To-dos widget: show, tick off and add reminders | Asked when you click Allow in the widget or in Settings |
| Location | Weather widget, for the weather where you are | Asked when you click Use My Location; off if you choose a city instead |
| Camera | Mirror widget | Only while the panel shows it; nothing is recorded |
| Local server on `127.0.0.1` | Optional YouTube extension connection | Only after you turn it on in Settings > Connections |
| Private Unix socket | Claude Code and Codex hooks, and [script activities](features.md#scripts) | Only while hooks are installed or script activities are on |
| `~/.claude/settings.json`, `~/.codex/hooks.json` | Installing and removing the Claude Code and Codex hooks | Only after you review the change; a backup is kept |
| Claude Code transcripts in `~/.claude/projects` | Context use and session title in the AI Agents widget | Read on this Mac only, the last 256 KB, while a session runs |
| Accessibility | Handling the volume or brightness keys | Only if you turn on "Replace the system volume indicator" or "…brightness indicator" |
| Clipboard | Clipboard History widget | Only while that widget is in one of your tabs |
| Files and Folders (Desktop, or wherever screenshots go) | Adding new screenshots to Clipboard History | Only if you turn on "Add new screenshots" |
| Login item | Launch at login | Off until you turn it on |
| Network | Artwork, weather, update check | See [What goes online](#what-goes-online) |

The App Sandbox is off: a sandboxed app would need exceptions to script Spotify and Music, to run the socket Claude Code's hooks reach, and to edit `~/.claude/settings.json`. Hardened Runtime is on, and the app has only the entitlements in [Cumba.entitlements](../Cumba/Resources/Cumba.entitlements) (Apple Events, calendars, location, camera).

Cumba never sends telemetry, asks for no administrator password, installs no helper tools, kernel or system extensions, doesn't change system settings, and never downloads code or updates itself. [SECURITY.md](../SECURITY.md) has the threat model and a map of the security-relevant code.

## Media, brightness and private APIs

macOS has no public way for an app to see what other apps play or to read the built-in display's brightness on Apple silicon. Cumba uses two private Apple frameworks for exactly these, and nothing else:

- **MediaRemote**, the system's Now Playing (what the media keys and Control Center use). macOS answers it only for Apple's own programs, so Cumba runs a small helper library from its own app bundle ([source](../NowPlayingHelper/CumbaNowPlaying.m)) inside the system's `/usr/bin/perl`, started with an empty environment. The helper only reads Now Playing and passes on play, pause, skip and seek; it opens no files or network connections and exits when Cumba quits. Turn off **Settings > Widgets > Media > Read media from every app** to use AppleScript for Spotify and Music and the extension for YouTube instead.
- **DisplayServices**, only for the brightness level in the notch. Turn off **Settings > General > Show brightness changes in the notch** to stop using it.

Private APIs can change with any macOS update. If they stop working, Cumba keeps running: media falls back to the public ways above, and the brightness level just isn't shown.
