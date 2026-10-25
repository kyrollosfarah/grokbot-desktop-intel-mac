# Validation — 2026-10-25

Performed on an Intel Mac running macOS 15.7.7.

- Bash syntax checks passed for the installer, updater, verifier, and shared library.
- `verify-grokbot-intel.sh` passed on the working `/Applications/Grok Bot.app` installation.
- `install-grokbot-intel.sh --verify-only --dmg <official-0.75.8-DMG>` passed and cleaned up its mounted volume.
- `install-grokbot-intel.sh --verify-only` fetched the current official feed, downloaded 0.75.8, checked its signature and publisher identity, passed Apple's Gatekeeper assessment, and cleaned up the mounted volume and temporary directory. It left the working app untouched.
- Six automated test methods passed, including subcases for source-signature failure, Gatekeeper rejection, interrupted copying, staged-copy verification failure, and final verification failure with rollback.
- Additional test cases covered fresh installation, preservation of an update backup, verification-only behavior, running-app refusal, Apple silicon/Rosetta refusal, and symlink-destination refusal.
- The package manifest, checksum file, and referenced local files were checked for consistency.

The automated lifecycle tests use fake platform, signing, and mounting commands in temporary directories. They test control flow and file preservation; they do not prove an Apple signature. Real signing and download checks were performed separately as described above. The installed app was not replaced to test this release's installer.

To run the lifecycle tests on macOS with Python 3:

```bash
python3 tests/test_installer.py
```

Python is needed only for these development tests, not for installing Grok Bot.
