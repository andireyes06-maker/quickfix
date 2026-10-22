# QuickFix UI Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native, in this session) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the audit's accessibility failures and usability gaps and unify the color theme, without changing app behavior.

**Architecture:** Edits inside the existing pages plus component themes in `main.dart`. Small plain State methods (`statusColor`, `categoryIcon`, `shortDate`) like the existing `formatDate`. No new files, packages, or widget classes.

**Tech Stack:** Flutter 3.44.8, Material widgets. Firebase emulators and Chrome for visual checks.

**Spec:** `QUICKFIX-UI-SPEC.md` (approved by Airen 2026-10-22). Audit: `QUICKFIX-UI-AUDIT.md`.

## Global Constraints
- `~/Documents/FLUTTER_STYLE_HANDOFF.md` is a requirement: StatefulWidget, setState, maps, standard widgets, braces on every callback, double quotes, no `late`, no arrow actions, no typedefs, no cascades, no `?.` chains, no new packages, no model or new widget classes, no `Theme.of`, no `ColorScheme.fromSeed`. Colors directly on widgets. Dialogs: `TextButton` cancel, `ElevatedButton` action.
- Colors (measured): Submitted `Colors.grey.shade700`; Under Review `Color(0xFFB45309)`; In Progress `Colors.blue.shade800`; Resolved `Colors.green.shade800`; delete/discard/error-delete `Colors.red.shade800`; unchecked progress `Colors.grey.shade600`; quiet captions `Colors.grey.shade700`.
- No data, rules, Firebase, or behavior changes. No deploy, push, or release unless Airen says so.
- Simulation stays clearly labeled as a demonstration.
- Visual checks only with `--dart-define=USE_EMULATORS=true`. Stop servers by exact command, never by broad port lists.
- User-facing text has no em dashes. Commits end with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Done means `flutter analyze` says "No issues found!", `flutter test` passes, and anything not checked is stated plainly.

## Review Focus
1. A 3-line title plus the status/date row on a list card at 320 px and 2x text: no overflow (use `Wrap`). Phase 1 Task 4, Phase 3.
2. A just-created report (`createdAt` still null): no date shown, no crash. Task 3.
3. Filtered empty state names the filter and returns to the normal text on "All". Task 3 and Task 4.
4. The theme change must not leave purple on other surfaces: dropdown menu, snackbar, dialogs, bottom bar, chips. Task 4 screenshots.
5. Each status color on its card background and with white text still passes 4.5:1 (re-measure). Task 4 and Phase 3.

## File Structure
- Modify `lib/main.dart` (theme), `lib/pages/reports_page.dart` (list, header, empty states), `lib/pages/report_details_page.dart` (status color only in Phase 1).
- Phase 2: `report_details_page.dart`, `report_form_page.dart`, `login_page.dart`. Phase 3: `README.md`, `HANDOFF.md`.

---

## Phase 1: theme, colors, list

### Task 1: Component themes
**Files:** Modify `lib/main.dart` (the `ThemeData(...)` block).
- [ ] Add to `ThemeData` (Flutter 3.44 names), keeping the existing `appBarTheme`, `inputDecorationTheme`, `elevatedButtonTheme`:
  - `cardTheme: CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent, elevation: 1)`
  - `dialogTheme: DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent)`
  - `textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.indigo))`
  - `outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo, side: BorderSide(color: Colors.indigo)))`
  - `chipTheme: ChipThemeData(backgroundColor: Colors.white, selectedColor: Colors.indigo.shade50)`
  - `bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: Colors.white)`
- [ ] `flutter analyze`. Expected: no issues. If a class name differs in this Flutter version, use the analyzer's suggestion (for example `CardTheme` vs `CardThemeData`).

### Task 2: Status colors
**Files:** Modify `lib/pages/reports_page.dart` and `lib/pages/report_details_page.dart` (`statusColor`).
- [ ] Under Review returns `Color(0xFFB45309)`. Other values unchanged. `grep -rn "Colors.orange" lib` must find nothing afterward.

### Task 3: List cards, header, empty states
**Files:** Modify `lib/pages/reports_page.dart`.
**Interfaces:** Produces State methods `IconData categoryIcon(String category)` and `String shortDate(Timestamp? value)` (returns `""` when null, else `"${date.month}/${date.day}/${date.year}"` in local time).
- [ ] `categoryIcon`: Furniture `Icons.chair_outlined`, Electrical `Icons.electrical_services`, Plumbing `Icons.plumbing`, Equipment `Icons.devices_other`, anything else `Icons.build_outlined`. The card's `CircleAvatar` uses it (indigo on `Colors.indigo.shade50`, as now).
- [ ] Card subtitle: location, then a `Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, ...)` with the status (bold, `statusColor`) and, only when `shortDate(...)` is not empty, the date in `Colors.grey.shade700`.
- [ ] Header on tab 0: subtitle "Report a problem. Track the progress." and under it a caption `Text("Demo: status changes are simulated.", style: TextStyle(fontSize: 12, color: Colors.grey.shade700))`. Tab 1 header unchanged.
- [ ] Empty state on tab 0 with `filter != "All"`: title "No $filter reports", body "Reports that reach this status will show up here." Otherwise the existing texts.
- [ ] `flutter analyze`. Expected: no issues.

### Task 4: Phase 1 check and commit
- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Start emulators (`--only auth,firestore`), seed accounts, seed five reports (all statuses, one with a very long title, one with no `createdAt` is not needed in the browser; Review Focus 2 is by code reading), build the emulator web demo, serve it. Screenshots at 412 px: login, list (All, each filter, an empty filter), History, empty state (second demo account), a form dropdown open, a snackbar, the delete dialog. Confirm no purple tint remains and the dropdown menu, snackbar, and bottom bar look right (Review Focus 4).
- [ ] Re-measure with the contrast checker: each status color on white; grey date and caption on white and on `#F5F6F8` (Review Focus 5).
- [ ] 320 px and 2x text spot check of the list with the long title (Review Focus 1; for 2x use the temporary uncommitted `builder:` text-scale override from the earlier pass, then revert and confirm `git diff lib/main.dart` shows only the theme change).
- [ ] Stop servers by exact command; remove temporary files. Update `HANDOFF.md`. `git add lib && git commit -m "feat: unified theme, accessible status colors, richer list cards"`.

---

## Phase 2: details, form, dialogs, semantics

### Task 5: Details page
**Files:** Modify `lib/pages/report_details_page.dart`.
- [ ] Status `Chip`: `backgroundColor: statusColor(status)`, white bold label, no border. Category chip unchanged.
- [ ] Progress list: current step text bold and filled indigo check; earlier steps checked; later steps `Icons.radio_button_unchecked` in `Colors.grey.shade600`.
- [ ] Photo `Image.memory(..., semanticLabel: "Photo of the reported problem")`.
- [ ] Coordinates and the Submitted/Last update lines as `fontSize: 13`, `Colors.grey.shade700` captions.
- [ ] "Delete report" text and icon `Colors.red.shade800`. Delete dialog action: `ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white)`.

### Task 6: Form
**Files:** Modify `lib/pages/report_form_page.dart`.
**Interfaces:** Produces fields `String photoError = ""` and `String locationError = ""`; `error` stays for save failures.
- [ ] Intro text adds "Everything on this page is required." Headings "Problem photo (required)" and "Approximate location (required)".
- [ ] Take photo: `ElevatedButton.icon`; Choose photo: `OutlinedButton.icon`; Record location: `OutlinedButton.icon`. After recording: green check icon (`Colors.green.shade800`) plus "Location recorded: lat, lon".
- [ ] Route messages: type, size, camera, picker, recover-photo, and "Please take or choose a photo" go to `photoError`; location failures and "Tap Record location..." go to `locationError`; each shows under its own section. Clear each where `error` is cleared today.
- [ ] Helper under the photo buttons: "One JPG, PNG, or WebP photo. Large photos are shrunk automatically." (drop the desktop note).
- [ ] Wrap the three error texts in `Semantics(liveRegion: true, child: Text(..., style: TextStyle(color: Colors.red.shade800)))`. Edit-preview image gets the same `semanticLabel`.
- [ ] Discard dialog action: same red `ElevatedButton.styleFrom` as Task 5.

### Task 7: Login
**Files:** Modify `lib/pages/login_page.dart`.
- [ ] Wrap the error text in `Semantics(liveRegion: true, ...)`. Nothing else.

### Task 8: Phase 2 check and commit
- [ ] `flutter analyze`, `flutter test`. Browser pass at 412 px against emulators: every details status (chip, progress marker, captions), delete and discard dialogs, form clean / with errors (photo and location messages appear under their sections) / photo and location recorded, camera and location denial messages, register error. Check the accessibility tree (page snapshot) shows the photo label and error announcements. Confirm submit, edit, replace photo, delete, and simulate still work (regression).
- [ ] Update `HANDOFF.md`; `git add lib && git commit -m "feat: clearer details and form, red destructive actions, announced errors"`.

---

## Phase 3: verification, docs

### Task 9: Full verification
- [ ] Final contrast re-measure of every pair in the spec table. Screenshots at 412 px and 320 px, and 2x text, for all screens in the spec's acceptance list. Template scan: `grep -nE "\blate\b|VoidCallback|RegExp|tryParse|\?\?=|=>|\.\.[a-z]" lib` shows only `createState() =>`. `flutter build web` and `flutter build apk --release` succeed.

### Task 10: README, handoff, commit
- [ ] README: UI notes (colors and contrast, required cues, red destructive actions, themes), tested-where rows (new look checked in Chrome only; TalkBack and real phone not tested). `HANDOFF.md` with what Airen must do. `git commit -m "docs: README for UI improvements"`. Do NOT push, release, or deploy without Airen's instruction.
