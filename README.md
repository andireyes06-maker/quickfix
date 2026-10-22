# QuickFix

Student campus maintenance reporting, built with Flutter for Android, iOS, and web.
Written in a simple student coding style using standard widgets, maps, and setState.

## Start here (teammates)

Install Flutter 3.44.8 or newer with Dart 3.12.2, Node.js 22 or newer, Java 21 or newer, and Firebase CLI (`npm install -g firebase-tools`). Android development also needs Android Studio and its SDK; iOS needs macOS and Xcode.

After cloning this repository, open a terminal in the `quickfix` folder:

```sh
flutter pub get
firebase emulators:start --only auth,firestore --project aclon-franz
```

Keep that terminal open. In a second terminal in the same folder:

```sh
node tools/seed_demo.cjs
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

Sign in with `maria.santos.act5@example.com` or `juan.delacruz.act5@example.com`, using local password `quickfix-local-only`. You can also register a new local account. Photos work in the local demo and on the free Firebase plan. Real Firebase project permissions are only needed for console access or deployment.

For an Android emulator, add `--dart-define=EMULATOR_HOST=10.0.2.2` to `flutter run`. Test real camera capture on a phone; desktop browsers may open a file picker instead.

Firebase client configuration is included to identify the registered apps. It does not grant Firebase Console, administrator, or database access. Service account credentials, logs, generated builds, local SDK paths, and private handoff notes are excluded.

## Features
- Firebase email/password registration and login. Existing Activity 5 logins work because the project shares Firebase Authentication.
- Submit a title, description, campus location, category, photo, and approximate coordinates.
- Camera capture and photo selection. Photos must be JPG, PNG, or WebP. The app shrinks them (800 px, about 500 KB at most), and a photo that is still too large is rejected before saving. Other formats are rejected too. On desktop browsers, large PNG files are not shrunk and may be rejected; use a JPG or a smaller photo. Phone cameras give JPG photos, which are shrunk.
- Recording location explains why it failed (location services off, permission denied or blocked, timed out). A report still needs recorded coordinates before it can be submitted.
- My Reports shows active reports; History shows resolved reports.
- Details show the photo, report information, timestamps, and status progress.
- Pending means Submitted. Only pending reports can be edited or deleted, enforced in Firestore rules and transactions.
- Editing a pending report shows its current photo. Leaving the form with unsaved changes asks before discarding them.
- Demo button advances Submitted → Under Review → In Progress → Resolved. The screens say these changes are simulated for the class demo, and each status has its own color (grey, orange, blue, green). No maintenance dashboard or notifications.

## Firebase
Project: `aclon-franz`. QuickFix has separate web, Android, and iOS app registrations.
Reports live in `quickfix_reports`. Each photo lives in `quickfix_photos/{reportId}` (same id as its report) as base64 text, with the owner, the content type, and a timestamp.
Activity 5's `users` collection remains intact. QuickFix registration uses Firebase Auth displayName and does not overwrite Activity 5 profiles.

**Photos are stored in Firestore, not Firebase Storage.** This is a change from the original plan. Firebase Storage needs the paid Blaze plan, and this project stays on the free Spark plan, so live photo uploads were impossible. Photos are small images saved as text in a separate Firestore document. This was the owner's decision on 2026-10-22; Firebase Storage was not required by the assignment. The app no longer uses Firebase Storage. `storage.rules` stays in the repository, unused. No billing change is made by this project.

Rules for photos: only the owner can read a photo, a photo is created together with its report, a photo can be replaced or deleted only while its report is Submitted, and a photo must be JPEG, PNG, or WebP and at most 700,000 characters of text.

**The Firestore rules must be deployed before the live app can save reports** (the older rules reject the new photo documents). Before deploying, copy the deployed rules from the Firebase Console (Firestore Database, Rules) and compare them with `firestore.rules`. Keep Activity 5's `users` block. Do not deploy Activity 5's older rules alone; that removes QuickFix report access.

```sh
flutter pub get
flutter run -d chrome
firebase deploy --only firestore:rules --project aclon-franz
```

Android builds made before this change (such as release `v1.1.0`) use Firebase Storage and cannot save reports on the live project. Use a build made after this change.

## Local demonstration without billing
Use Firebase emulators; accounts and reports are separate from live Firebase:

```sh
firebase emulators:start --only auth,firestore --project aclon-franz
flutter run -d chrome --dart-define=USE_EMULATORS=true
# Android emulator: also pass --dart-define=EMULATOR_HOST=10.0.2.2
# Physical phone: pass the computer's LAN IP and configure emulator hosts for LAN access.
```

Ports: Auth 9199, Firestore 8188, Emulator UI 4108. (The Storage emulator on 9299 is no longer needed.)
Never use emulator mode for a production build.

## Device checks
- Camera: test on a real Android/iOS device. Desktop web may show a file picker for camera capture.
- Location: request while near the problem, use foreground permission only, and store coordinates rounded to 3 decimals (roughly 100 m). Browser location needs localhost or HTTPS.
- Test denied location permission, camera cancellation, and unavailable services.
- Android minimum API: 24. iOS minimum: 15.0. iOS permission descriptions are included.

## Tested where (last full pass: 2026-10-22)
| Area | Emulator / browser | Real phone |
| --- | --- | --- |
| Register, sign in, sign out | Passed in Chrome against local emulators | Not tested |
| Submit with photo, view, edit with photo preview, replace photo, delete pending (report and photo removed together), status simulation, History | Passed in Chrome against local emulators (photos stored in Firestore) at 412 px | Not tested |
| Photo limits | A 4.8 MB JPG was shrunk to about 78 KB; an 11.5 MB PNG was rejected with a message (a GIF was rejected in an earlier pass, same check) | Real phone camera photo sizes not tested |
| Report whose photo document is missing | Page loads and shows "The photo could not be loaded" with Retry | Not applicable |
| 320 px wide screens and 2x text | Checked in Chrome before the photo change (list, form, details); login has a widget test | Not tested |
| Location denied message, mock location | Passed in Chrome (permission denied, then a mock position) | Real GPS and permission dialogs not tested |
| Camera capture | Desktop browser shows only a file picker | Not tested |
| Firestore rules (reports, photos, Activity 5 profiles) | Emulator tests passed (`tools/check_rules.cjs`) | Not applicable |
| Live Firebase with the new rules | Not tested: the new rules are not deployed yet | Not tested |
| Builds | Web (production and emulator) and Android release APK built | APK not installed on a phone; iOS not built |

## Data lifecycle
A report and its photo are saved together in one transaction, replaced together when a pending report is edited with a new photo, and deleted together. If a save or delete fails, nothing is left half done, so there are no unused photo objects to clean up and no cleanup job is needed. Editing a report without choosing a new photo leaves its photo untouched.

Because Activity 5 shares this Firebase project, use QuickFix's combined Firestore rules when deploying. Redeploying Activity 5's older rules alone would remove QuickFix report access.

## Checks
```sh
flutter analyze
flutter test
flutter build web
flutter build apk --release
# Security/lifecycle tests use a disposable demo project in emulators:
npm install --prefix /private/tmp/quickfix-rule-tests @firebase/rules-unit-testing firebase
QUICKFIX_TEST_DEPS=/private/tmp/quickfix-rule-tests firebase emulators:exec --project demo-quickfix --only firestore 'node tools/check_rules.cjs'
# With the regular emulators running, seed the two local demo logins:
node tools/seed_demo.cjs
```

The rule checks cover owner-only reads, required field validation, legal status progression, pending-only edits and deletion, a report needing its photo (and a photo needing its report), photo type and size limits, photo privacy, all-or-nothing deletion, and existing Activity 5 profile access.
Fresh local emulators can be seeded with `node tools/seed_demo.cjs`. Both demo emails listed in that script use `quickfix-local-only` as their local password. This password is for the local emulator only; live Firebase credentials are not included. Existing emulator accounts keep their current passwords. Local emulator data is reset when the emulators stop unless explicitly exported. Web emulator sign-in uses memory only; sign in again after reloading the page. Live Firebase keeps its normal sign-in persistence.

To build the standalone emulator demo: `flutter build web --no-wasm-dry-run --dart-define=USE_EMULATORS=true --output build/web-demo`, then serve `build/web-demo` locally. This emulator build is for local demonstration only.
