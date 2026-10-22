# QuickFix Photos in Firestore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native, in this session) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make live photo reports work on the free Spark plan by storing each photo as base64 text in a Firestore document, with the report and photo saved together.

**Architecture:** New collection `quickfix_photos/{reportId}` (`ownerId`, `contentType`, `data`, `updatedAt`). Report and photo are written or deleted in one Firestore transaction. Rules enforce owner-only access and pending-only changes. The app stops using Firebase Storage.

**Tech Stack:** Flutter 3.44.8, firebase_auth, cloud_firestore, image_picker, `dart:convert`. Firebase emulators (auth, firestore) for all runtime checks.

**Spec:** `QUICKFIX-PHOTOS-SPEC.md` (approved by Airen 2026-10-22).

## Global Constraints
- Style: `~/Documents/FLUTTER_STYLE_HANDOFF.md` is a requirement. StatefulWidget, setState, simple maps, standard widgets, plain functions, double quotes, braces on every callback, no `late`, no arrow actions, no typedefs, no `??=`, no `?.` chains, no cascades, no new packages, no model classes, no new widget classes, no `Theme.of`. Dialogs: Cancel `TextButton` plus action `ElevatedButton`.
- Photo limits: picker `maxWidth` 800, `maxHeight` 800, `imageQuality` 60. App rejects a photo over `500 * 1024` bytes. Rules: `data.size() <= 700000`. Types: `image/jpeg`, `image/png`, `image/webp`.
- Photo document id equals the report id. Report `photoPath` must equal `"quickfix_photos/" + reportId`.
- Keep the `users/{userId}` rules block unchanged. No rules deploy, no push, no billing change, no release unless Airen says so.
- Live Firestore rules must be pasted by Airen and compared before any deploy. This plan only edits the local file.
- Runtime checks only with `--dart-define=USE_EMULATORS=true`. Stop servers by exact command, never by broad port lists.
- User-facing text has no em dashes. Commit messages end with: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Done means `flutter analyze` says "No issues found!" and `flutter test` passes, with anything not checked stated plainly.

## Review Focus
1. Photo over 500 KB: rejected with a message, nothing saved. Pinned in Task 4 and the Task 7 browser check.
2. Editing a report without choosing a new photo leaves the photo document untouched and still shown. Pinned in Task 4 and Task 7.
3. Deleting a pending report removes both documents together; if the report already moved on, the whole delete fails and the photo stays. Pinned in Task 1 (rules) and Task 5.
4. A photo document with no matching report, or for another student's report id, is rejected by the rules. Pinned in Task 1.
5. Details for a report whose photo document is missing shows "Photo unavailable" and does not crash. Pinned in Task 5.

## File Structure
- Modify `firestore.rules`, `tools/check_rules.cjs` (Phase 1).
- Modify `lib/pages/report_form_page.dart`, `lib/pages/report_details_page.dart`, `lib/main.dart`, `pubspec.yaml` (Phase 2).
- Modify `README.md`, `HANDOFF.md` (Phase 3). `storage.rules` and `firebase.json` stay as they are.

---

## Phase 1: rules and rule tests

### Task 1: Rewrite the rules test first (TDD)
**Files:** Modify `tools/check_rules.cjs`.
- [ ] Remove every Storage import and call (`ref`, `uploadBytes`, `getBytes`, `deleteObject`, the `storage` option, `alice.storage()`). Use Firestore only. Add a helper that builds a photo document: `{ ownerId, contentType: 'image/png', data: <base64 string>, updatedAt: serverTimestamp() }`.
- [ ] Keep every existing report assertion (owner isolation, status restrictions, pending-only edits and deletes, profile access). Change `photoPath` in test reports to `'quickfix_photos/report-one'` (and `'quickfix_photos/delete-me'`).
- [ ] Create now goes through `runTransaction` writing report and photo together. Add these assertions (each must `assertSucceeds` or `assertFails` as named):
  - succeeds: alice creates report plus photo together; alice reads her photo
  - fails: bob reads alice's photo; guest reads it; creating a report with no photo document; creating a photo with no report; creating a photo for a report id owned by someone else; `contentType: 'image/gif'`; `data` of 700001 characters; empty `data`; extra field on the photo document; `ownerId` of another student
  - succeeds: alice replaces her photo (update with new `data`) while the report is `Submitted`
  - after status `Under Review`: fails to update the photo, fails to delete the photo, fails to delete the report
  - succeeds: pending report and its photo deleted together in one transaction; a deletion transaction for a report that is no longer pending fails and the photo still exists
  - `users/student-alice` profile checks stay, unchanged
- [ ] Update the final `console.log` to describe the new checks.
- [ ] Run it (command in Task 3). Expected: FAIL, because the rules do not know `quickfix_photos` yet.

### Task 2: Rules
**Files:** Modify `firestore.rules`.
**Interfaces:** Produces: `match /quickfix_photos/{reportId}` block; report rule `photoPath` must equal `'quickfix_photos/' + reportId`.
- [ ] In `validReport()` replace the `photoPath ... matches('quickfix/'...)` condition with `d.photoPath == 'quickfix_photos/' + reportId`.
- [ ] Report `create` additionally requires `existsAfter(/databases/$(database)/documents/quickfix_photos/$(reportId))`.
- [ ] Add the photo block. Conditions, with exact values:
  - `read`: `request.auth != null && resource.data.ownerId == request.auth.uid`
  - `create`: auth, key set exactly `['ownerId','contentType','data','updatedAt']`, `ownerId == request.auth.uid`, `contentType in ['image/jpeg','image/png','image/webp']`, `data is string && data.size() > 0 && data.size() <= 700000`, `updatedAt == request.time`, and `getAfter` of the report has `ownerId == request.auth.uid` and `status == 'Submitted'`
  - `update`: same shape checks, `resource.data.ownerId == request.auth.uid`, `ownerId` unchanged, and `get` of the report has `status == 'Submitted'`
  - `delete`: `resource.data.ownerId == request.auth.uid` and (`!exists` of the report, or `get` of the report has `status == 'Submitted'`)
- [ ] Copy the `users/{userId}` block exactly as it is. Keep a short comment above the photo block saying photos live here because Storage needs Blaze.

### Task 3: Run rule tests and commit
- [ ] `npm install --prefix <scratchpad>/rule-tests @firebase/rules-unit-testing firebase` if the folder is gone, then: `QUICKFIX_TEST_DEPS=<scratchpad>/rule-tests firebase emulators:exec --project demo-quickfix --only firestore 'node tools/check_rules.cjs'`. Expected: the PASS line and exit 0. A failure is a finding to fix in the rules, not a reason to weaken a test.
- [ ] Update `HANDOFF.md` (Phase 1 done, next Phase 2). `git add firestore.rules tools && git commit -m "feat: store report photos in Firestore with owner-only pending-only rules"`.

---

## Phase 2: app

### Task 4: Report form
**Files:** Modify `lib/pages/report_form_page.dart`.
**Interfaces:** Produces: no more Storage use. Uses `import "dart:convert";`.
- [ ] `pickPhoto`: `maxWidth: 800`, `maxHeight: 800`, `imageQuality: 60`.
- [ ] `usePhoto`: after the type check, if `bytes.length > 500 * 1024` set `error = "This photo is too large. Take it again or choose a smaller one."` and return.
- [ ] `loadPhoto(String reportId)` as `Future<Uint8List?>`: reads `quickfix_photos/$reportId`, returns `base64Decode(data["data"])`, or null when the document is missing. `currentPhoto` (edit mode, existing field) uses it. Remove the `oldPhoto` Storage logic: keep a plain `bool hasPhoto` set from `widget.report != null` for the "photo kept" text and the required-photo check.
- [ ] `saveReport`: no upload and no cleanup. One `runTransaction`: create sets the report (`photoPath: "quickfix_photos/${reference.id}"`) and `transaction.set(photoReference, photoValues)`; edit checks owner and `Submitted` as it does now, updates the report, and writes the photo document only when `photo != null`. Keep the same error messages and the `busy` handling. Remove the `uploaded`, `saved`, and old-photo deletion code.
- [ ] `flutter analyze`. Expected: no issues.

### Task 5: Report details
**Files:** Modify `lib/pages/report_details_page.dart`.
- [ ] Replace the Storage `getData` future with a `loadPhoto(String reportId)` function (same shape as in Task 4). A missing document gives "Photo unavailable." and the Retry button stays for errors.
- [ ] `deleteReport`: one transaction that checks `Submitted`, then `transaction.delete(reference)` and `transaction.delete(photoReference)`. Remove the Storage deletion and the "photo could not be removed" message. Dialog text stays.
- [ ] `flutter analyze`. Expected: no issues.

### Task 6: Remove Storage from the app and commit
**Files:** Modify `lib/main.dart`, `pubspec.yaml`.
- [ ] `main.dart`: remove the `firebase_storage` import, `useStorageEmulator`, and the two retry-time lines.
- [ ] `pubspec.yaml`: remove `firebase_storage`. Run `flutter pub get`.
- [ ] `flutter analyze` (No issues found!) and `flutter test` (all pass). Confirm `grep -rn firebase_storage lib` finds nothing.
- [ ] Update `HANDOFF.md`, then `git add lib pubspec.yaml pubspec.lock && git commit -m "feat: save and show report photos through Firestore instead of Storage"`.

---

## Phase 3: verification, README, APK

### Task 7: Emulator and browser pass
- [ ] Start `firebase emulators:start --only auth,firestore --project aclon-franz`, seed with `node tools/seed_demo.cjs`, `flutter build web --no-wasm-dry-run --dart-define=USE_EMULATORS=true --output build/web-demo`, serve it. Stop everything by exact command afterward.
- [ ] Chrome at 412 px (see `docs/history.md` for the Flutter-web driving tips): submit with a JPG; view the photo in details; Edit, replace the photo, save, see the new one; Edit without choosing a photo, save, photo still shown; choose a file over 500 KB and see the message (the web picker should shrink it first; note what happens); delete a pending report and confirm in the Firestore emulator REST that both documents are gone; confirm a non-pending report offers no edit or delete.
- [ ] Check the emulator Firestore REST for the photo document fields. Confirm no Storage requests appear in the network list.

### Task 8: README, build, handoff, commit
- [ ] README: replace the Storage text (live uploads blocked, bucket, Storage rules deploy, emulator ports) with the Firestore photo design, the deviation from "Firebase Storage for photos" with the reason and Airen's approval date, the size limits, the deploy command `firebase deploy --only firestore:rules --project aclon-franz`, the new emulator command (`auth,firestore`), updated rules-test command (`--only firestore`), and the "Tested where" table (still no real phone, no live test).
- [ ] `flutter build web`, `flutter build apk --release`. Expected: both succeed.
- [ ] Final `flutter analyze` and `flutter test`; `git status` shows no logs or private files; commit `docs: README for Firestore photos`.
- [ ] Update `HANDOFF.md` with what Airen must do: paste and compare live rules, deploy rules, test the APK on a phone, decide on a new release and the push. Do NOT push, deploy, or publish a release without Airen's instruction.
