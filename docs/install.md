# Install, update and uninstall

Back to the [README](../README.md) · [Türkçe](install.tr.md)

## Requirements

- A Mac with a notch (other Macs can show a virtual notch, see Settings > General)
- macOS 26 or later

## With Homebrew

```bash
brew install --cask ljasp-studio/cumba/cumba
```

The cask lives in [LJASP-studio/homebrew-cumba](https://github.com/LJASP-studio/homebrew-cumba). It installs the same `.dmg` from the latest release after checking its SHA-256, then removes macOS's download flag from Cumba.app, so there's no Open Anyway step ([what that warning means](safety.md#why-macos-warns)). A new version reaches the cask only after its checksum and build provenance pass. Then go on at step 5 below; later, update with `brew upgrade --cask cumba`.

## By hand

1. Get `Cumba-vX.Y.Z.dmg` (or the `.zip`) from [cumbanotch.com](https://cumbanotch.com) or the [latest release](https://github.com/LJASP-studio/Cumba/releases/latest).
2. **Check the download before opening it.** Its SHA-256 must match the one in `SHA256SUMS.txt` on the release page:
   ```bash
   shasum -a 256 ~/Downloads/Cumba-vX.Y.Z.dmg
   ```
   From 1.1.0 on, releases are also immutable (files and tag can't change after publishing) and carry signed build provenance. With the [GitHub CLI](https://cli.github.com) you can confirm the file was built from this repository by its release workflow:
   ```bash
   gh attestation verify ~/Downloads/Cumba-vX.Y.Z.dmg --repo LJASP-studio/Cumba
   ```
   1.1.0 was built before the repository moved to LJASP-studio, so check it with `--owner muazfurkan` instead of `--repo`.
3. Open the disk image and drag Cumba to Applications.
4. Cumba isn't notarized by Apple, because that needs a paid developer account, so macOS blocks the first launch ([what the warning means](safety.md#why-macos-warns)). Open it once, then click **Open Anyway** in **System Settings > Privacy & Security**. If you'd rather not run a downloaded build at all, [build it from source](#build-from-source).
5. A short welcome lets you try the panel. Cumba lives in the menu bar; if its icon hides behind the notch, right-click the notch for Settings.

<details>
<summary>Terminal alternative to Open Anyway</summary>

`xattr -dr com.apple.quarantine /Applications/Cumba.app` removes the download flag from this one app, so Gatekeeper stops asking. Only do this for a copy you checked in step 2.
</details>

## Updates

The app tells you when a new version is out; it never downloads or installs anything itself. Release builds are signed ad hoc, so after an update macOS asks again for the permissions you gave (Automation, Calendar, Location, Camera) and for Keychain access to Cumba's tokens. Check the new download first, then allow.

## Coming from cumbaNotch

Cumba is the same app under a new name. Quit cumbaNotch, move the old app to the Trash and install Cumba; your settings, layout, notes and themes carry over. If you use Claude Code hooks, click **Update…** once in Settings > Agents. If you use the Chrome extension, remove it in `chrome://extensions`, load it again from the new app as in [YouTube extension](features.md#youtube-extension-optional) and paste the token.

## Build from source

You need Xcode 26 or later and [Homebrew](https://brew.sh).

```bash
brew install xcodegen
git clone https://github.com/LJASP-studio/Cumba.git
cd Cumba
cp Local.xcconfig.example Local.xcconfig   # then set your DEVELOPMENT_TEAM
xcodegen generate
open Cumba.xcodeproj
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for details.

## Uninstall

1. If you installed the Claude Code or Codex hooks, remove them first in **Settings > Agents > Remove…** (for each agent). Hooks left behind do nothing once the app is gone, but they stay in `~/.claude/settings.json` and `~/.codex/hooks.json`.
2. Turn off **Launch at login** in Settings > General, quit Cumba from the menu bar and move it to the Trash. If you installed it with Homebrew, run `brew uninstall --cask cumba` instead; `--zap` also deletes its settings, themes and notes (not the tokens in step 4).
3. Remove the extension in `chrome://extensions`.
4. To delete its data too (themes, layout, notes, preferences and the tokens):
   ```bash
   rm -rf ~/Library/Application\ Support/Cumba
   defaults delete io.github.muazfurkan.ljaspnotch
   security delete-generic-password -s io.github.muazfurkan.ljaspnotch.server -a token
   security delete-generic-password -s io.github.muazfurkan.ljaspnotch.server -a extension-token
   security delete-generic-password -s io.github.muazfurkan.ljaspnotch.server -a scripts-token
   ```
   Backups made during hook setup are next to the files they back up, as `~/.claude/settings.json.bak-…` and `~/.codex/hooks.json.bak-…`; keep or delete them.
