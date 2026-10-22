# QuickFix Redesign and Remake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native, in this session) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every screen the approved "Campus Service" look (navy and gold, white 16 px cards, greeting and count tiles, three-step form) without changing any behavior.

**Architecture:** Same files and widgets. Theme tokens in the existing `ThemeData` block; small top-level pure helper functions (`firstNameOf`, `openReportsLine`, `stepsLine`) so the new wording logic is unit tested. No new files, packages, fonts, or widget classes.

**Tech Stack:** Flutter 3.44.8, Material widgets, Firebase emulators and Chrome for visual checks.

**Spec:** `QUICKFIX-REMAKE-SPEC.md` (approved by Airen 2026-10-22). Earlier work: `QUICKFIX-UI-AUDIT.md`.

## Global Constraints
- `~/Documents/FLUTTER_STYLE_HANDOFF.md` is a requirement: StatefulWidget, `setState`, maps, standard widgets, braces on every callback, double quotes, no `late`, no arrow actions, no typedefs, no cascades, no `?.` chains, no `??=`, no new packages, model or widget classes, no `Theme.of`, no `ColorScheme.fromSeed`. Colors set directly (hex literals are fine and repeated per file on purpose; pages cannot import `main.dart`). Dialogs: `TextButton` cancel, `ElevatedButton` action.
- Tokens: navy `Color(0xFF1F3A5F)`; gold `Color(0xFFF2B134)`; page `Color(0xFFF3F5F9)`; border `Color(0xFFDFE5EE)`; muted text `Color(0xFF44516A)`; icon circle `Color(0xFFE6ECF5)`; status colors unchanged (grey 700, `Color(0xFFB45309)`, blue 800, green 800); danger `Colors.red.shade800`; card radius 16.
- Status text only on white cards or inside filled pills (brown is only 4.6:1 on the page color).
- No data, rules, Firebase, auth, or behavior changes. No deploy, push, or release unless Airen says so.
- Existing login test strings must stay exactly: "New to QuickFix? Create an account", "Create account", "Please enter your full name", "Please enter your email", "Please enter your password", "Passwords do not match".
- Visual checks only with `--dart-define=USE_EMULATORS=true`. Stop servers by exact command. User-facing text has no em dashes. Commits end with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Done means `flutter analyze` says "No issues found!", `flutter test` passes, and anything not checked is stated plainly.

## Review Focus
1. Count tiles toggle the filter, and the filter survives stream updates; header sits inside the `StreamBuilder` without flicker. Task 4, Task 5.
2. Accounts with no display name (Activity 5 accounts may have none): greeting is "Hello, there". Task 1 test and Task 4.
3. Three tiles at 320 px and 2x text: labels wrap, nothing overflows. Task 5, Task 9.
4. Step counter updates on typing, choosing a photo, and recording location; edit mode starts with the steps that are already done. Task 7, Task 8.
5. Contrast: white on navy, navy on gold, status pills, status text on white cards. Task 9.

## File Structure
- Phase 1: `lib/main.dart`, `lib/pages/login_page.dart`, `lib/pages/reports_page.dart`, `test/widget_test.dart`.
- Phase 2: `lib/pages/report_details_page.dart`, `lib/pages/report_form_page.dart`, `test/widget_test.dart`.
- Phase 3: `README.md`, `HANDOFF.md`.

---

## Phase 1: tokens, sign-in, My Reports

### Task 1: Wording helpers (TDD)
**Files:** Modify `lib/pages/reports_page.dart` (top level), `test/widget_test.dart`.
**Interfaces:** Produces top-level `String firstNameOf(String? displayName)` and `String openReportsLine(int count)`.
- [ ] Write failing tests with these assertions: `firstNameOf("Maria Santos")` is `"Maria"`; `firstNameOf("  Juan  ")` is `"Juan"`; `firstNameOf("")` is `"there"`; `firstNameOf(null)` is `"there"`; `openReportsLine(0)` is `"No open reports right now."`; `openReportsLine(1)` is `"1 open report. Thanks for helping our campus."`; `openReportsLine(3)` is `"3 open reports. Thanks for helping our campus."`.
- [ ] `flutter test`. Expected: FAIL (functions not defined).
- [ ] Implement both with plain `if` statements (trim, split on space, first word).
- [ ] `flutter test`. Expected: pass.

### Task 2: Theme tokens and color replacement
**Files:** Modify `lib/main.dart` and every page.
- [ ] `ThemeData`: `scaffoldBackgroundColor` page color; keep `canvasColor` white; `appBarTheme` navy with white text and `centerTitle: true`; `elevatedButtonTheme` navy, white text, `padding: EdgeInsets.all(16)`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`; `textButtonTheme` and `outlinedButtonTheme` navy (outlined side navy); `cardTheme` white, radius 16, 1 px border color, elevation 0; `dialogTheme` white; `chipTheme` white background; `bottomNavigationBarTheme` white. Update the `primarySwatch` comment/value only if analyze requires.
- [ ] Replace every `Colors.indigo` (and `.shade50`) in `lib/` with the navy literal or the icon-circle literal. `grep -rn "Colors.indigo" lib` must find nothing afterward.
- [ ] `flutter analyze`. Expected: no issues.

### Task 3: Sign-in and register
**Files:** Modify `lib/pages/login_page.dart`.
- [ ] Layout (no overlap, my call for 2x text safety): a full-width navy block at the top with a gold rounded logo tile (`Icons.handyman_outlined`, navy icon), "QuickFix" (white, bold) and "Campus maintenance reports" (white, 13 px or larger); below it, centered with `maxWidth` 440, a white card (padding 16, radius 16) containing the existing form, errors, buttons, and mode switch. Headings "Welcome back" or "Create your student account" keep their text. The whole page stays scrollable.
- [ ] Keep every string, validator, and the busy behavior unchanged. Run `flutter test`. Expected: all existing login tests still pass.

### Task 4: My Reports
**Files:** Modify `lib/pages/reports_page.dart`.
- [ ] Wrap the body `Column` in the `StreamBuilder` so counts and list share one snapshot; while there is no data show the header with the greeting and a progress indicator below. Filter state stays in `filter`.
- [ ] Header (navy block, white text): `Text("Hello, ${firstNameOf(FirebaseAuth.instance.currentUser!.displayName)}")` (bold 20), then `openReportsLine(openCount)` where `openCount` counts documents whose status is not "Resolved". Tab 1 (History) header keeps its own title and subtitle in the same navy block.
- [ ] Count tiles (tab 0 only): three equal tiles in a `Row` of `Expanded` children for Submitted, Under Review, In Progress, each a white rounded card with the count (bold 18, navy) and the label (12 px or larger, muted, may wrap). Tapping a tile sets `filter` to its status, or back to "All" when it is already selected; the selected tile has a 2 px navy border. Remove the filter chips.
- [ ] Cards: keep the category icon circle, title, location, and the status plus date `Wrap` already built; white, 16 px radius via the theme. Gold FAB (`backgroundColor` gold, `foregroundColor` navy). Bottom bar `selectedItemColor` navy.
- [ ] Empty states: filtered "No $filter reports" (existing); no open reports on tab 0 with filter "All": title "You are all caught up", body "No open reports right now. Use New report if something needs fixing."; History empty unchanged.
- [ ] `flutter analyze`. Expected: no issues.

### Task 5: Phase 1 check and commit
- [ ] `flutter analyze`, `flutter test` pass.
- [ ] Emulators (`--only auth,firestore`), seed accounts and five reports (all statuses, one long title), build the emulator web demo, serve. Chrome at 412 px: login, register, list, each tile filter and clearing it, filtered empty state, History, empty state (second demo account), one dialog. The no-display-name greeting ("Hello, there") cannot be reached through the app, because registration always sets a name, so it is covered by the unit test only. Review Focus 1 and 3: add a report from another session while a filter is on and confirm the filter holds; 320 px and 2x text (temporary uncommitted `builder:` override, then revert and confirm `git diff lib/main.dart` shows only the theme change).
- [ ] Stop servers; remove temp files; update `HANDOFF.md`; `git add lib test && git commit -m "feat: campus service look for sign-in and My Reports"`.

---

## Phase 2: details and form

### Task 6: Details
**Files:** Modify `lib/pages/report_details_page.dart`.
- [ ] Navy app bar (theme). Title, category chip (outlined white) and status pill as built. Section headings navy. Progress tracker: current step bold, earlier steps navy check, later steps `Colors.grey.shade600` hollow (already built; recolor to navy). "Submitted: ..." and "Last update: ..." quiet captions stay. Edit report is the navy theme button; Delete stays `red.shade800`; demonstration card unchanged and still labeled.
- [ ] `flutter analyze`. Expected: no issues.

### Task 7: Form steps (TDD for the wording)
**Files:** Modify `lib/pages/report_form_page.dart`, `test/widget_test.dart`.
**Interfaces:** Produces top-level `String stepsLine(int done)`.
- [ ] Failing test: `stepsLine(0)` is `"0 of 3 steps done."`; `stepsLine(2)` is `"2 of 3 steps done."`; `stepsLine(3)` is `"All set. Ready to submit."`. Run `flutter test`; expected FAIL. Implement; expected pass.
- [ ] Method `int stepsDone()` in the State: step 1 counts when title, description, and campus location texts are each non-empty after trimming; step 2 when `photo != null || hasPhoto`; step 3 when `latitude != null`.
- [ ] A thin white strip under the app bar shows `stepsLine(stepsDone())` (muted, bold for the count). `Form(onChanged: ...)` must call `setState` on every change so the line updates while typing (keep setting `changed = true`).
- [ ] Three white step cards, each with a gold number badge (navy bold number) and a navy heading: "Describe it" (title, description, campus location, category), "Add a photo (required)", "Where is it? (required)". Existing photo and location sections, buttons, errors, preview, and "Location recorded" row move into steps 2 and 3 unchanged. Submit stays a full-width navy button.
- [ ] `flutter analyze`, `flutter test`. Expected: clean, pass.

### Task 8: Phase 2 check and commit
- [ ] Browser pass at 412 px against emulators: details for each status; form clean (0 of 3), typing step 1 (1 of 3), photo (2 of 3), location (3 of 3, "All set"), edit mode starts correctly, errors under steps, discard and delete dialogs; regression: submit, edit, replace photo, discard, save, simulate to Resolved, pending delete, History. Console must be free of errors.
- [ ] `HANDOFF.md`; `git add lib test && git commit -m "feat: campus service look for details and three-step form"`.

---

## Phase 3: verification and docs

### Task 9: Full verification
- [ ] Re-measure every pair from the spec table in the final screens. Screenshots at 412 px, 320 px, and 2x text of every screen in the spec's acceptance list. Template scan: `grep -nE "\blate\b|VoidCallback|RegExp|tryParse|\?\?=|=>|\.\.[a-z]" lib` shows only `createState() =>`. `flutter build web` and `flutter build apk --release` succeed. Confirm `grep -rn "Colors.indigo" lib` finds nothing.

### Task 10: README, handoff, commit
- [ ] README: the new look in the feature list, tested-where rows (new look checked in Chrome only; TalkBack and a real phone not tested), no mention of the removed filter chips. `HANDOFF.md` final. `git commit -m "docs: README for the redesign"`. Do NOT push, release, or deploy without Airen's instruction.
