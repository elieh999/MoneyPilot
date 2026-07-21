# Contributing

Thanks for taking an interest in MoneyPilot. Small, focused improvements are the
easiest to review.

## Before opening a change

1. Search the existing issues and pull requests.
2. Open an issue before starting a large feature or data model change.
3. Do not include real financial records, credentials, `.env` files, databases,
   generated build output, or personal paths.

## Development

Follow [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for setup and test commands.
Keep Flutter changes in `apps/money_pilot`, API changes in `services/api`, and
shared calculation changes in `packages`.

## Pull requests

- Keep each pull request limited to one clear change.
- Explain the behavior before and after the change.
- Add or update tests when behavior changes.
- Run `./scripts/check.ps1` before requesting review.
- Update the committed OpenAPI schema when API routes or schemas change.
- Include screenshots for visible interface changes.

Commit messages should describe the actual change, such as `Fix Arabic calendar
cell overflow` or `Add transaction date filter`.
