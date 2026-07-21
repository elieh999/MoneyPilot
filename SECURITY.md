# Security policy

## Supported version

Security fixes are applied to the latest commit on the default branch. MoneyPilot
is an early project and should not be treated as a hosted banking service.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting or Security Advisory feature. Do
not open a public issue containing exploit details, tokens, personal data, or
financial records.

Include the affected component, reproduction steps, impact, and the smallest
safe proof of concept. Never include a real data export or user credentials.

## Sensitive configuration

- Copy `.env.example` to `.env` and replace placeholder values locally.
- Never commit `.env`, signing keys, local databases, exports, recovery codes,
  account snapshots, or captured API tokens.
- Production API startup rejects missing, short, or obvious placeholder JWT
  secrets.
- The desktop application stores profile data on the device. The current
  financial snapshot is not database level encrypted, so use operating system
  disk encryption and a protected user account.
- Hosted deployment, backup, monitoring, and incident response are not provided
  by this repository.
