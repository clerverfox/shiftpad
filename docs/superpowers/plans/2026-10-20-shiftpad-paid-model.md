# ShiftPad paid model: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or superpowers:subagent-driven-development) to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 14-day full trial and a one-time purchase (12 €) to ShiftPad, sold on the Microsoft Store (MSIX, Store-managed trial) and on the owner's site (license key through a merchant of record). A ride is never cut by the trial or the license, and the app works offline once bought.

**Spec:** `docs/superpowers/specs/2026-10-20-shiftpad-paid-model-design.md` (French). Read it before Task 1. Hardware and ride findings so far: `docs/testing/findings.md`.

**Architecture:** One `LicenseService` interface (pure Dart, unit-tested with fakes) answers four things: the current `LicenseState`, how many trial days are left, how to buy, and how to activate a key. The build channel is chosen at compile time with `--dart-define=CHANNEL=store|direct`. `direct` uses `KeyLicenseService`: a local trial clock plus a key checked through a `LicenseApi` (Lemon Squeezy first, behind an interface). `store` uses `StoreLicenseService`: the Windows `StoreContext` API through a small C++/WinRT method channel in the runner. A `LicenseGate` decides whether actions may be sent; the decision is taken at app start and never revoked during a session.

**Tech stack:** existing Flutter/Dart app. New: `http` (license API calls), `msix` (dev, packaging), C++/WinRT in `windows/runner`.

**Execution:** native, on the bike PC, as for v1. The owner does not code and speaks French: talk to them in simple French, one instruction at a time. Tasks 1 to 6 need no account. Tasks 7 and 8 need the owner's accounts (micro-entreprise, Lemon Squeezy, Partner Center); stop and ask before them if the accounts are not ready.

## Global constraints

- **Never block or cut a ride.** If the state at app start allowed sending, sending stays allowed until the app closes, whatever the clock or the server says later.
- **Offline first.** A validated license works with no network. Direct channel: revalidate at most every 7 days when online; after 60 days with no successful contact, ask for a connection at the next app start only.
- **No personal data.** Send only the license key, a random instance id and the instance name `ShiftPad-<computername>` to the license API. No analytics.
- **Trial:** 14 calendar days from the first app start, stored in two places (`shared_preferences` and the user registry `HKCU\Software\ShiftPad`), using the earliest of the two. Clock moved backwards → keep the furthest time seen (no reset).
- **Copy:** simple English, all strings in `lib/l10n/app_en.arb`. Price shown as "12 €" (from a constant in `lib/licensing/pricing.dart`).
- **Secrets:** no API secret in the app. The Lemon Squeezy license endpoints (`/v1/licenses/activate`, `/validate`, `/deactivate`) are public and need no API key. Store/product ids come from `--dart-define`.
- Keep every v1 test passing; `flutter analyze` must report no issues.

## Review focus

1. **Trial expiring mid-ride**: the session keeps sending → test in Task 3 (`LicenseGate`) and Task 5.
2. **Offline buyer**: no network at start, license validated 20 days ago → unlocked; 61 days ago → unlocked this session, prompt shown → Task 2.
3. **License server down or slow** (timeouts, 5xx): never throws, never locks a validated buyer → Task 2.
4. **Trial reset by reinstalling**: the registry copy keeps the first-start date → Task 1.
5. **Store API unavailable** (unpublished app, offline, non-Store install): falls back to "trial unknown, allowed" for the session, logs it, no crash → Task 4.

---

### Task 1: Trial clock

**Files:** create `lib/licensing/trial_clock.dart`, `lib/licensing/trial_store.dart` (interface + `PrefsTrialStore`, `RegistryTrialStore` via `win32` registry API, `CombinedTrialStore` taking the earliest), `lib/licensing/pricing.dart`; test `test/licensing/trial_clock_test.dart`.

**Interfaces:**
- `abstract class TrialStore { Future<DateTime?> firstStart(); Future<void> setFirstStart(DateTime t); Future<DateTime?> lastSeen(); Future<void> setLastSeen(DateTime t); }`
- `class TrialClock { TrialClock({required TrialStore store, DateTime Function() now, Duration length = const Duration(days: 14)}); Future<TrialStatus> check(); }` and `class TrialStatus { final bool active; final int daysLeft; final DateTime endsAt; }`

- [ ] **Step 1: Failing tests:** first check records the first start, 14 days left; day 13 → 1 day left, active; day 14 + 1 s → not active; clock set back 10 days after day 5 → still counts from the furthest time seen; a combined store with an earlier registry date wins over prefs (reinstall case).
- [ ] **Step 2:** run, see them fail. **Step 3:** implement. **Step 4:** run, see them pass.
- [ ] **Step 5: Commit:** `feat(licensing): trial clock`

### Task 2: Key license service (direct channel)

**Files:** create `lib/licensing/license_service.dart` (interface, `LicenseState`), `lib/licensing/license_api.dart` (interface + `LemonSqueezyLicenseApi` using `http`), `lib/licensing/key_license_service.dart`; test `test/licensing/key_license_service_test.dart` with a fake `LicenseApi` and a fake clock.

**Interfaces:**
- `enum LicenseKind { trial, trialEnded, licensed, needsCheck }`
- `class LicenseState { final LicenseKind kind; final int? trialDaysLeft; final String? maskedKey; }`
- `abstract class LicenseService { Future<LicenseState> load(); Future<ActivationResult> activate(String key); Future<void> openPurchase(); ValueListenable<LicenseState> get state; }`
- `abstract class LicenseApi { Future<ApiResult> activate(String key, String instanceName); Future<ApiResult> validate(String key, String instanceId); }`, where `ApiResult` is ok / invalid(reason) / limitReached / networkError.

- [ ] **Step 1: Failing tests:** valid key → licensed and stored (key, instance id, last OK date); invalid key → a clear reason and the state unchanged; 3-PC limit → `limitReached` message; network error during activation → "check your connection", trial untouched; startup offline with last OK 20 days ago → licensed, no API call; online and last OK 8 days ago → validate in the background, licensed whatever the answer unless the API says the key was revoked or refunded; last OK 61 days ago and offline → `needsCheck` (the gate still allows this session); API timeout after 5 s → treated as networkError, never throws.
- [ ] **Steps 2 to 4:** run (fail), implement, run (pass). The store purchase URL comes from `--dart-define=BUY_URL`.
- [ ] **Step 5: Commit:** `feat(licensing): license keys for the direct channel`

### Task 3: License gate in the controller

**Files:** create `lib/licensing/license_gate.dart`; modify `lib/shiftpad_controller.dart`, `lib/app_services.dart`; test `test/licensing/license_gate_test.dart` and add to `test/shiftpad_controller_test.dart`.

- `class LicenseGate { LicenseGate(LicenseService s); Future<void> decideAtStart(); bool get canSend; }`: `canSend` is decided once in `decideAtStart()` (trial active, licensed, or needsCheck → true; trialEnded → false). It only ever goes from false to true, after a successful activation or purchase.
- [ ] **Step 1: Failing tests:** trial expires (clock jumps past day 14) after start → still sends; trialEnded at start → presses produce no action, a `blocked` log line and `lastBlocked` is set; activation succeeds → sends right away, no restart needed.
- [ ] **Steps 2 to 4**, **Step 5: Commit:** `feat(licensing): never cut a ride: decide at start`

### Task 4: Store license service (Store channel)

**Files:** modify `windows/runner/` (add `store_license_plugin.cpp/.h`, register a method channel `shiftpad/store` in `flutter_window.cpp`, link `windowsapp.lib`); create `lib/licensing/store_license_service.dart`; test `test/licensing/store_license_service_test.dart` with a mocked method channel.

- Native methods: `getLicense` → `{isActive, isTrial, trialEndsAt (ISO or null)}` from `StoreContext::GetDefault().GetAppLicenseAsync()` (call `IInitializeWithWindow` with the Flutter window handle); `purchase` → `RequestPurchaseAsync(storeId)`, returning the status as a string. The store id comes from `--dart-define=STORE_ID`.
- [ ] **Step 1: Failing tests:** trial with an end date → trial and days left; active and not trial → licensed; inactive → trialEnded; channel throws (unpublished app or non-Store install) → `trial` with daysLeft null, logged, no crash; purchase "Succeeded" → reloads and becomes licensed.
- [ ] **Steps 2 to 4**, plus `flutter build windows --debug` succeeds. **Step 5: Commit:** `feat(licensing): Microsoft Store license`

### Task 5: Screens

**Files:** create `lib/ui/purchase_screen.dart`, `lib/ui/widgets/trial_badge.dart`, `lib/ui/activate_key_dialog.dart`; modify `lib/ui/home_screen.dart`, `lib/app.dart`, `lib/l10n/app_en.arb`; tests `test/ui/purchase_screen_test.dart`, add to `test/ui/home_screen_test.dart`.

- Home: a small `TrialBadge` ("Trial: 9 days left · Buy") during the trial, nothing once licensed, and a quiet line "Check your licence online soon" for `needsCheck`.
- When the gate is closed at start: `PurchaseScreen` ("Your 14-day trial has ended", price, "Buy ShiftPad", "I have a key" on the direct channel only, a "Diagnostics" link). Pods still connect behind it.
- Key dialog: paste the key, then "Activate" shows a spinner and the result message (invalid / 3 PCs already / no connection / done).
- Menu: "Licence" shows the state, the masked key and "Remove from this PC" (deactivate) on the direct channel.
- [ ] **Steps 1 to 4** (widget tests first). **Step 5: Commit:** `feat(ui): trial badge, purchase screen, key activation`

### Task 6: Channels, packaging and a local end-to-end check

**Files:** modify `tool/package_windows.ps1` (takes `-Channel direct|store`), add the `msix` dev dependency and its config in `pubspec.yaml` (identity placeholders read from env), `README.md`, `docs/INSTALL.md` (trial and buying); create `lib/licensing/channel.dart` (`const channel = String.fromEnvironment('CHANNEL', defaultValue: 'direct')`).

- [ ] **Step 1:** `-Channel direct` builds the zip as today, with the trial. `-Channel store` builds an MSIX with the `msix` package, unsigned for local testing.
- [ ] **Step 2: Manual check on this PC:** fake a trial ended (date in prefs and registry set 15 days back with a small debug tool, `tool/trial_debug.ps1`) → the purchase screen shows. Restore it → the badge shows the right number of days.
- [ ] **Step 3:** `flutter test` and `flutter analyze` are clean. **Commit:** `chore: build channels and MSIX packaging`

### Task 7: Checkpoint C: real license keys (needs the owner's Lemon Squeezy account, test mode)

- [ ] Ask the owner, in French and one step at a time, to create the product "ShiftPad" (12 €, license keys on, 3 activations) in **test mode**, and give the buy link. Never ask them to paste any secret API key: the license endpoints need none.
- [ ] Buy in test mode with the test card, receive the key, activate it in ShiftPad: licensed. Unplug the network and restart: still licensed. Activate on a 4th "PC" (deactivate/activate cycles with fake instance names in a test script): `limitReached` message. Refund the test order → the next validation marks it revoked.
- [ ] Record everything in `docs/testing/findings.md`. Commit `docs: checkpoint C (license keys)`.

### Task 8: Checkpoint D: Microsoft Store (needs Partner Center, app name reserved)

- [ ] Guide the owner through reserving the name "ShiftPad" in Partner Center, setting price 12 € and a 14-day free trial, and filling the identity values into the build environment.
- [ ] Submit a **private** flight (package flight or hidden listing) with the MSIX. Install it from the Store on the bike PC: the badge shows the Store trial; "Buy" opens the Store purchase. If possible, the owner buys it (refundable) or uses a promo code: licensed, works offline.
- [ ] Record in `findings.md`. Commit `docs: checkpoint D (Microsoft Store)`.

### Task 9: Release

- [ ] Version `1.1.0+2`. Direct zip, signed if the owner has set up code signing (otherwise document the SmartScreen warning in INSTALL.md); Store submission set to public by the owner when they are ready.
- [ ] `flutter test`, `flutter analyze` clean; whole-branch review; push.
