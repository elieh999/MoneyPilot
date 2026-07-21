# Windows launcher

`MoneyPilotLauncher.cs` builds the small `MoneyPilot.exe` placed at the project
root. It starts `MoneyPilot Runtime/MoneyPilotApp.exe` with the correct working
directory and shows a clear error if the support folder is missing.

The GitHub Actions Windows job compiles the launcher with the application icon,
builds the Flutter runtime, smoke launches the packaged layout, and publishes
the complete folder as a workflow artifact.
