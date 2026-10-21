# QuickFix

Student campus maintenance reporting, built with Flutter for Android, iOS, and web.
Written in a simple student coding style using standard widgets, maps, and setState.

## Start here (teammates)

Install Flutter 3.44.8 or newer with Dart 3.12.2, Node.js 22 or newer, Java 21 or newer, and Firebase CLI (`npm install -g firebase-tools`). Android development also needs Android Studio and its SDK; iOS needs macOS and Xcode.

After cloning this repository, open a terminal in the `quickfix` folder:

```sh
flutter pub get
firebase emulators:start --only auth,firestore,storage --project aclon-franz
```

Keep that terminal open. In a second terminal in the same folder:

```sh
node tools/seed_demo.cjs
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

Sign in with `maria.santos.act5@example.com` or `juan.delacruz.act5@example.com`, using local password `quickfix-local-only`. You can also register a new local account. A running local demo supports photos without a paid Firebase plan. Real Firebase project permissions are only needed for console access or deployment.

For an Android emulator, add `--dart-define=EMULATOR_HOST=10.0.2.2` to `flutter run`. Test real camera capture on a phone; desktop browsers may open a file picker instead.

Firebase client configuration is included to identify the registered apps. It does not grant Firebase Console, administrator, or database access. Service account credentials, logs, generated builds, local SDK paths, and private handoff notes are excluded.

## Features
- Firebase email/password registration and login. Existing Activity 5 logins work because the project shares Firebase Authentication.
- Submit a title, description, campus location, category, photo, and approximate coordinates.
- Camera capture and photo selection; photos are limited to 5 MB.
- My Reports shows active reports; History shows resolved reports.
- Details show the photo, report information, timestamps, and status progress.
- Pending means Submitted. Only pending reports can be edited or deleted, enforced in Firestore rules and transactions.
- Demo button advances Submitted → Under Review → In Progress → Resolved. No maintenance dashboard or notifications.

## Firebase
Project: `aclon-franz`. QuickFix has separate web, Android, and iOS app registrations.
Reports live in `quickfix_reports`; photos live in `quickfix/{uid}/{reportId}/`.
Activity 5's `users` collection remains intact. QuickFix registration uses Firebase Auth displayName and does not overwrite Activity 5 profiles.
Photo bytes are read with authenticated Storage requests, rather than public download links.

**Live photo uploads are blocked until the owner enables Blaze billing and creates the default Firebase Storage bucket.** Billing is currently disabled on this project. The application does not save a report if its required photo cannot upload. No billing upgrade is performed by this project.

Before live uploads: create the default `aclon-franz.firebasestorage.app` bucket, then deploy Storage rules. Creating a differently named bucket requires updating `storageBucket` in `lib/firebase_options.dart`.

```sh
flutter pub get
flutter run -d chrome
firebase deploy --only firestore:rules --project aclon-franz
# After Storage is available:
firebase deploy --only storage --project aclon-franz
```

## Local demonstration without billing
Use Firebase emulators; accounts and reports are separate from live Firebase:

```sh
firebase emulators:start --only auth,firestore,storage --project aclon-franz
flutter run -d chrome --dart-define=USE_EMULATORS=true
# Android emulator: also pass --dart-define=EMULATOR_HOST=10.0.2.2
# Physical phone: pass the computer's LAN IP and configure emulator hosts for LAN access.
```

Ports: Auth 9199, Firestore 8188, Storage 9299, Emulator UI 4108.
Never use emulator mode for a production build.

## Device checks
- Camera: test on a real Android/iOS device. Desktop web may show a file picker for camera capture.
- Location: request while near the problem, use foreground permission only, and store coordinates rounded to 3 decimals (roughly 100 m). Browser location needs localhost or HTTPS.
- Test denied location permission, camera cancellation, and unavailable services.
- Android minimum API: 24. iOS minimum: 15.0. iOS permission descriptions are included.

## Data lifecycle
Replacing a photo removes the old photo after the report saves. Failed writes attempt to remove newly uploaded images. Deleting a pending report removes its document, then its photo. Interrupted requests can leave unused Storage objects; failed cleanup is reported for deletion and should be checked in Storage. This school project does not have a server cleanup job.

Because Activity 5 shares this Firebase project, use QuickFix's combined Firestore rules when deploying. Redeploying Activity 5's older rules alone would remove QuickFix report access.

## Checks
```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
# Security/lifecycle tests use a disposable demo project in emulators:
npm install --prefix /private/tmp/quickfix-rule-tests @firebase/rules-unit-testing firebase
QUICKFIX_TEST_DEPS=/private/tmp/quickfix-rule-tests firebase emulators:exec --project demo-quickfix --only firestore,storage 'node tools/check_rules.cjs'
# With the regular emulators running, seed the two local demo logins:
node tools/seed_demo.cjs
```

The rule checks cover owner-only reads, required field validation, legal status progression, pending-only edits/deletion, image limits, photo privacy, and existing Activity 5 profile access.
Fresh local emulators can be seeded with `node tools/seed_demo.cjs`. Both demo emails listed in that script use `quickfix-local-only` as their local password. This password is for the local emulator only; live Firebase credentials are not included. Existing emulator accounts keep their current passwords. Local emulator data is reset when the emulators stop unless explicitly exported. Web emulator sign-in uses memory only; sign in again after reloading the page. Live Firebase keeps its normal sign-in persistence.

To build the standalone emulator demo: `flutter build web --no-wasm-dry-run --dart-define=USE_EMULATORS=true --output build/web-demo`, then serve `build/web-demo` locally. This emulator build is for local demonstration only.
