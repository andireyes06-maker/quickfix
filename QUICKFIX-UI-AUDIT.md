# QuickFix UI audit

Date: 2026-10-22. Read-only; no code changed. Build audited: `main` at `c5ac30f` (emulator web build, Chrome, 412 px wide, seeded data in every status). Frameworks used: WCAG 2.1 AA checklist and a design critique (design plugin skills). Colors measured with the contrast checker. Not covered: a real phone, screen readers, dark mode.

## Overall impression
Clean and consistent: one indigo accent, generous spacing, clear flow, and the core screens fit a phone. The main opportunities are (1) a few real accessibility failures, (2) the most important actions look optional or the most dangerous look harmless, and (3) screens that show less than a student needs when tracking reports.

## A. Accessibility (WCAG 2.1 AA)
| # | Finding | Measured | Severity | Fix |
|---|---------|----------|----------|-----|
| A1 | "Under Review" orange text fails contrast (my phase 2 choice) | #EF6C00 on card #F7F2FA = 2.79:1 (needs 4.5) | Critical | Use a darker orange, for example brown-orange #B45309 or Colors.deepOrange.shade900; re-measure |
| A2 | "Delete report" red text fails contrast | #F44336 on #F5F6F8 = 3.41:1 | Major | Use Colors.red.shade800 (#C62828, 5.2:1) |
| A3 | Photo has no text alternative for screen readers | Image.memory without semanticLabel (details, edit preview) | Major (1.1.1) | Add semanticLabel "Photo of the reported problem" |
| A4 | Unchecked progress circles are low contrast | #9E9E9E on #F5F6F8 = 2.48:1 (non-text needs 3:1) | Minor (1.4.11) | Use Colors.grey.shade600 |
| A5 | Required fields and required photo/location not marked | form shows no "required" cue until submit | Major (3.3.2) | Mark required in labels or section headings |
| A6 | Error text is not announced to screen readers when it appears | plain Text in the form and login | Minor (3.3.1) | Wrap errors in Semantics(liveRegion: true) |
| A7 | Not yet verified with TalkBack or VoiceOver | n/a | Unknown | Phone test by Airen |
Passing: white on indigo 6.87:1; blue 5.21:1; green 4.65:1 (thin margin); grey 5.61:1; error red 5.2:1; icon buttons have tooltips; layouts survive 320 px and 2x text.

## B. Usability and hierarchy
| # | Finding | Severity | Fix |
|---|---------|----------|-----|
| B1 | Photo and location are required but styled as optional (small outlined and text buttons, no required cue); their errors appear only above the Submit button, possibly below the fold on short phones | Major | Larger buttons, a "required" cue, show the photo/location error next to its section |
| B2 | Destructive actions look harmless: Delete confirmation button is the same indigo as every primary action; "Delete report" is a faint text button | Major | Red-background ElevatedButton for Delete in the dialog (uses Colors on the widget, as the template allows) |
| B3 | Status is not prominent: the status chip looks the same as the category chip, and the progress list does not mark the current step | Major | Status chip filled with the status color (white text, check contrast) and the current step bold |
| B4 | List cards show too little: same wrench icon for every report, no date, no category, no photo thumbnail | Moderate | Category-based icon and color, date line ("Submitted Oct 22"); no thumbnails (they would need a photo read per row) |
| B5 | Empty state ignores the filter ("No reports here yet" even when a filter hides reports) | Minor | Say "No Under Review reports" for a filtered view |
| B6 | Helper text is developer-style ("On desktop browsers, Take photo may open a file picker"; "It is made smaller automatically") | Minor | Short, student-facing text |
| B7 | Details show raw coordinates and four timestamp lines with equal weight | Minor | Smaller or hidden coordinates; "Submitted" and "Last update" as a quieter caption |
| B8 | Header repeats a long simulation sentence on My Reports | Minor | Keep the label but shorter or as a small note beside the demo button only |
| B9 | Sign out has no confirmation and the app never shows who is signed in | Minor | Show the user's name in the list header |
| B10 | Login and form content jumps when validation errors appear | Minor | Accept; low value |

## C. Visual consistency
| # | Finding | Severity | Fix |
|---|---------|----------|-----|
| C1 | Material 3 default purple leaks into some parts while others are explicit indigo: card tint lavender, dialog lavender, text buttons purple (#6750A4), outlined buttons and chips purple-grey, AppBar and filled buttons indigo | Moderate | Set component themes in `main.dart` (cardTheme, dialogTheme, textButtonTheme, outlinedButtonTheme, chipTheme) to white surfaces and indigo; no ColorScheme.fromSeed, no Theme.of |
| C2 | Heading styles are hard-coded per screen (28, 26, 18) but consistent in practice | OK | None |
| C3 | App icon is still the generated Flutter icon | Minor | Optional; needs icon assets (a new dev package or manual PNGs) |

## What works well
- One clear primary action per screen (New report, Submit, Edit).
- Good empty state and loading states; photo failure has a Retry.
- Status always has text, not only color.
- Demo status simulation is clearly separated in its own labeled card.
- Form fits a 412x915 screen without scrolling.

## Constraints on any fix
Flutter template: StatefulWidget, setState, maps, standard widgets, no new widget classes, no Theme.of, no ColorScheme.fromSeed, no new packages, braces on callbacks, dialogs with TextButton cancel and ElevatedButton action. Colors set directly on widgets.
