# ShiftPad

ShiftPad reads the buttons of a pair of Zwift Click V2 controllers over Bluetooth and turns them into virtual gear shifts (and other actions) in MyWhoosh. It works on a single Windows PC, next to MyWhoosh, without installing Bonjour or any other third-party software, and without any command limit.

- Sends shifts to MyWhoosh over **OpenBikeControl** (network, announced with the mDNS support built into Windows), with an automatic **keyboard** fallback.
- Right controller only, or both controllers, with configurable buttons.
- Reconnects the controllers by itself. Diagnostics screen with log export.

Install for riders: see [docs/INSTALL.md](docs/INSTALL.md).

## Development

- Build: `flutter build windows --release`
- Package: `powershell -File tool/package_windows.ps1` → `dist\ShiftPad-windows-<version>.zip`
- Tests: `flutter test`, lint: `flutter analyze`
- Check the mDNS announcement: `python -I tool/mdns_browse.py` (needs `pip install zeroconf`)
- Design: [docs/superpowers/specs](docs/superpowers/specs), hardware findings: [docs/testing/findings.md](docs/testing/findings.md)

Stopping `flutter run` can leave `shiftpad.exe` running. Run `taskkill /IM shiftpad.exe /F` before the next run, or the OpenBikeControl port stays taken.
