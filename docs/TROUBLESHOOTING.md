# Troubleshooting Grok Bot on Intel Macs

## “This application is not supported on this Mac”

Check **Apple menu → About This Mac** and `uname -m`. An Intel Mac needs the **Intel / x64** download. The verified 0.75.8 app declares macOS 12.0 as its minimum. A newer release may require a newer operating system.

## The installer asks me to quit Grok Bot

Use **Grok Bot → Quit Grok Bot**, or **Command-Q**, and rerun the command. The installer stops if it detects a running app to avoid replacing files in use. It does not force-quit your session.

## Permission denied while copying into Applications

Use Finder to drag the app into Applications and follow any macOS authentication prompt, or install for your user:

```bash
bash install-grokbot-intel.sh --app-dir "$HOME/Applications"
```

Use this same directory for future scripted updates. You do not need to run the entire installer as root.

## Signature, Gatekeeper, or “damaged app” error

Download a fresh installer from [the official page](https://x.ai/bot) and check it with:

```bash
bash install-grokbot-intel.sh --dmg "$HOME/Downloads/Grok_Bot_0.75.8_x64.dmg" --verify-only
```

Replace the filename with the one you downloaded. If the downloaded app fails verification, stop and check with the publisher. Do not disable macOS security settings to make it launch.

If verification succeeds for the DMG but fails for the installed app, the copy may have been interrupted. Quit the app and rerun the installer; it stages a clean copy instead of merging files into the existing bundle.

## Interrupted copy or “a sealed resource is missing or invalid”

During the original installation documented here, an interrupted copy left a temporary `.BC.T_*` file inside the Electron framework. Recopying over the same directory left that extra file behind. Signature verification identified the exact extra file; removing that specific copy artifact restored verification.

The scripts avoid this failure by copying into a new staging directory. Do not remove arbitrary files from the installed bundle. Use the clean reinstall procedure instead.

A force quit of the installer, power failure, or `kill -9` can prevent cleanup. In your installation directory, inspect `.grokbot-stage.*` and `Grok Bot Backup.*` folders in Finder (**Command-Shift-.** reveals hidden files). If the app is missing, restore the `Grok Bot.app` from the backup folder to the installation directory, then verify it. Keep the backup until a working replacement is confirmed.

## Download fails or the URL format changed

Check your internet connection and try again. The automated installer accepts only the expected official Intel download format. If the publisher changes the release feed or signing identity, use the [official download page](https://x.ai/bot) and review the script before changing its checks.

To inspect the release feed without installing:

```bash
curl -fL https://api2.cursor.sh/updates/api/download/stable/darwin-x64/sand
```

## App launches but sign-in or access fails

Installation and account access are separate steps. Complete the browser sign-in flow, return to the app, and check the [official account requirements](https://docs.x.ai/grok-bot/get-started). If you use a linked subscription, follow the linking instructions in that guide. Reinstalling the app does not purchase or activate a plan.

## Blank window or app closes after launch

Quit and reopen Grok Bot, run `bash verify-grokbot-intel.sh`, and check for an official update. If verification passes but the issue continues, use the publisher's support channel. This repository does not include a confirmed fix for blank-window issues.

## Roll back a scripted update

1. Quit Grok Bot.
2. In Finder, move the current `Grok Bot.app` aside.
3. Move `Grok Bot.app` from the backup folder printed by the installer back into Applications (or your selected installation directory).
4. Run the verification script, then open the app.

Older versions may eventually require an update to access the service. The backup is an application rollback, not a backup of settings or cloud data.
