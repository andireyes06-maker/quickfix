# QuickFix redesign and remake: spec

Status: DRAFT, waiting for Airen's approval. No code has been changed for this spec.
Date: 2026-10-22. Baseline: `main` at `720dc7e` plus the UI work already committed (scope B, phases 1 and 2). Brainstorm result: Airen wants "friendly and official", chose direction A (navy and gold "Campus Service") and said "you decide" on what to borrow. Mockups: `.superpowers/brainstorm/` (local, git-ignored).

## Why
The app works and is accessible, but it looks like a default Material app. A full redesign gives it one clear identity: a campus service that is welcoming (greeting, counts, step-by-step form) and credible (navy, structure, formal wording). This replaces the unfinished phase 3 of the scope-B UI plan; its verification and README work is folded into this spec.

## Goals
1. One visual identity on every screen: navy and gold, white cards, 16 px rounded corners, category icons, filled status pills.
2. My Reports greets the student by name, shows counts, and lets the count tiles act as the status filters.
3. The new-report form becomes three numbered steps with a live "n of 3 steps done" line.
4. Sign-in and register get a branded header and a white form card.
5. Details get a clearer progress tracker and the same status pill as the list.
6. Everything stays accessible (measured contrast, labels, announced errors) and readable at 320 px and 2x text.

## Non-goals and anti-goals
- No change to data, Firestore rules, Firebase project, authentication, status simulation, or any behavior (submit, edit, delete, History, pending-only rules).
- No new packages, no custom fonts (default Roboto only), no model classes, no new widget classes, no `Theme.of`, no `ColorScheme.fromSeed`.
- Not in this pass: a new app icon, dark mode, list photo thumbnails, tap-to-enlarge photo, landscape or tablet layouts.
- No deploy, push, or release unless Airen says so.
- Anti-goal: decoration that costs readability or breaks the plain student-level code. If a feature needs complicated code, drop the feature.

## Constraints
- `~/Documents/FLUTTER_STYLE_HANDOFF.md` is a requirement: StatefulWidget, `setState`, maps, standard widgets, braces on callbacks, double quotes, plain methods with a short comment, dialogs with a `TextButton` cancel and an `ElevatedButton` action. Colors are set directly on widgets or in the existing `ThemeData` block in `main.dart`.
- Keep the file layout (`lib/main.dart`, `lib/pages/*.dart`).
- Keep all text free of em dashes.
- Status simulation stays clearly labeled as a demonstration.

## Design decisions (my calls, because Airen said "you decide")
**Colors (all measured):**
| Token | Value | Use | Contrast |
|---|---|---|---|
| Navy | `Color(0xFF1F3A5F)` | app bars, primary buttons, headings | 11.48:1 with white; 10.52:1 on page |
| Gold | `Color(0xFFF2B134)` | accent: New report button, step numbers | 6.08:1 with navy text on it |
| Page | `Color(0xFFF3F5F9)` | scaffold background | n/a |
| Border | `Color(0xFFDFE5EE)` | card outlines | decorative |
| Muted text | `Color(0xFF44516A)` | secondary text | 7.31:1 on page |
| Status | grey 700, `Color(0xFFB45309)`, blue 800, green 800 | pills, always with text | white on each 5.0 to 6.2; text on white cards 5.0 or better |
| Danger | `Colors.red.shade800` | delete, discard | 5.2:1 |
Status text that sits on the page color (not a white card) must be checked again; the brown measures 4.6:1 there, so status text stays on white cards or in filled pills.

**Borrowed from the other directions:** from B, 16 px card corners, circular category icons and a friendly empty state ("You are all caught up" when there are no open reports); from C, the formal subtitle "Campus maintenance reports" under the app name on sign-in and the app bar of the list. Not borrowed: the serif headline (no custom fonts), stamp-style statuses, the merged Open/Resolved list (History stays its own tab).

**My Reports (`reports_page.dart`):**
- Navy header block with "Hello, {first name}" (first word of the Auth display name; "Hello, there" if empty) and one line: "{n} open reports. Thanks for helping our campus." (one report: "1 open report."; none: "No open reports right now.").
- Three count tiles (Submitted, Under review, In progress) replace the filter chips. Tapping a tile filters the list; tapping it again clears the filter. Counts come from the same stream as the list.
- Cards: white, 16 px radius, light border, circular category icon, title, location, status pill plus date. The colored edge strip from the early mockup is not used.
- Gold "New report" button. Bottom navigation keeps My reports and History, navy when selected.
- Empty states: filtered ("No {status} reports"), none open (friendly), History (unchanged meaning).

**Sign in and register (`login_page.dart`):** navy top area with a gold logo tile, "QuickFix" and "Campus maintenance reports"; the form sits in a white card that overlaps the navy area. Same fields, validation, and errors as now.

**New report (`report_form_page.dart`):** a thin line under the app bar, "{n} of 3 steps done" or "All set. Ready to submit.", computed live from the form state. Three white step cards with gold number badges: 1 Describe it (title, description, campus location, category), 2 Add a photo (required), 3 Where is it (required, location recording). The photo and location messages from the earlier work stay under their own steps. Submit is a full-width navy button.

**Details (`report_details_page.dart`):** navy app bar, title, category chip and status pill, the photo, description, location with the quiet coordinates caption, a progress tracker (current step bold, earlier steps checked), Edit (navy) and Delete (red text), and the labeled demonstration card unchanged.

## Acceptance checks
- Every foreground/background pair in the table re-measured in the final build.
- `flutter analyze` clean; `flutter test` passes (existing tests updated if they depend on removed filter chips).
- Chrome against emulators at 412 px, 320 px, and 2x text: sign in, register, list (counts, each tile filter, empty states, History), details (each status), form (clean, errors, steps progressing, photo and location done), dialogs. Compare to the approved mockups.
- Regression pass: submit, edit, replace photo, discard, delete, simulate to Resolved, History.
- Template scan: no banned patterns in new or changed code. Console free of errors.
- README updated (new look, tested-where); `flutter build web` and `flutter build apk --release` succeed.

## Not verifiable by me
- The look and feel on a real phone, TalkBack or VoiceOver output, and whether Airen likes the result. I will show screenshots at the end of each phase.

## Phases
1. Theme tokens in `main.dart`, sign-in and register, My Reports (greeting, tiles, cards, empty states).
2. Details page and the three-step form.
3. Full verification at all sizes, README, handoff. New APK, push, and release only if Airen asks.

## Risks
- Count tiles replacing filter chips changes a familiar control. Mitigation: tiles stay clearly tappable (selected tile gets a navy outline) and the filter text is still shown.
- Moving the header inside the stream builder (for counts) must not lose the filter state or flash on updates. Check in the browser.
- The live step counter needs a `setState` on every text change in the form; keep it simple and watch typing performance.

## Needs Airen
1. Approve this spec, or change the decisions above (especially tiles as filters, the greeting, and the step counter).
2. Later: test on a real phone, and tell me when to push and release.
