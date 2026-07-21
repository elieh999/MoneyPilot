# Roadmap

MoneyPilot is usable as a local personal finance app, but several parts still
need work before it should be treated as a synchronized production service.

## Next

- Connect the Flutter client to FastAPI authentication and financial endpoints.
- Replace the local snapshot with a versioned database and migration support.
- Add an offline change queue, server pull cursor, and visible conflict handling.
- Keep the client and server money models aligned through shared test data.
- Add session management, email verification, and complete password recovery to
  the server backed account flow.
- Encrypt sensitive local financial storage and use platform protected secret
  storage.
- Expand integration tests around persistence failures, synchronization, and
  account deletion.

## Later

- CSV import and export with preview and undo
- Recurring transaction detection and reminders
- Historical currency conversion
- Encrypted backup and restore
- Optional hosted coach providers with explicit consent
- Signed desktop and mobile releases

Issues and pull requests should stay focused on one area at a time. A feature is
listed here as an idea, not as a promise that it already works.
