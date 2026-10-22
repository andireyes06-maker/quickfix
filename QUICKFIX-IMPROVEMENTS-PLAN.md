# QuickFix Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native, in this session) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the location-error and photo-format bugs and close the usability gaps found in the review, without rewriting the app.

**Architecture:** Small edits inside the existing pages. Plain StatefulWidget, setState and maps. No new packages, model classes, or shared widget files. One pure top-level helper (`photoTypeFor`) so the photo rule can be unit tested.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12.2, firebase_auth, cloud_firestore, firebase_storage, image_picker, geolocator. Firebase emulators for all runtime checks.

**Spec:** `QUICKFIX-IMPROVEMENTS-SPEC.md` (approved by Airen 2026-10-22).

## Global Constraints
- Style: `~/Documents/FLUTTER_STYLE_HANDOFF.md`. Double quotes, braces on every callback, no `late`, no arrow actions, no typedefs, no `??=`, no `?.` chains, no cascades, no packages, no model classes, no `Theme.of`.
- No Firestore or Storage rules changes. No deploys, no push, no billing or project changes.
- Runtime checks only with `--dart-define=USE_EMULATORS=true`. Never write to live `aclon-franz` data.
- User-facing text has no em dashes.
- Commit after each phase. Commit messages end with: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Done means `flutter analyze` says "No issues found!" and `flutter test` passes, with what was not checked stated plainly.

## Review Focus
1. A web photo with no mime type and no extension (or `.heic`/`.gif`): rejected with a message, nothing uploaded, previous photo kept. Pinned in Task 2.
2. Uppercase extension (`PHOTO.JPG`): accepted. Pinned in Task 2.
3. Location "denied forever": specific message, the rest of the form still usable. Pinned in Task 6 browser check.
4. Back gesture while saving stays blocked; back after a successful save shows no discard dialog. Pinned in Task 4 and Task 6.
5. Edit form where the current photo fails to load: editing and saving still work. Pinned in Task 3.

## File Structure
- Modify `lib/pages/report_form_page.dart`: Phase 1 (Tasks 1 to 4).
- Modify `lib/pages/reports_page.dart`, `lib/pages/report_details_page.dart`, `lib/pages/login_page.dart`: Phase 2.
- Modify `test/widget_test.dart`: tests added in Tasks 2 and 7 and 8.
- Modify `README.md`, `HANDOFF.md`: Task 10.

---

## Phase 1: report form

### Task 0: Checkpoint
- [ ] `git tag pre-review-improvements` on current HEAD (`e6056c6`).
- [ ] `git add QUICKFIX-IMPROVEMENTS-SPEC.md QUICKFIX-IMPROVEMENTS-PLAN.md && git commit -m "docs: add improvements spec and plan"`. Expected: tag exists, tree clean.

### Task 1: Specific location errors
**Files:** Modify `lib/pages/report_form_page.dart` (`getLocation`, about `:128-180`; add `import "dart:async";`).
**Interfaces:** Produces: `Future<void> getLocation()` (same signature). It no longer throws. It sets `error` and returns.
- [ ] Rewrite `getLocation` so each failure sets its own `error` and returns inside the `try`. Exact messages:
  - services off: "Turn on your device location services, then try again."
  - denied forever: "Location is blocked. Enable it for QuickFix in your device or browser settings."
  - denied: "Location permission is needed to record where you reported the problem."
  - `on TimeoutException`: "Could not get your location in time. Try again near a window or outdoors."
  - any other error: "Could not get your location. Please try again."
  Keep the `finally` that clears `deviceBusy`, the 3-decimal rounding, and the `mounted` checks.
- [ ] Run `flutter analyze`. Expected: "No issues found!". (Behavior is checked in Task 6 because geolocator needs a platform.)

### Task 2: Photo type check (TDD)
**Files:** Modify `lib/pages/report_form_page.dart` (`usePhoto` `:69-92`, hint texts `:437`, `:473`); Test `test/widget_test.dart`.
**Interfaces:** Produces: top-level `String photoTypeFor(String mimeType, String fileName)`. Returns `"image/jpeg"`, `"image/png"`, `"image/webp"`, or `""` when unsupported.
- [ ] Write failing test `photoTypeFor accepts only jpeg, png, webp` with these assertions:
  - `photoTypeFor("image/png", "a.bin")` is `"image/png"`
  - `photoTypeFor("image/jpg", "a")` is `"image/jpeg"`
  - `photoTypeFor("", "PHOTO.JPG")` is `"image/jpeg"`
  - `photoTypeFor("", "x.jpeg")` is `"image/jpeg"`
  - `photoTypeFor("", "x.webp")` is `"image/webp"`
  - `photoTypeFor("", "x.gif")`, `photoTypeFor("", "noextension")`, `photoTypeFor("image/heic", "a.heic")`, and `photoTypeFor("image/gif", "x.jpg")` are all `""`
- [ ] Run `flutter test`. Expected: FAIL, `photoTypeFor` not defined.
- [ ] Implement `photoTypeFor`: if `mimeType` is non-empty, use it alone (lowercased, `image/jpg` counts as jpeg); otherwise use the file name's lowercase extension. Plain `if` statements.
- [ ] In `usePhoto`, call it with `file.mimeType` (null becomes `""`) and `file.name`. When it returns `""`, set `error = "Choose a JPG, PNG, or WebP photo."` and return without touching `photo`. Check size after the type. Hint texts say "JPG, PNG, or WebP".
- [ ] Run `flutter test` and `flutter analyze`. Expected: pass, no issues.

### Task 3: Current photo in edit mode
**Files:** Modify `lib/pages/report_form_page.dart`.
**Interfaces:** Produces: field `Future<Uint8List?>? currentPhoto;`.
- [ ] In `initState`, when `widget.report != null` and `oldPhoto` is not empty, set `currentPhoto = FirebaseStorage.instance.ref(oldPhoto).getData(5 * 1024 * 1024);`.
- [ ] Where the "Your existing photo will be kept..." text is (`:443-446`, shown when `photo == null && oldPhoto.isNotEmpty`), show a `FutureBuilder<Uint8List?>` before it: waiting gives a 220 px high progress box, data gives `ClipRRect` + `Image.memory` (height 220, `BoxFit.cover`), error or null gives the existing text plus "The current photo could not be previewed." The kept-photo text stays in every case.
- [ ] `flutter analyze`. Expected: no issues. (Review Focus 5: a failed load never blocks Save, so the future must not be awaited in `saveReport`.)

### Task 4: Discard-changes confirmation
**Files:** Modify `lib/pages/report_form_page.dart`.
**Interfaces:** Produces: field `bool changed = false;` and `void confirmDiscard()`.
- [ ] Set `changed = true` (inside `setState`, only when it was false) from: `Form(onChanged: ...)`, a successful `usePhoto`, the category dropdown, and a successful `getLocation`. Do not set it in `initState` (edit prefill must not count).
- [ ] `PopScope(canPop: !busy && !changed, onPopInvokedWithResult: (didPop, result) { ... })`: when `didPop` is false and `busy` is false, call `confirmDiscard()`.
- [ ] `confirmDiscard()` shows an `AlertDialog` titled "Discard changes?" with "Keep editing" and "Discard". Discard closes the dialog, then `Navigator.pop(context)`.
- [ ] Do not change the save path's `Navigator.pop(context)` (it must not show the dialog). `flutter analyze`. Expected: no issues.

### Task 5: Phase 1 commit and handoff
- [ ] `flutter analyze` ("No issues found!") and `flutter test` (all pass).
- [ ] Update `HANDOFF.md` "Current task" block: Phase 1 done, Phase 1 browser check result (Task 6), next is Phase 2.
- [ ] `git add lib test && git commit -m "fix: specific location errors, photo type check, edit photo preview, discard confirm"`.

### Task 6: Phase 1 emulator and browser check
- [ ] Start `firebase emulators:start --only auth,firestore,storage --project aclon-franz`, run `node tools/seed_demo.cjs`, then `flutter run -d chrome --dart-define=USE_EMULATORS=true` (web server mode is fine for Playwright).
- [ ] Drive at 412 px: (a) deny geolocation, tap Record location, expect the "Location is blocked..." or "needed" message, form still usable; (b) choose a `.gif`, expect "Choose a JPG, PNG, or WebP photo." and no photo set; (c) valid JPG, submit succeeds; (d) open the pending report, Edit, expect the photo preview; (e) type text, press back, expect the discard dialog, "Keep editing" stays, "Discard" leaves; (f) save an edit, expect no discard dialog.
- [ ] Record results in `HANDOFF.md`. Say plainly that this was an emulator and browser check, not a device.

---

## Phase 2: status display, list, login

### Task 7: Status colors, simulation labels, sort
**Files:** Modify `lib/pages/reports_page.dart` (sort `:143-150`, list status `:212-220`, subtitle `:79-83`), `lib/pages/report_details_page.dart` (status chip `:225`, progress heading `:300-306`).
**Interfaces:** Produces: `Color statusColor(String status)` as a method of each page's State class (not top level, so the two files cannot clash). Submitted `Colors.grey.shade700`, Under Review `Colors.orange.shade800`, In Progress `Colors.blue.shade800`, Resolved `Colors.green.shade800`, anything else `Colors.grey.shade700`.
- [ ] List status text uses `statusColor`. The details status `Chip` gets a matching `labelStyle` color (text stays visible).
- [ ] My Reports subtitle becomes "Report a problem. Track the progress. Status changes are simulated for this class demo." Add the line "Status changes are simulated for this class demo." under the "Report progress" heading.
- [ ] Sort: both `createdAt` null returns 0, only `first` null returns -1, only `second` null returns 1, else `second.compareTo(first)`.
- [ ] `flutter analyze`. Expected: no issues.

### Task 8: Login hardening (TDD where possible)
**Files:** Modify `lib/pages/login_page.dart`; Test `test/widget_test.dart`.
- [ ] Write test `Registration shows a mismatch error` : open register, enter name, email, password `secret1`, confirm `secret2`, tap Create account, expect `"Passwords do not match"`. Run `flutter test`. Expected: it already passes (it pins existing behavior).
- [ ] Wrap `updateDisplayName` in its own `try`/`catch` that ignores failure (account exists and the user is signed in). Add a final `catch (e)` after `on FirebaseAuthException` that sets "Something went wrong. Please try again." Error color becomes `Colors.red.shade800`; drop the redundant `semanticsLabel`.
- [ ] `flutter analyze` and `flutter test`. Expected: clean, pass.
- [ ] Update `HANDOFF.md`, then `git add lib test && git commit -m "feat: status colors and simulation labels, stable sort, login hardening"`.

---

## Phase 3: tests, verification, docs

### Task 9: Small-screen and large-text test
**Files:** Test `test/widget_test.dart`.
- [ ] Add test `Login has no overflow at 320 wide and 2x text`, in both sign-in and register modes: set `tester.view.physicalSize = Size(320, 568)` with `devicePixelRatio = 1.0`, wrap with `MaterialApp(builder: ...)` using `MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2.0)), child: child)`, and expect `tester.takeException()` is null. Reset the view at the end.
- [ ] `flutter test`. Expected: pass. If it fails, fix the layout in `login_page.dart` first.

### Task 10: Full verification, README, final commit
- [ ] Rules and lifecycle tests: install `@firebase/rules-unit-testing firebase` into the session scratchpad (not the project), then run the README command with `QUICKFIX_TEST_DEPS` pointing there. Expected: all checks pass. A failure is a finding, not something to hide.
- [ ] Builds: `flutter build web`, `flutter build web --no-wasm-dry-run --dart-define=USE_EMULATORS=true --output build/web-demo`, `flutter build apk --debug`. Expected: all succeed.
- [ ] Browser pass against the emulators at 412 px and 320 px: submit, edit, simulate to Resolved with status colors visible, History, pending delete (photo removed in Storage emulator), sign out and in. At 320 px also check the form, list, and details for overflow.
- [ ] Large text on signed-in pages: add a temporary `builder:` text-scale 2.0 override to `lib/main.dart`, look at list, form, details, then `git checkout lib/main.dart` to revert. Confirm `git diff lib/main.dart` is empty.
- [ ] README: behavior changes (location messages, photo formats, edit preview, discard prompt, status colors, simulation labels), a "Tested where" table (emulator and browser: yes; real phone, iOS, live Storage: not done), the first Storage deploy note (cross-service permission prompt), live rules caution, and the lost-response cleanup caveat.
- [ ] Final `HANDOFF.md` (60 lines max for "Start here", older detail to `docs/history.md`) with what Airen must do: phone camera and location test, Blaze and bucket if wanted, decide when to push.
- [ ] `flutter analyze` and `flutter test` one last time, then `git add -A && git status` to confirm no logs or private files, then `git commit -m "docs: README and verification for improvements"`.
