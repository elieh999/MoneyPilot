using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class MoneyPilotLauncher
{
    [STAThread]
    private static void Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string runtime = Path.Combine(root, "MoneyPilot Runtime");
        string application = Path.Combine(runtime, "MoneyPilot.exe");

        if (!File.Exists(application))
        {
            MessageBox.Show(
                "MoneyPilot could not find its support files.\n\n" +
                "Keep MoneyPilot.exe and the MoneyPilot Runtime folder together, then try again.",
                "MoneyPilot",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return;
        }

        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = application,
                WorkingDirectory = runtime,
                UseShellExecute = true
            });
        }
        catch (Exception error)
        {
            MessageBox.Show(
                "MoneyPilot could not start.\n\n" + error.Message,
                "MoneyPilot",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }
}
