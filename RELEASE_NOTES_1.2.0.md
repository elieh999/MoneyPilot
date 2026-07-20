# MoneyPilot AI 1.2.0

## Coach repair

- Fixed the release-layout defect that could collapse the Coach conversation
  panel into a blank card at narrower desktop widths.
- The typed message, prompt chips, user message, thinking state, assistant reply,
  and approval card now share a bounded conversation layout.
- The view scrolls again after the assistant finishes replying, not only when the
  user sends a message.
- Added a visual regression test at the reported 883 x 1014 window size.
- The packaged build uses the stable JavaScript CanvasKit renderer instead of the
  newer WebAssembly renderer used by the previous package.

## Languages

- Added English, French, and Arabic under Settings > Appearance & language.
- Arabic activates right-to-left application layout.
- Navigation, Settings language controls, and the complete Coach interface are
  localized.
- The Local Coach understands and answers typed English, French, and Arabic
  questions. Arabic-Indic digits such as ٩٠٠ are recognized as amounts.
- French and Arabic cover greetings, capabilities, affordability, safe to spend,
  income, expenses, balances, bills, goals, and approval-required budget drafts.
- Bundled open-licensed Noto Sans Arabic for reliable Arabic rendering without an
  internet connection.

## Verification

- Dart static analysis: no issues.
- Flutter tests: 25 passed, including multilingual Coach replies, RTL layout, the
  reported screen size, and a rendered Arabic reply golden.
- Python API and financial-core tests: 34 passed.
- Windows package and extracted ZIP launch smoke tests: passed.
