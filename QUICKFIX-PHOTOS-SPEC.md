# QuickFix photos in Firestore: spec

Status: DRAFT, waiting for Airen's approval. No code has been changed.
Date: 2026-10-22. Baseline: `main` at `1e61d7c`, release `v1.1.0`.
Decision by Airen (2026-10-22): Firebase Storage is not required; go with option 1 (photos inside Firestore). No Blaze billing.

## Why
Live Firebase Storage needs the Blaze plan, so the live app cannot save any report (a photo is required). Firestore works on the free Spark plan. Storing a small photo as text in Firestore makes live photos work with no billing, no new service, and no new package.

## Goals
1. Live photo reports work on the Spark plan: take or choose a photo, submit, view in details, replace while pending, deleted with the report.
2. Photo and report are written together in one transaction, so a failed save can no longer leave an orphan photo (this removes the Storage cleanup problem).
3. Keep owner-only access and pending-only edit/delete, enforced in the Firestore rules and in the UI.
4. Keep Activity 5's `users/{uid}` permissions exactly as they are.
5. Keep the local emulator demo working (Auth and Firestore only; the Storage emulator is no longer needed).

## Non-goals and anti-goals
- No billing change, no outside image host, no new packages (base64 comes from `dart:convert`, which ships with Dart).
- No deploy and no push without Airen's instruction. No change of Firebase project.
- Anti-goal: any rules change that removes Activity 5's or QuickFix's existing access.
- Not keeping the old Storage upload path. No live reports exist with Storage photos (uploads never worked live), to be confirmed by Airen in the Console.

## Design (my calls, Airen can overturn)
- **Photo size:** the picker shrinks photos to 800 px and quality 60 (about 60 to 200 KB). The app rejects a photo larger than 500 KB with a clear message. A base64 string of 500 KB is about 667 KB, safely under Firestore's 1 MiB document limit.
- **Where photos live:** a new collection `quickfix_photos/{reportId}` with fields `ownerId`, `contentType` (`image/jpeg`, `image/png`, or `image/webp`), `data` (base64 text), `updatedAt`. Separate documents keep the My Reports list fast, because the list query never downloads photos.
- **Report documents:** same fields as now. `photoPath` stays and must equal `quickfix_photos/{reportId}`, so the report rules change by one line.
- **Rules (`firestore.rules`):**
  - Report create must also create its photo document in the same transaction (`existsAfter`).
  - Photo create: owner only, exact key set, content type and size checks (`data.size() <= 700000`), `updatedAt == request.time`, and the matching report must be created by the owner as `Submitted`.
  - Photo read: owner only.
  - Photo update and delete: owner only, only while the report is `Submitted`.
  - The `users/{userId}` block is copied unchanged.
- **Storage:** the app no longer uses Firebase Storage. `storage.rules` and `firebase.json`'s storage entry stay in the repo, unused, so nothing is deleted. The `firebase_storage` dependency is removed from `pubspec.yaml`.
- **Code (style per `FLUTTER_STYLE_HANDOFF.md`: setState, maps, standard widgets, braces on callbacks):**
  - `report_form_page.dart`: picker settings, the 500 KB check, one transaction that writes the report and the photo document, edit mode loads the current photo from Firestore, all upload and cleanup code removed.
  - `report_details_page.dart`: loads the photo with a Firestore `get`, deleting removes the report and photo in one transaction.
  - `main.dart`: remove Storage setup.
  - `tools/check_rules.cjs`: replace the Storage checks with photo document checks.
  - `README.md`: new photo storage text, the deviation from "Firebase Storage for photos" noted with the reason, deploy command `firebase deploy --only firestore:rules --project aclon-franz`.

## Constraints
- Before ANY rules change is deployed, Airen pastes the currently deployed Firestore rules from the Console. I compare them with the local `firestore.rules` and keep every existing permission.
- Checks only against emulators, with `--dart-define=USE_EMULATORS=true`.
- Commit after each phase. Commit messages end with the Claude co-author line.

## Phases
1. Rules and rule tests (`firestore.rules`, `tools/check_rules.cjs`), run in emulators.
2. App changes (form, details, main, pubspec) with analyze and tests.
3. Emulator and browser pass, README, new APK, handoff.

## Verification plan
- `flutter analyze`, `flutter test`, the updated rules tests (owner isolation, pending-only photo changes, size and type limits, report without photo rejected, Activity 5 profile access still works).
- Browser against emulators at 412 px: submit with photo, view, replace photo while pending, delete (photo document gone), photo over 500 KB rejected, non-pending photo cannot be changed.
- Check that web photo shrinking works. If the web picker does not resize, large desktop photos will be rejected by the 500 KB limit, and the message must say so clearly.
- `flutter build web`, `flutter build apk --release`.

## Not verifiable by me
- Live Firestore behavior until Airen deploys the rules and tests the APK on a phone.
- Real phone camera photo sizes (a typical camera photo shrunk to 800 px should fit, but this needs a phone).

## Needs Airen
1. Approve this spec.
2. Paste the live Firestore rules (Firebase Console, Firestore Database, Rules tab).
3. Confirm in the Console that `quickfix_reports` has no live reports that depend on Storage photos.
4. Later: tell me when to deploy rules, build and publish the new APK, and push.
