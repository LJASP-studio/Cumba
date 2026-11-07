# Is Cumba safe?

Back to the [README](../README.md) · [Türkçe](safety.tr.md)

People usually ask two things first: *"Wasn't this written by an AI?"* and *"Why does macOS warn me about it?"* Both are answered below, with a way to check each claim yourself.

## Written with AI, checked like any code

Cumba is designed and maintained by one person, and much of its code is written with Claude Code. Code written with AI can have the same mistakes as any other code, so Cumba is set up so that you don't have to trust whoever wrote it:

- All of it is open. The whole app is in this repository under the MIT license. There's no closed part, and the app never downloads code later.
- Nothing reaches `main` unchecked. Every change comes through a pull request that must build, pass more than 200 unit tests, a strict format check and a Release build on GitHub's machines before it can merge. Direct pushes, force pushes and history rewrites on `main` are blocked for everyone, the maintainer included.
- The files you download come from GitHub, not from a laptop. Releases are built only by the [release workflow](../.github/workflows/release.yml), from a tagged commit, on a GitHub-hosted Mac with read-only access. Each file carries signed build provenance that ties it to this repository and that commit, and releases can't be changed after publishing.
- There's little to go wrong: one third-party library ([FlyingFox](https://github.com/swhitty/FlyingFox), MIT, pinned to a commit), no analytics or ad SDKs, no telemetry. Workflows may use only GitHub's own actions, pinned to commits. Secret scanning, push protection and Dependabot security updates are on, and CodeQL scans the Chrome extension, the workflows and the scripts every week.
- Security work is on the record. The [CHANGELOG](../CHANGELOG.md) lists the security fixes in each release. [SECURITY.md](../SECURITY.md) has the threat model and a map of the security-relevant code, about a dozen files, for anyone who wants to review it.
- What's missing: no independent firm has audited Cumba yet. If you find a problem, please report it privately as described in [SECURITY.md](../SECURITY.md).

## Why macOS warns

On first launch, macOS says Apple could not verify that Cumba is free of malware. It says the same about every app that isn't notarized. Notarization is Apple's automated malware scan, and it's only available for apps signed with a paid Apple Developer ID. Cumba doesn't have one, so its releases are signed ad hoc.

- The warning means Apple hasn't scanned this build. It doesn't mean anything was found.
- XProtect, the malware protection built into macOS, still checks Cumba at first launch, as it does every app.
- In place of Apple's scan, you can check something notarization doesn't show: that your download was built by GitHub from this public code (the first row below).

## Check it yourself

A few commands in Terminal; the first needs the [GitHub CLI](https://cli.github.com).

| Claim | Command | What you should see |
|---|---|---|
| GitHub built the file from this repository | `gh attestation verify ~/Downloads/Cumba-vX.Y.Z.dmg --repo LJASP-studio/Cumba` | `Verification succeeded!` |
| It's the file the release lists | `shasum -a 256 ~/Downloads/Cumba-vX.Y.Z.dmg` | The value in the release's `SHA256SUMS.txt` |
| It has only the entitlements in [Cumba.entitlements](../Cumba/Resources/Cumba.entitlements) | `codesign -d --entitlements - /Applications/Cumba.app` | App Sandbox off, then Apple Events, camera, calendars and location; nothing else |
| Hardened Runtime is on | `codesign -dv /Applications/Cumba.app 2>&1 \| grep flags` | `runtime` among the flags |
| No other device can connect to it | `lsof -nP -iTCP -sTCP:LISTEN \| grep Cumba` | No output; with the YouTube extension on, `127.0.0.1` only |
| It talks only to the servers in [Privacy](privacy.md#what-goes-online) | `nettop -p Cumba`, or an outbound firewall such as LuLu or Little Snitch | `api.github.com` for the update check; weather and artwork servers only while you use them |
| Nothing keeps running after you quit | Quit Cumba, then `pgrep -fl Cumba` | No output |
| It installs nothing that runs in the background | `ls ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons` | No Cumba file; launch at login uses the macOS login items list, under Cumba's own name |

What Cumba can reach on your Mac is listed in [Permissions and what runs](privacy.md#permissions-and-what-runs). If you'd rather not run a prebuilt app at all, [build it from source](install.md#build-from-source).
