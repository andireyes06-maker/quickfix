# QuickFix UI improvements (scope B): spec

Status: DRAFT, waiting for Airen's approval. No code has been changed.
Date: 2026-10-22. Baseline: `main` at `c5ac30f` (release `v1.2.0`). Source: `QUICKFIX-UI-AUDIT.md` (item ids A1 to C3 refer to it). Airen chose scope B.

## Why
The audit found real accessibility failures (two colors below 4.5:1, an undescribed photo, missing required-field cues) and screens that show less than a student needs when tracking reports. This pass fixes those and unifies the look, without changing what the app does.

## Goals
1. **Accessibility (A1 to A6):** every text color at least 4.5:1 and every meaningful icon at least 3:1 against its background (measured, not eyeballed); the photo has a screen-reader description; errors are announced; required things are marked.
2. **Required actions look required (B1):** photo and location are clear, prominent sections with their own error messages next to them.
3. **Danger looks dangerous (B2):** delete and discard actions use a red button.
4. **Status stands out (B3):** filled status chip, current step marked in the progress list.
5. **Richer list (B4, B5):** category icon and date on each card; empty state that names the active filter.
6. **Calmer text (B6, B7, B8):** student-friendly helper text, quieter timestamps and coordinates, shorter header with a small demo caption.
7. **One coherent color theme (C1):** no more Material 3 purple tint next to indigo.

## Non-goals and anti-goals
- Not doing B9 (show signed-in user), B10 (error layout jump), C3 (app icon), dark mode, photo thumbnails in the list (a photo read per row), tap-to-enlarge photo, or any change to data, rules, Firebase, or behavior.
- No new packages, model classes, new widget classes, `Theme.of`, or `ColorScheme.fromSeed`. No rules deploy, push, or release unless Airen says so.
- Anti-goal: a restyle that makes the app look like a different product or breaks the template's student level. Keep the indigo identity.

## Constraints
- `~/Documents/FLUTTER_STYLE_HANDOFF.md` is a requirement: StatefulWidget, setState, maps, standard widgets, braces on callbacks, double quotes, plain methods with a short comment. Colors are set directly on widgets (hex like `Color(0xFFB45309)` is fine, as in `main.dart` already). Dialogs keep a `TextButton` cancel and an `ElevatedButton` action.
- Component themes in `main.dart` use the Flutter 3.44 class names (`CardThemeData`, `DialogThemeData`); `main.dart` already sets `appBarTheme`, `inputDecorationTheme`, and `elevatedButtonTheme` the same way.
- Keep the simulation clearly labeled as a demonstration (original requirement).
- Commit after each phase. Commit messages end with the Claude co-author line.

## Design decisions (my calls; Airen can overturn)

**Colors (measured with the contrast checker)**
| Use | Value | Result |
|---|---|---|
| Submitted | `Colors.grey.shade700` #616161 | 6.19:1 with white text; 5.61:1 as text on a card |
| Under Review | `Color(0xFFB45309)` | 5.02:1 as text on white and with white text (replaces failing #EF6C00 at 2.79:1) |
| In Progress | `Colors.blue.shade800` #1565C0 | 5.75:1 with white text |
| Resolved | `Colors.green.shade800` #2E7D32 | 5.13:1 with white text |
| Delete and discard buttons, "Delete report" text | `Colors.red.shade800` #C62828 | 5.2:1 (replaces `Colors.red` at 3.41:1) |
| Unchecked progress circles | `Colors.grey.shade600` #757575 | 4.26:1 vs page, above the 3:1 non-text bar (replaces 2.48:1) |

**Theme (`main.dart`):** white cards with no tint (`CardThemeData`), white dialogs with no tint (`DialogThemeData`), indigo text buttons and outlined buttons (`textButtonTheme`, `outlinedButtonTheme`), selected filter chip in a light indigo. Existing appBar, input, and elevated button themes stay.

**List cards (`reports_page.dart`):**
- Leading icon by category through a `categoryIcon(String category)` method: Furniture `Icons.chair_outlined`, Electrical `Icons.electrical_services`, Plumbing `Icons.plumbing`, Equipment `Icons.devices_other`, anything else `Icons.build_outlined`.
- Title, then location, then a row with the status (bold, status color) and the creation date (`month/day/year`, grey). No date while `createdAt` is still pending.
- Empty state: with a filter other than All, "No {status} reports" and "Reports that reach this status will show up here." The All and History texts stay.
- Header: subtitle "Report a problem. Track the progress." plus a small grey caption "Demo: status changes are simulated." Same caption idea stays in the details progress section and the existing demonstration card.

**Details (`report_details_page.dart`):**
- Status chip filled with the status color, white bold text. Category chip stays outlined.
- Progress list: current step in bold and filled indigo check; earlier steps checked; later steps `grey.shade600` hollow circle.
- Photo gets `semanticLabel: "Photo of the reported problem"` (also on the edit preview).
- "Submitted" and "Last update" as quieter grey captions; coordinates as a small grey caption under the location text.
- "Delete report" in `red.shade800`; the delete dialog's Delete button is a red `ElevatedButton` (`backgroundColor: Colors.red.shade800, foregroundColor: Colors.white`).

**Form (`report_form_page.dart`):**
- Intro line says everything on the page is required. Section headings read "Problem photo (required)" and "Approximate location (required)".
- Take photo is a filled indigo `ElevatedButton.icon`; Choose photo an `OutlinedButton.icon`; Record location an `OutlinedButton.icon`. After recording, a green check and "Location recorded: lat, lon".
- Two new fields, `photoError` and `locationError`, so photo and location messages (type, size, camera, permission, "please take a photo", "tap Record location") appear directly under their own section. The existing `error` stays for save failures near Submit.
- Helper under the photo buttons: "One JPG, PNG, or WebP photo. Large photos are shrunk automatically." The desktop-browser note moves to the README only.
- Error messages in the form and on the login page are wrapped in `Semantics(liveRegion: true, ...)` so they are announced.
- Discard dialog's action button is red like Delete.

**Login (`login_page.dart`):** error text wrapped for announcement; otherwise unchanged (it already picks up the new theme for its text button).

## Acceptance checks
- Every foreground/background pair above re-measured in the final build; none below its threshold.
- `flutter analyze` clean; `flutter test` passes (existing 4 tests, plus new tests only where they can run without Firebase).
- Chrome against emulators at 412 px and 320 px, and 2x text, for: login, register, list (all filters and an empty filter), History, empty state, form (clean, with errors, with photo and location recorded), details (each status), delete and discard dialogs. Compare to the baseline screenshots in the audit.
- Template scan: no banned patterns in new or changed code.
- Behavior unchanged: submit, edit, delete, simulate, History work as before (browser regression pass).

## Not verifiable by me
- Real phone look and feel, TalkBack/VoiceOver announcements (the `Semantics` changes are only checked through the browser accessibility tree), and live Firebase behavior.
- Whether Airen likes the look. I'll show screenshots at the end of each phase.

## Phases
1. Theme and colors (`main.dart`, status and delete colors, contrast values) plus list cards, empty states, header.
2. Details page and form changes, red dialogs, semantics.
3. Verification at all sizes, README (UI notes, tested-where), handoff. New APK and release only if Airen asks.

## Needs Airen
1. Approve this spec (or edit the decisions above).
2. Later: test the look and TalkBack on the phone, and tell me when to push and release.
