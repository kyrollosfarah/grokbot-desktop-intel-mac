# Verified installation record

## Working application

| Item | Observed value |
|---|---|
| Verification date | 2026-10-25 |
| Architecture | `x86_64` (Intel) |
| Operating system | macOS 15.7.7 Sequoia, build 24G720 |
| Grok Bot version | 0.75.8 |
| Install location | `/Applications/Grok Bot.app` |
| App bundle ID | `com.anysphere.sand` |
| Developer Team ID | `DCNK4UB866` |
| Declared minimum macOS | 12.0 |
| App executable | `Grok Bot`, Mach-O x86_64 |
| Apple assessment of downloaded app | Accepted; Notarized Developer ID |
| Installed signature verification | Passed after repairing the interrupted copy |
| User confirmation | User reported the app was working |

The source DMG came from the [publisher's Intel release feed](https://api2.cursor.sh/updates/api/download/stable/darwin-x64/sand). Its URL was:

```text
https://downloads.cursor.com/grokbot/stable/darwin-x64/0.75.8/Grok_Bot_0.75.8_x64.dmg
```

The SHA-256 of the downloaded file is:

```text
48175e9f6cd549227e83a5639ac661bd2a087901230d1f262a533f3d85aefb64
```

This checksum was calculated locally from the verified download; it is not a separately published publisher checksum. The app's Apple code signature and Gatekeeper acceptance provide the publisher-identity checks.

To compare a downloaded copy with the recorded file, run this from the folder containing the DMG, using the checksum file from this repository:

```bash
shasum -a 256 -c /path/to/grokbot-desktop-intel-mac/releases/SHA256SUMS-0.75.8.txt
```

## Scope

The app was installed and launched on the environment above. Account sign-in is performed by the user. No credentials, account data, browser profiles, local application settings, or app binaries are included in this repository. No compatibility test on macOS 12–14 or Apple silicon is claimed.

See [VALIDATION.md](../VALIDATION.md) for checks performed on the published scripts.
