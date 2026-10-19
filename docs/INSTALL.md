# Install ShiftPad on Windows

ShiftPad lets you shift gears in MyWhoosh with your Zwift Click V2 controllers.

## What you need

- A Windows 10 or 11 PC with Bluetooth.
- MyWhoosh installed on the same PC.
- A pair of Zwift Click V2 controllers.

## Install

1. Unzip `ShiftPad-windows-<version>.zip` into a folder, for example `C:\ShiftPad`.
2. Open the folder and run `shiftpad.exe`.
3. If Windows asks about the firewall, press **Allow**. MyWhoosh needs this to talk to ShiftPad.

Nothing else to install: no Bonjour, no account, no command limit.

## First start

ShiftPad shows a short guide:

1. **Close Zwift and Zwift Companion** (also on your phone). A controller can talk to only one app at a time.
2. Press a button on each controller to wake it up.
3. Choose **Both controllers** (+ shifts up, − shifts down) or **Right controller only** (+ shifts up, B shifts down).
4. In MyWhoosh, open **Connection**, choose **OpenBikeControl**, pick **ShiftPad**, and press **Yes**.
5. Press **+**: your gear in MyWhoosh goes up.

## Good to know

- Keep ShiftPad open while you ride. You can minimise it.
- If MyWhoosh is not connected over OpenBikeControl, ShiftPad uses **keyboard mode** (K = shift up, I = shift down). This needs the MyWhoosh window open (not minimised).
- With only one controller connected, ShiftPad restarts it after 55 seconds without a press, so Windows does not drop it. It comes back in about 10 seconds.
- Change what each button does in the menu: **Button mapping**.
- Something wrong? The menu has **Troubleshooting**. **Diagnostics → Export logs** saves a file in `Documents\ShiftPad` that you can send for help.
