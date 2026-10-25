#!/usr/bin/env python3
"""Exercise installer failure/rollback behavior with fake tools in temp folders.

Run on macOS with Python 3. These tests do not download, mount, sign, or launch
an app. Real Apple verification is a separate integration check.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]

FAKE_TOOL = r'''
import os, pathlib, plistlib, shutil, sys
tool = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
root = pathlib.Path(os.environ['GROK_TEST_ROOT'])
scenario = os.environ.get('GROK_TEST_SCENARIO', '')
mount_record = root / 'mount-record'
if tool == 'uname':
    print('Darwin' if args == ['-s'] else ('arm64' if scenario == 'arm' else 'x86_64'))
elif tool == 'sysctl':
    print('1' if scenario == 'rosetta' else '0')
elif tool == 'sw_vers':
    print('15.7.7')
elif tool == 'ps':
    if scenario == 'running':
        print('/Applications/Grok Bot.app/Contents/MacOS/Grok Bot')
elif tool == 'file':
    print('Mach-O 64-bit executable x86_64')
elif tool == 'hdiutil':
    if args[0] == 'attach':
        mount = pathlib.Path(args[args.index('-mountpoint') + 1])
        mount_record.write_text(str(mount))
        app = mount / 'Grok Bot.app'
        (app / 'Contents' / 'MacOS').mkdir(parents=True)
        (app / 'Contents' / 'MacOS' / 'Grok Bot').write_text('new app fixture')
        with (app / 'Contents' / 'Info.plist').open('wb') as stream:
            plistlib.dump({'CFBundleIdentifier':'com.anysphere.sand',
                          'CFBundleExecutable':'Grok Bot',
                          'CFBundleShortVersionString':'0.75.8',
                          'LSMinimumSystemVersion':'12.0'}, stream)
    elif mount_record.exists():
        mount_record.unlink()
elif tool == 'mount':
    if mount_record.exists():
        print('/dev/fake on ' + mount_record.read_text() + ' (apfs, read-only)')
elif tool == 'codesign':
    app = pathlib.Path(args[-1])
    source = app.parent.name == 'mounted'
    staged = '.grokbot-stage.' in str(app)
    installed = app.parent == root / 'Applications'
    if ((scenario == 'source_failure' and source)
        or (scenario == 'staged_failure' and staged)
        or (scenario == 'installed_failure' and installed)):
        sys.exit(1)
elif tool == 'spctl':
    if scenario == 'gatekeeper_failure':
        sys.exit(1)
elif tool == 'ditto':
    if scenario == 'copy_failure':
        pathlib.Path(args[1]).mkdir()
        (pathlib.Path(args[1]) / '.copy-partial').write_text('partial')
        sys.exit(1)
    shutil.copytree(args[0], args[1])
elif tool == 'open':
    (root / 'opened').write_text('called')
else:
    raise RuntimeError(tool)
'''


@unittest.skipUnless(sys.platform == 'darwin', 'Uses macOS PlistBuddy')
class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='grokbot-test-')
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        launcher = self.bin / 'fake-tool'
        launcher.write_text('#!' + sys.executable + '\n' + FAKE_TOOL)
        launcher.chmod(0o755)
        for tool in ['uname', 'sysctl', 'sw_vers', 'ps', 'file', 'hdiutil',
                     'mount', 'codesign', 'spctl', 'ditto', 'open']:
            (self.bin / tool).symlink_to(launcher)
        self.app_dir = self.root / 'Applications'
        self.app_dir.mkdir()
        self.app = self.app_dir / 'Grok Bot.app'
        self.dmg = self.root / 'fixture.dmg'
        self.dmg.write_text('test-only fixture')
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                        GROK_TEST_ROOT=str(self.root), TMPDIR=str(self.root))

    def tearDown(self):
        self.temp.cleanup()

    def previous_app(self):
        self.app.mkdir()
        (self.app / 'old-marker').write_text('keep this app')

    def run_installer(self, scenario='', extra=()):
        env = dict(self.env, GROK_TEST_SCENARIO=scenario)
        result = subprocess.run(['/bin/bash', str(REPO / 'install-grokbot-intel.sh'),
                                 '--dmg', str(self.dmg), '--app-dir', str(self.app_dir),
                                 '--no-open', *extra], env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertFalse((self.root / 'mount-record').exists(), result.stdout)
        self.assertEqual(list(self.app_dir.glob('.grokbot-stage.*')), [], result.stdout)
        self.assertEqual(list(self.root.glob('grokbot-install.*')), [], result.stdout)
        self.assertFalse((self.root / 'opened').exists(), result.stdout)
        return result

    def test_new_install(self):
        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.app / 'Contents/Info.plist').is_file(), result.stdout)
        self.assertEqual(list(self.app_dir.glob('Grok Bot Backup.*')), [])

    def test_update_preserves_backup(self):
        self.previous_app()
        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stdout)
        backups = list(self.app_dir.glob('Grok Bot Backup.*/Grok Bot.app/old-marker'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'keep this app')
        self.assertFalse((self.app / 'old-marker').exists())

    def test_failures_preserve_previous_app(self):
        for scenario in ['source_failure', 'gatekeeper_failure', 'copy_failure',
                         'staged_failure', 'installed_failure']:
            with self.subTest(scenario=scenario):
                self.previous_app()
                result = self.run_installer(scenario)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual((self.app / 'old-marker').read_text(), 'keep this app')
                self.assertEqual(list(self.app_dir.glob('Grok Bot Backup.*')), [])
                shutil.rmtree(self.app)

    def test_verify_only_keeps_existing_app(self):
        self.previous_app()
        result = self.run_installer(extra=['--verify-only'])
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.app / 'old-marker').read_text(), 'keep this app')

    def test_wrong_architecture_and_running_app_stop_early(self):
        self.previous_app()
        for scenario in ['arm', 'rosetta', 'running']:
            with self.subTest(scenario=scenario):
                result = self.run_installer(scenario)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual((self.app / 'old-marker').read_text(), 'keep this app')

    def test_symlink_destination_is_refused(self):
        preserved = self.root / 'preserved'
        preserved.mkdir()
        self.app.symlink_to(preserved)
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertTrue(self.app.is_symlink())

    def test_version_comparison_rejects_expressions(self):
        cases = [('15.7.7', '12.0', True), ('12', '12.0.0', True),
                 ('12.08', '12.7', True), ('11.9', '12.0', False),
                 ('15.7.7', '12.x', False), ('15.7.7', '12.0.1+1', False),
                 ('15.7.7', '12.0.$(touch forbidden)', False)]
        for actual, required, expected in cases:
            with self.subTest(actual=actual, required=required):
                result = subprocess.run(['/bin/bash', '-c',
                    'source "$1"; version_at_least "$2" "$3"', 'test',
                    str(REPO / 'lib/common.sh'), actual, required], cwd=self.root)
                self.assertEqual(result.returncode == 0, expected)
        self.assertFalse((self.root / 'forbidden').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
