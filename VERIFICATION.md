# Verification record

Verification date: 2026-07-20. Host: Windows, PowerShell, Python 3.12, portable
Flutter SDK. All commands were run against this exact repository snapshot before
packaging.

## Passed gates

| Area | Result |
|---|---|
| Python tests | 34 passed; one upstream Starlette `TestClient` deprecation warning. |
| Python formatting | Ruff reports all 33 Python files already formatted. |
| Python lint | Ruff reports no issues. |
| Database migrations | `alembic check` reports no new upgrade operations. |
| API launch smoke | Uvicorn started and stopped cleanly; readiness and OpenAPI returned HTTP 200. |
| API workflow smoke | Development seed, login, dashboard summary, and safe-to-spend completed against the SQLite fallback. |
| Flutter dependencies | `flutter pub get` completed successfully with a locked dependency graph. |
| Dart formatting | 44 files checked and formatted. |
| Flutter analysis | No issues found. |
| Flutter tests | 36 passed: authentication/recovery, secret handling, profile isolation, empty onboarding, full phrase-catalog parity, English/French/Arabic Coach intent coverage, RTL layout, calendar calculations, narrow Arabic calendar rendering, palette/glow persistence, secure wipe confirmation, reported-size visual regression, purchase-safe action approval, shared financial vectors, controller invariants, responsive navigation, and semantics. |
| Documentation | Local Markdown links, workflow YAML, Compose YAML structure, and PowerShell syntax validated. |
| Secret scan | No committed credential/private-key pattern found; `.env` and local databases are excluded. |
| UI previews | Desktop and mobile PNGs rendered from the tested widget tree and visually inspected. |
| Packaged executable smoke | Exit code 0 with `FLUTTER_RENDERED`, `CAPTURE_OPAQUE_RATIO 1.0000`, and `SMOKE_TEST_PASSED`. |
| Normal Windows launch | `MoneyPilot.exe` opened four scoped runtime processes; the main window remained responsive until the controlled shutdown. |
| Extracted archive smoke | A fresh extraction of `MoneyPilot-1.3.0-Windows.zip` returned exit code 0 with the same complete-render markers. |
| Archive audit | Required executable, launcher, shortcut, source, internship note, and checksums were present; no secrets, caches, generated ephemeral folders, or smoke logs were included. |

## Smoke values

The zero-Docker API smoke used the development seed and returned monthly income
`250000`, expenses `42500`, raw safe-to-spend `127500`, and daily allowance
`4250`, all in integer USD minor units.

## Environment-limited checks

- Docker was not installed, so the Compose topology was statically parsed but
  not built or launched.
- Visual Studio C++ and Android/iOS toolchains were not installed. A portable
  Windows desktop executable was therefore produced with Electron hosting the
  release Flutter web runtime; no signed installer, APK, IPA, or store submission
  was produced.
- PostgreSQL parity, load testing, two-device sync chaos, external AI providers,
  and store accessibility audits remain later-milestone gates.

## Important prototype limitations

The Flutter client uses local accounts and is not yet wired to FastAPI cloud
authentication or synchronization. Financial snapshots are isolated per local
profile but are not database-level encrypted. The private Local Coach is a
rule-based conversational engine, not a cloud large-language-model service; it
uses only entered records and creates approval-required typed budget drafts.
Account and transaction deletion remain local device operations.
