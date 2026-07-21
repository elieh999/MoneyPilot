# Local Coach

MoneyPilot includes a local financial coach in the Flutter client. It works
without an internet connection or API key and answers from the active profile's
accounts, transactions, budgets, bills, goals, and safety preferences.

The current coach is rule based. It recognizes common questions in English,
French, and Arabic, then calculates a response from the local data. When a value
is missing, it asks for the missing information instead of inventing a balance.

## Supported questions

The coach can explain:

- account balances and net worth
- income and spending totals
- category spending
- upcoming bills
- savings goals
- safe to spend estimates
- purchase affordability

It can also prepare a budget suggestion. Suggestions are drafts and require the
user to approve them before anything is saved.

## API provider interface

The FastAPI service has a separate `AIProvider` interface. Its default provider
is also rule based and uses a short list of approved tools. No hosted model is
configured in this repository.

API tools can read a financial summary, calculate safe to spend, list upcoming
bills, or prepare a budget proposal. The provider receives no database handle
and cannot execute SQL or shell commands. The API checks ownership again before
running a tool.

## Privacy and limitations

The Flutter coach stays on the device. A future hosted provider would require a
separate adapter, explicit configuration, and a clear consent flow before any
financial context is sent outside the device.

Coach replies are educational explanations based on the records available in
MoneyPilot. They are not financial, tax, investment, or legal advice.
