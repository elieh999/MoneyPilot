# Roadmap

MoneyPilot is usable as a local personal finance app, but several parts still
need work before it should be treated as a synchronized production service.

## Next

- Extend the existing API session connection to financial endpoints.
- Replace the local snapshot with a versioned database and migration support.
- Add an offline change queue, server pull cursor, and visible conflict handling.
- Keep the client and server money models aligned through shared test data.
- Add session management, email verification, and complete password recovery to
  the server backed account flow.
- Move local encryption keys into platform protected secret storage.
- Expand integration tests around persistence failures, synchronization, and
  account deletion.

## Later

- CSV file picking, import preview, and undo on top of the current copy/paste flow
- Reminders for the existing recurring transaction insights
- Historical currency conversion
- Encrypted backup and restore
- Optional hosted coach providers with explicit consent
- Signed desktop and mobile releases

Issues and pull requests should stay focused on one area at a time. A feature is
listed here as an idea, not as a promise that it already works.
