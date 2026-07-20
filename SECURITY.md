# Security policy

## Supported version

Security fixes are applied to the current `1.3.x` source line. MoneyPilot is an
MVP foundation and should not be treated as a hosted banking service without an
independent production security review.

## Reporting a vulnerability

Use GitHub's private vulnerability-reporting or Security Advisory feature for
the repository. Do not open a public issue containing exploit details, tokens,
personal data, or financial records.

Include the affected component, reproduction steps, impact, and the smallest
safe proof of concept. Never include a real MoneyPilot data export or a user's
credentials.

## Sensitive configuration

- Copy `.env.example` to `.env` and replace every `CHANGE_ME` value locally.
- Never commit `.env`, signing keys, local databases, exports, recovery codes,
  account snapshots, or captured API tokens.
- Production API startup rejects missing, short, or obvious placeholder JWT
  secrets.
- The offline desktop application stores local profile data on the device; use
  operating-system disk encryption and a protected user account.
