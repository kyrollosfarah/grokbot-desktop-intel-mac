# Grok Bot for Intel iMacs and Intel Macs (x86_64)

Install the official Intel build of **Grok Bot** with a step-by-step guide, reusable install/update scripts, and checks for the app's signature and architecture.

**Working installation confirmed:** Intel Mac (`x86_64`), macOS **15.7.7 Sequoia**, Grok Bot **0.75.8**, on **October 25, 2026**. The user confirmed that the app works after installation. This release declares macOS **12.0** as its minimum; older supported macOS versions have not been tested here.

This is a community setup guide by Kyrollos Farah, following the format of [Hermes Desktop for Intel Macs](https://github.com/kyrollosfarah/hermes-desktop-intel-mac). Grok Bot already provides an official Intel app, so the installer downloads that signed app directly.

## Quick links

- [Download the setup scripts and guide](https://github.com/kyrollosfarah/grokbot-desktop-intel-mac/releases/latest)
- [Official Intel DMG — verified version 0.75.8](https://downloads.cursor.com/grokbot/stable/darwin-x64/0.75.8/Grok_Bot_0.75.8_x64.dmg)
- [Official downloads — choose More downloads → macOS Intel](https://x.ai/bot)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Installation and verification record](docs/VERIFIED-INSTALL.md)

## Which Mac is this for?

Open **Apple menu → About This Mac** and look for an Intel processor. The scripts also reject an Apple silicon Mac running Terminal under Rosetta.

In Terminal:

```bash
uname -m
sw_vers -productVersion
```

An Intel Mac normally reports `x86_64`. For Apple silicon, choose the appropriate download at [x.ai/bot](https://x.ai/bot).

## What is included?

| File | Purpose |
|---|---|
| `install-grokbot-intel.sh` | Download, verify, install, and open the official Intel app. |
| `update-grokbot-intel.sh` | Install the latest Intel release, keeping the previous app as a backup. |
| `verify-grokbot-intel.sh` | Check an installed app without changing it. |
| `lib/common.sh` | Shared compatibility and signature checks; keep this with the scripts. |
| `docs/TROUBLESHOOTING.md` | Installation, launch, sign-in, and interrupted-copy fixes. |
| `docs/VERIFIED-INSTALL.md` | Tested environment, download checksum, and validation evidence. |
| `releases/verified-0.75.8.json` | Metadata for the exact installer used successfully. |
| `releases/SHA256SUMS-0.75.8.txt` | SHA-256 of that official DMG. |
| `tests/test_installer.py` | Isolated tests of installation guards, clean copying, and rollback. |

The GitHub release bundles this guide and its scripts. The Grok Bot application is downloaded from its publisher; the DMG is linked above and is not included in the source archive.

## Fast path

1. Download **GrokBot-Intel-Mac-Setup-v1.0.0.zip** from [Releases](https://github.com/kyrollosfarah/grokbot-desktop-intel-mac/releases/latest), then double-click it to extract the folder.
2. Open **Terminal** and enter the extracted folder. If it is in Downloads:

   ```bash
   cd ~/Downloads/grokbot-desktop-intel-mac
   bash install-grokbot-intel.sh
   ```

3. When the app opens, choose **Sign in** and complete the account flow in your browser.

If you already use Git, you can instead run:

```bash
git clone https://github.com/kyrollosfarah/grokbot-desktop-intel-mac.git
cd grokbot-desktop-intel-mac
bash install-grokbot-intel.sh
```

Quit Grok Bot with **Command-Q** before running the installer or updater. Keep all downloaded files together so the scripts can find `lib/common.sh`. The ZIP method needs only macOS's built-in tools; Git, Homebrew, Node.js, and Python are not prerequisites for the installer.

### Installer options

```bash
# Inspect the current official Intel release without changing your installed app:
bash install-grokbot-intel.sh --verify-only

# Use a DMG you already downloaded from the publisher:
bash install-grokbot-intel.sh --dmg "$HOME/Downloads/Grok_Bot_0.75.8_x64.dmg"

# Install for your user if you cannot write to /Applications:
bash install-grokbot-intel.sh --app-dir "$HOME/Applications"

# Install without opening it:
bash install-grokbot-intel.sh --no-open
```

The default resolves the current stable release from the publisher's Intel feed. Version 0.75.8 records the successful installation; later releases can change compatibility. `--dmg` still checks the app signature, developer identity, Intel executable, and minimum macOS version.

## Manual installation, step by step

### Step 1: Download the Intel installer

Open [x.ai/bot](https://x.ai/bot), find **More downloads**, and select **macOS Intel / x64**. The filename for the verified version is `Grok_Bot_0.75.8_x64.dmg`.

### Step 2: Open the disk image

Double-click the downloaded `.dmg`. macOS mounts an installer volume in Finder.

### Step 3: Copy the app

Drag **Grok Bot.app** into **Applications**. Wait until the copy finishes before ejecting the disk image or opening the app. If replacing an existing installation, quit Grok Bot first and keep a copy of the old app if you want a rollback option.

### Step 4: Open and sign in

Open **Applications → Grok Bot**, then select **Sign in**. Follow the browser flow and return to the app. Access requires an eligible account plan; consult the [official setup guide](https://docs.x.ai/grok-bot/get-started) for current eligibility and account-linking instructions.

### Step 5: Verify the installation

From this repository's folder:

```bash
bash verify-grokbot-intel.sh
```

For a per-user installation:

```bash
bash verify-grokbot-intel.sh "$HOME/Applications/Grok Bot.app"
```

A successful check reports the version and Intel compatibility; Apple's assessment reports acceptance. The script exits with an error if verification fails.

### Step 6: Eject the installer

In Finder, click the eject button next to the Grok Bot installer volume. You can keep or discard the downloaded DMG after the installed app works.

## Updating later

Use the app's update feature, or quit the app and run:

```bash
bash update-grokbot-intel.sh
```

For a per-user installation, use the same `--app-dir "$HOME/Applications"` option you used initially. The updater accepts all installer options.

Before replacing an app, the script verifies a fresh copy in a temporary sibling directory. It then moves the old app into `Grok Bot Backup.<random>/Grok Bot.app` in the same installation directory. A failed replacement attempts to restore that backup. The printed backup path can be removed in Finder after you confirm the new version works. It backs up the application bundle, not account data or settings.

## How the automated checks work

- Require macOS on Intel, including a check for Rosetta.
- Restrict the release download to the expected official Intel URL format.
- Mount the disk image read-only, then check the app's identity and Intel executable.
- Check the current macOS version against the app's declared minimum.
- Validate code signatures and Apple's expected developer Team ID `DCNK4UB866`.
- Require a successful Gatekeeper assessment before installation and after copying.
- Stage a fresh app copy, preserving the current installation until the copy verifies.

These identity checks reflect the official 0.75.8 app. If the publisher changes its signing identity or download format, the installer stops for review. It never disables Gatekeeper or clears quarantine attributes.

## Uninstall

Quit Grok Bot, then move **Grok Bot.app** from your installation directory to Trash in Finder. Remove any `Grok Bot Backup.*` folders you no longer need. This removes the app; it does not delete your account or cloud data, cancel a plan, or erase local application settings.

## Sources

- [Official downloads](https://x.ai/bot)
- [Official setup and sign-in guide](https://docs.x.ai/grok-bot/get-started)
- [Official deployment and release-feed documentation](https://docs.x.ai/grok-bot/deployment)
- [Official Intel release feed](https://api2.cursor.sh/updates/api/download/stable/darwin-x64/sand)

## License

The original scripts and documentation in this repository are MIT licensed. Grok Bot and its trademarks belong to their respective owners and remain subject to the publisher's terms. This repository is not an official distribution of Grok Bot.
