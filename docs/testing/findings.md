# Hardware findings

## Checkpoint A: Click V2 on the real pods (2026-10-19)

Setup: bike PC (Windows 11), ShiftPad debug build (`flutter run -d windows`), Zwift launcher and Zwift Companion closed. The pods had **not** been used with any Zwift app that day. Both pods report firmware 1.2.0.

Logs (in `Documents\ShiftPad` on the bike PC, not committed because they contain the pods' Bluetooth addresses):
- `shiftpad-logs-20261019-checkpointA-run1.txt`: steps 1, 2, 3 and 5 (21:09 to 21:20)
- run 2 (21:22 to 21:23, after the fixes) was read from the `flutter run` console

### Step 1: Side bytes
- Expected: `0x0A` = right, `0x0B` = left.
- Observed: confirmed. The 0x3C info frame also carries the pod's id with the same prefix (`0A-D4060F…` on the right, `0B-D4060F…` on the left).
- Decision: no change.

### Step 2: Right pod buttons
- Expected: A, B, Y, Z and + each logged once as the right button.
- Observed: all five masks are correct (`ef`, `df`, `bf`, `ff fe`, `ff df` for A, B, Y, Z, +).
- **Surprise:** every right-pod press also arrives, byte for byte, on the **left** pod's Async characteristic (the left pod relays the right one). The right pod does not relay left presses. Without a fix, one press of + would shift twice.
- Decision: each `ClickSession` now keeps only the buttons of its own side. In run 2, 5 presses of + gave exactly 5 `plus down` events, and 5 presses of − gave exactly 5 `minus down`.

### Step 3: Left pod, cold (not unlocked by a Zwift app today)
- Expected (spec §5.2): the left pod stops sending events after about 1 min.
- Observed: the left pod echoes `RideOn`, then sends a challenge `ff 03 00 …` at +5 s and again at +2 min 40 s. It **keeps sending every press anyway**: ←, ↑, →, ↓ and − all decoded correctly (`fe`, `fd`, `fb`, `f7`, `ff fd`), and 13 presses of − spread over 4 minutes (up to 8.5 minutes after connecting) all arrived. No disconnects.
- ShiftPad sends `RideOn` every 3 s and `FF 04 00` after every `RideOn` echo. We do not know whether this is what keeps the pod working. Nothing else was tried.
- Bug found: the `RideOn` echo of the keep-alive moved the lock state from "locked" back to "unlocked" right after each challenge. Fixed: an echo only sets the state when it is still "unknown". A press from the pod's own side marks it "unlocked", because that proves it works.
- Other frames seen: `19 10 5a` (battery, field 2 = 90 %, now parsed), `2a 08 03 …` (status, about every 3 s on the left), `ff 05 00 …` (unknown, about every 3 s on the left, treated as unknown), `3c …` (device info after `00 08 00`; firmware read from it).

### Step 4: Companion unlock test
- Not done. Step 3 shows the left pod works without any unlock, so this test could not change the design.

### Step 5: Idle behaviour
- Observed: the right pod was left untouched for about 7 minutes while connected, with no disconnect. The keep-alive echoes count as frames anyway, so the 55 s idle reboot never fired.
- Decision: `idleRebootEnabled` now defaults to `false`.

### Step 6: Decision for the wizard (Task 11)
Neither (a) nor (b) from the plan applies: **the left pod works without being unlocked by a Zwift app.** Wizard copy: "Both controllers work with ShiftPad. If the left one stops answering, ShiftPad switches to right-only buttons by itself." No Companion steps.

Controller rule (Task 10), adjusted to this finding: a challenge alone must **not** drop left-pod events. When the left pod is not usable (not connected, or a challenge was received and no own press came after it), the right pod also gets the right-only bindings (B = shift down) as a backup. Left presses that do arrive are still used.

## Task 8 manual check: keyboard into MyWhoosh (2026-10-19)

MyWhoosh 6.2.3.0 (Microsoft Store build, `MyWhoosh.exe`, one visible window of class `UnrealWindow`), during a free ride with virtual shifting on.

- Typed by hand: **K = shift up, I = shift down.** This matches `KeyboardOutput.defaultKeys`.
- `SendInput` with scan codes works. A probe sent K three ways (scan code only with a 60 ms hold, scan code only with a 250 ms hold, VK + scan code with a 250 ms hold): all three shifted.
- Bug found: the first version checked `GetForegroundWindow()` right after `SetForegroundWindow()`. Activation is asynchronous, so the key-down was sometimes dropped. Fixed: wait up to 500 ms for the activation, then 200 ms more before the first key.
- After the fix, 4 out of 4 "Send shift up" tests shifted: 3 with MyWhoosh already in front, 1 where ShiftPad brought it to the front.
- The MyWhoosh process has a hidden "Bonjour Hidden Window". MyWhoosh seems to ship its own Bonjour (mDNS) client, which matters for Task 9.

## Task 9 manual check: OpenBikeControl on the same PC (2026-10-19)

- `WindowsDnsSdAdvertiser` (`DnsServiceRegister`) registers `ShiftPad-DELL-JD._openbikecontrol._tcp.local.` with status 0. `python -I tool/mdns_browse.py` sees it, with host `DELL-JD.local.`, the right port and all the TXT keys. Caveat: the Bonjour service is also installed on this PC, so "works without Bonjour" is shown for the Windows API, not proven on a PC without Bonjour.
- No Windows Firewall prompt appeared. MyWhoosh on the same PC connects through the PC's LAN address (`192.168.1.139`), which the firewall does not block.
- **MyWhoosh 6.2.3 lists ShiftPad under Connection → OpenBikeControl and connects on the first try.** App info received: `mywhoosh 5.7.0`, buttons `0x01, 0x02, 0x03, 0x10–0x19, 0x40`. So MyWhoosh handles shifting, steering and navigation, but not HUD toggle (`0x44`) or emote (`0x20`). Those go to the keyboard: `ObcOutput.supports()` now honours the list the app sends.
- A shift sent through OpenBikeControl changed gear in MyWhoosh. MyWhoosh does not have to be the foreground window.
- When ShiftPad restarts, **MyWhoosh does not reconnect by itself**: no reconnect within 4 minutes, even with ShiftPad back on the same fixed port (47331, now the default). In the meantime the router falls back to the keyboard and shifting keeps working. The UI (Task 11) must tell the rider how to reconnect: Connection → OpenBikeControl → ShiftPad → Yes.
- Dev note: stopping `flutter run` left the `shiftpad.exe` window running, and several stale instances had piled up (one of them was still holding port 47331). Some of the earlier keyboard results may have been affected. Before each run, kill every instance with `taskkill /IM shiftpad.exe /F`.

## Checkpoint B: MyWhoosh on the same PC (2026-10-19)

Release build, MyWhoosh 6.2.3 paired to the D500 over Bluetooth, virtual shifting on.
Log: `shiftpad-logs-20261019-230656.txt` (in `Documents\ShiftPad`, not committed).

### Step 1: OpenBikeControl and the wizard
- The owner followed the wizard from first launch (22:36:08) to Finish (22:39:00): **2 min 52 s** (target: under 5 minutes). Mode chosen: right controller only.
- MyWhoosh connected over OpenBikeControl and + / B shifted.
- When ShiftPad was restarted cleanly (no stale instance left), **MyWhoosh reconnected by itself**, about 1 s after the mDNS registration. The earlier "no reconnect" (Task 9 note) was caused by stale `shiftpad.exe` instances still running.

### Step 2: Keyboard
- K shifts up and I shifts down (unchanged). **The toggle-UI key is U, not H.** `defaultKeys` is fixed and tested.
- The owner disconnected OpenBikeControl in MyWhoosh: the route card switched to "Keyboard mode" and + still shifted.

### Step 3: Latency
- 178 presses in the ride log: from the BLE notification to the output sent, median 0 ms, max 1 ms (target: under 100 ms).

### Step 4: Ride (stopped after 18 min, see below)
The owner reported shifting that did not feel smooth, frequent disconnects, a pod card saying "Used by another app" when no other app was open, and one sudden jump from very easy to very hard without shifting.

What the log shows:
- The left pod was asleep the whole ride (right-only mode, never pressed), so the **right pod was connected alone**. A lone pod is dropped about 60 s after its last *button* frame. Keep-alive `RideOn` echoes do not count: the first drop came 61 s after connecting, and another 66 s after the last press. The pod was then unreachable (connect timeouts, "Unreachable") until the owner pressed a button. 24 disconnects in 18 min. Presses made while it was down were lost. In checkpoint A both pods were connected and nothing was dropped in 7 idle minutes.
- "Used by another app" was wrong: every connect failure was reported as `busyElsewhere`.
- Every shift sent had a matching press from the owner (no phantom shifts). The fast series of + (about 10 presses in 3 s at 22:56) was real presses right after a reconnect. The jump in resistance is not explained by ShiftPad output. A likely contributor: ShiftPad kept scanning for the missing left pod and retrying connections every 5 to 15 s, which loads the Bluetooth radio that the D500 also uses.

Fixes (tested):
- The idle reboot is back on. Its clock now follows button frames only, and it runs only when the pod is alone (`idleRebootWhen`). Hardware test, right pod alone and no presses for 3 minutes: a reboot every 55 s, the pod back in about 10 s each time, and the next + was delivered (5 ms). A press made during those ~10 s would still be lost.
- A connect failure after the pod has answered once is shown as "Searching…" (asleep), not busy. "Used by another app" became "Can't connect", with a hint that covers both causes.
- Scanning stops once the sides the mode needs are found. Right-only mode no longer scans for the left pod.

Still to do: the one-hour ride with these fixes.
