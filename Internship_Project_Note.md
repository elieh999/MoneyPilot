# Internship Project Note — MoneyPilot 1.3.0

## Project objective

The task was to improve and finalize MoneyPilot as a publishable personal
finance desktop and mobile application. The requested work focused on complete
multilingual behavior, a reliable financial assistant, broader feature
testing, new calendar and appearance features, secure user-controlled data
deletion, and a clean ready-to-run Windows delivery.

## Requested improvements

The application previously supported English, French, and Arabic selection,
but several cards and controls remained in English after French or Arabic was
selected. The settings screenshots specifically showed untranslated account,
Coach, privacy, safety, and accessibility content. The request also included:

- Test and improve the financial Coach.
- Test the complete application rather than only individual screens.
- Add a calendar showing how much was spent each day and which transactions
  occurred.
- Add more visual themes, including cyan, dark green, and optional glow.
- Let users wipe financial data and permanently delete their account.
- Clean the published folder and remove temporary or generated-looking names.
- Deliver the completed project as a ready-to-run ZIP.

## Implementation completed

### Complete localization

A shared runtime translation layer was introduced so reusable text widgets,
page headers, cards, metrics, empty states, buttons, dialogs, status pills, and
dynamic messages follow the selected locale. The French and Arabic catalogs
contain matching coverage for more than 275 common interface phrases, with an
additional catalog for longer explanatory content.

Localization now covers:

- Navigation and page titles.
- Account and transaction editors.
- Budgets, bills, goals, reports, and purchase checks.
- Settings, privacy, Coach style, safety buffer, and data controls.
- Validation and authentication errors.
- Default financial category names.
- Dynamic labels such as due dates, goal dates, record counts, approval
  prompts, and safe-to-spend values.
- The sign-in and account-creation screen.

Arabic uses right-to-left layout and the bundled Noto Sans Arabic font. A
language selector is available before sign-in as well as in Settings.

### Spending calendar

A new Calendar destination was added to desktop and mobile navigation. It
groups real transactions by day and shows:

- Expenses and income for each calendar day.
- Transactions and categories for the selected day.
- Total monthly income and expenses.
- The number of no-spend days observed so far.
- The highest-spending day of the month.
- Previous- and next-month navigation.

The calendar has a compact mobile mode. On narrow screens, colored indicators
replace long currency labels inside day cells, while the selected-day panel
continues to show exact values.

### Appearance system

The original System, Light, and Dark appearance choices remain available. A
new independent color-palette selector adds:

- Ocean Blue
- Electric Cyan
- Deep Forest
- Royal Violet
- Warm Sunset

An optional Glow Effects switch adds a soft palette-colored shadow to cards
and primary controls. Palette and glow choices are stored in the local user
profile and work with light, dark, and system modes.

### Data safety and account controls

The existing permanent account-deletion workflow was retained and localized.
It requires the current password and removes both the local profile and its
financial storage.

Financial-data wiping was strengthened with a destructive-action dialog. The
user must type `WIPE` before the confirmation button is enabled. This removes
accounts, transactions, budgets, bills, goals, and Coach history while keeping
the login, categories, language, theme, and privacy preferences.

### Financial Coach

The Local Coach remains private and works without an external API key. It uses
only the signed-in profile's recorded accounts, transactions, budgets, bills,
goals, and safety preferences. It reports missing information instead of
inventing balances.

The expanded multilingual regression checks cover:

- Greetings and general capabilities.
- Safe-to-spend explanations.
- Income and cash flow.
- Category spending.
- Account balances and net worth.
- Upcoming bills.
- Savings goals.
- Purchase affordability.
- Budget proposals requiring explicit approval.
- Arabic-Indic number input.

## Debugging performed

Testing found and corrected two important edge cases:

1. A financial-wipe confirmation field was being disposed before the dialog's
   exit animation completed. The dialog was changed to use safe state-managed
   input without a prematurely disposed controller.
2. Arabic text caused a small overflow in calendar cells at 390-pixel mobile
   width. The cells were redesigned with compact income and expense indicators.

The earlier Coach blank-screen problem remains covered by a regression test at
the exact 883 × 1014 dimensions from the original screenshot.

## Verification approach

The project is verified with:

- Dart formatting and static analysis.
- Flutter unit, controller, authentication, accessibility, widget, golden,
  localization, Calendar, Coach, theme, and data-safety tests.
- Python financial-core and API tests.
- Ruff lint and formatting checks.
- Windows packaged-executable smoke testing.
- A normal interactive launch check.
- A second smoke test from a freshly extracted copy of the final ZIP.
- Archive inspection to exclude secrets, caches, generated build folders, and
  smoke-test logs.

## Publishable delivery structure

The final release uses a clean folder named `MoneyPilot-1.3.0` with:

- `MoneyPilot/` — the self-contained Windows application and executable.
- `Source/` — the application and service source code.
- `Documentation/` — release notes, verification, and this internship note.
- `Launch MoneyPilot.cmd` — a double-click launcher.
- `MoneyPilot.lnk` — a Windows shortcut.
- `SHA256SUMS.txt` — file-integrity hashes.

The release archive is named `MoneyPilot-1.3.0-Windows.zip`.
