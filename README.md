<p align="center"><img src="docs/banner.png" alt="The Cumba panel open below the notch, showing a mini player"></p>

<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/cumba-dark.svg">
    <img src="docs/cumba-light.svg" alt="Cumba" width="300">
  </picture>
</h1>

<p align="center"><sub>by LJASP · formerly cumbaNotch</sub></p>

<p align="center">
  <a href="https://github.com/LJASP-studio/Cumba/releases/latest"><img src="https://img.shields.io/github/v/release/LJASP-studio/Cumba?label=download&color=DCB669" alt="Latest release"></a>
  <a href="https://github.com/LJASP-studio/Cumba/actions/workflows/build.yml"><img src="https://github.com/LJASP-studio/Cumba/actions/workflows/build.yml/badge.svg?branch=main" alt="Build status"></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-111111?logo=apple" alt="macOS 26 or later">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/LJASP-studio/Cumba?color=111111" alt="MIT license"></a>
</p>

<p align="center"><a href="https://cumbanotch.com">cumbanotch.com</a> · <a href="README.tr.md">Türkçe</a></p>

<p align="center"><img src="docs/demo.gif" width="800" alt="Cumba in use: the panel opens with music and the weather, Claude Code asks to edit a file and gets Allow from the notch, then clipboard history and the volume level beside the notch"></p>

Cumba is a free, open source notch app for macOS. Rest the pointer on the MacBook notch and a panel opens below it with what's playing, what Claude Code and Codex are doing, and the widgets you chose.

A *cumba* is the small bay window that juts out from the upper floor of old Turkish houses: a quiet place to sit and watch the street. The panel does the same from the top of your screen.

## What you get

- A mini player for whatever is playing, in any app: Spotify, Music, YouTube in Safari or Chrome, podcasts. Artwork, seeking and controls, with nothing to set up.
- Claude Code and Codex in the notch. You see what the agent is doing and answer its permission requests with Allow, Deny or In Terminal without leaving the window you're in. For Claude Code you also see how full the context window is.
- Widgets in tabs: a calendar with a Join button for calls, Apple Notes, Reminders, clipboard history, timer and Pomodoro, weather, a file tray with AirDrop and more.
- Eight themes, from plain black and Liquid Glass to Neon Tokyo and Synthwave. You can also make your own with glass, gradients, a neon edge, colors and fonts, and share it as JSON.
- Live activities beside the closed notch: a running timer, a working agent, charging, the current song, volume and brightness.
- Cumba lets clicks through to the menu bar, works in full-screen apps and uses next to no CPU while idle.
- English, Spanish, French and Turkish.

You decide what the notch shows: which widgets, in which tabs and order, in which theme. You also choose which agent requests you can allow from the notch. By default that's everything except shell commands, and you can widen it or turn Allow off. Extras such as replacing the volume indicator stay off until you turn them on, and Cumba asks for macOS permissions only when you turn on a feature that needs one.

Every widget and option is listed in [Features](docs/features.md).

## Download and install

Install with [Homebrew](https://brew.sh):

```bash
brew install --cask ljasp-studio/cumba/cumba
```

Or download the `.dmg` from [cumbanotch.com](https://cumbanotch.com) or the [latest release](https://github.com/LJASP-studio/Cumba/releases/latest) and drag Cumba to Applications. You need macOS 26 or later. Macs without a notch can show a virtual one.

<a name="why-macos-warns"></a>

Cumba isn't notarized by Apple, because that needs a paid developer account, so macOS blocks the first launch of a downloaded copy. Open it once, then click **Open Anyway** in **System Settings > Privacy & Security**. If you install with Homebrew, it checks the download and you can skip this step. [What the warning means](docs/safety.md#why-macos-warns)

Cumba's icon sits in the menu bar. If it hides behind the notch, right-click the notch for Settings.

<a name="uninstall"></a>

Checking the download, updates, moving from cumbaNotch, building from source and uninstalling are covered in [Install, update and uninstall](docs/install.md).

## Is it safe?

Cumba is new (first release October 2026). One person makes it, much of the code is written with Claude Code, and no outside firm has audited it yet. You don't have to take anyone's word for it, though. The whole app is open source in this repository, every change has to pass CI before it reaches `main`, and GitHub builds the releases from tagged commits, with signed provenance you can verify.

[Is Cumba safe?](docs/safety.md) explains the macOS warning and gives the commands to check all of this yourself. [Privacy and permissions](docs/privacy.md) lists what Cumba can reach on your Mac. To report a problem privately, see [SECURITY.md](SECURITY.md).

## Privacy

Cumba sends no telemetry. These are the only features that go online:

| Feature | Talks to |
|---|---|
| Spotify artwork in the media player | `i.scdn.co` |
| YouTube thumbnails in the media player | `*.ytimg.com`, `*.googleusercontent.com`, `*.ggpht.com` |
| Weather, while the widget is on screen | `api.open-meteo.com` with your location rounded to about 10 km (or the city you choose), `geocoding-api.open-meteo.com` for city search, Apple Maps for the city name |
| Update check | `api.github.com` at launch and once a day; you can turn it off in Settings > General |

What each request contains is in [Privacy and permissions](docs/privacy.md).

## Support

Cumba is free. If it's useful to you, you can support it on [GitHub Sponsors](https://github.com/sponsors/muazfurkan) or [Buy Me a Coffee](https://buymeacoffee.com/ljasp).

## Contributing

Questions and ideas are welcome in [Discussions](https://github.com/LJASP-studio/Cumba/discussions). If you'd like to contribute code, please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately as described in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
