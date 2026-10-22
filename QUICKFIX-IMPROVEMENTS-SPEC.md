# QuickFix improvements: spec

Status: DRAFT, waiting for Airen's approval. No code has been changed.
Date: 2026-10-22. Baseline: git commit `e6056c6`, clean tree, `flutter analyze` clean, `flutter test` passing.

## Why
The first version covers all nine requirements. A read-only review found two real bugs and several usability gaps. This spec makes focused fixes only. It does not rewrite the app.

## Goals
1. Show the real reason when location fails (services off, denied, blocked, timeout).
2. Accept only JPG, PNG, or WebP photos, and reject anything else with a clear message before upload.
3. Show the current photo when editing a pending report.
4. Ask before discarding unsaved form input.
5. Make status display consistent (one color per status) and label the simulation clearly everywhere statuses appear.
6. Fix unstable list ordering for a just-created report.
7. Harden registration and login error handling.
8. Test small screens (320 px wide) and large text (2x).
9. Update the README with behavior changes, a "tested where" table, and the Storage first-deploy note.

## Non-goals and anti-goals
- No Firestore or Storage rules changes, and no deploys of any kind.
- No billing changes, no other photo service, no project changes, no push.
- No staff dashboard, new packages, model classes, state management, or shared widget classes.
- Location stays required (Airen approved my recommendation). Not making it optional, because that needs a rules change and a deploy on the project shared with Activity 5.
- My Reports keeps showing active reports only. Resolved reports stay in History, as the README says.
- Anti-goal: any change that looks like a rewrite, or that breaks existing Activity 5 data or access.

## Constraints
- Follow `~/Documents/FLUTTER_STYLE_HANDOFF.md`: StatefulWidget, setState, maps, standard widgets, braces on callbacks, double quotes, plain functions with a short comment above.
- `async` stays where Firebase and device calls need it.
- Existing structure stays: `lib/main.dart` and `lib/pages/*.dart`.
- Git checkpoint before the first edit: local tag `pre-review-improvements` on `e6056c6`. Commit after each phase.
- Browser and emulator checks must run with `--dart-define=USE_EMULATORS=true` so no test ever writes to live `aclon-franz` data.

## Changes (file references are from the baseline)

### Phase 1: report form (`lib/pages/report_form_page.dart`)
- `getLocation()` (`:128-180`): stop throwing and catching. Set a specific `error` string for each case and return. Cases: services off, denied, denied forever, timeout, other. The `finally` still clears `deviceBusy`.
- `usePhoto()` (`:69-92`): check the file's mime type, or its extension when the mime type is empty. Allow only jpeg, png, webp. Otherwise show "Choose a JPG, PNG, or WebP photo." and keep the previous photo. Fix the hint text (`:437`, `:473`) to say JPG, PNG, or WebP.
- Edit mode: load the current photo with `getData` in `initState` and show it above the buttons. A failed load shows a short text and does not block editing.
- Unsaved changes: add a `changed` flag, set by field changes and by photo, category, and location changes. `PopScope` asks "Discard changes?" only when the flag is set and the form is not busy. Saving still pops normally.

### Phase 2: status display, list, login
- `reports_page.dart` and `report_details_page.dart`: add a small `statusColor(String status)` function in each file (duplicated on purpose, no shared file). Colors: Submitted grey 700, Under Review orange 800, In Progress blue 800, Resolved green 800. Use it for the list status text and for the details chip. Text always stays visible, so color is never the only signal.
- Simulation labels: the My Reports subtitle and the details "Report progress" heading each get a short "status changes are simulated for this class demo" line. The existing "Project demonstration" card stays.
- `reports_page.dart:143-150`: sort so a report with a null `createdAt` (just created, server time pending) sorts first.
- `login_page.dart`: catch a failed `updateDisplayName` separately so a created account is not reported as a failure. Catch non-Firebase errors with a generic message. Use `Colors.red.shade800` for the error, as the other pages do.

### Phase 3: tests, verification, docs
- Widget tests (no Firebase needed): login at 320x568 with 2x text scale shows no overflow; password mismatch shows its error.
- Re-run the existing rules and lifecycle tests (`tools/check_rules.cjs`) against the emulators. Install the test dependencies in the session scratchpad, not in the project.
- Builds: `flutter build web` (production config), `flutter build web` with `USE_EMULATORS` (demo), `flutter build apk --debug`.
- Browser against emulators at 412 px and 320 px: submit, edit with photo preview, reject a `.gif`, deny location, cancel the photo picker, discard dialog, status colors, simulate through to Resolved, History, pending delete.
- Large text on the signed-in pages: use a temporary, uncommitted `builder:` text-scale override in `main.dart`, then revert it.
- README: behavior changes, tested-where table, Storage first-deploy note (the rules read Firestore, so the first Storage deploy asks to grant a cross-service permission), live-rules caution.
- Update `HANDOFF.md` (git-ignored) and write a handoff at each phase boundary.

## Findings with no code change (documented)
- Rare case: if a save succeeds but the response is lost, the `finally` cleanup (`report_form_page.dart:288`) can delete the photo of a saved report. Low probability, so the README gets a line and no redesign.
- Interrupted uploads can still leave unused Storage objects. Already documented.

## Not verified, and why
- Live `aclon-franz` rules were NOT read. `gcloud` is not installed and the Firebase CLI has no read command. This spec changes no rules, so nothing here depends on them. If a rules change ever becomes necessary, the deployed text must be read first (Console copy from Airen, or an approved method) before anything is written.
- Real phone camera and location permission behavior, iOS build, live Storage uploads (billing is off). These need Airen.

## Calls I made (Airen can overturn)
- Status colors above, and duplicating the small function in two files.
- Mime type first, extension as fallback, for photo checks.
- Discard-confirmation on the form is included but is the first thing to drop if scope needs trimming.
- No magic-byte inspection of photo contents (too advanced for this project).

## Needs Airen after the work
- Test camera and location on a real phone (denial, cancel, services off).
- Enable Blaze and create the default Storage bucket if live photo uploads are wanted, then deploy `storage.rules`.
- Decide when to push to GitHub.
