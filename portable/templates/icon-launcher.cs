// Windows icon entry point only. The pet and all animation logic remain in R.
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class PortableCatLauncher
{
    [STAThread]
    private static int Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        try
        {
            string helper = Path.Combine(root, "scripts", "portable.cmd");
            string runner = Path.Combine(root, "runtime", "R", "bin", "x64", "Rscript.exe");
            if (!File.Exists(helper) || !File.Exists(runner))
                throw new FileNotFoundException("Required portable files are missing. Extract the entire ZIP before starting @PET@.");

            ProcessStartInfo start = new ProcessStartInfo();
            start.FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "cmd.exe");
            // Expand the path once through an environment variable, keeping spaces,
            // Unicode and shell characters in the extracted folder name quoted.
            start.EnvironmentVariables["PET_ICON_HELPER"] = helper;
            start.Arguments = "/d /s /c \"\"%PET_ICON_HELPER%\" start\"";
            start.WorkingDirectory = root;
            start.UseShellExecute = false;
            start.CreateNoWindow = true;
            start.WindowStyle = ProcessWindowStyle.Hidden;
            using (Process process = Process.Start(start))
            {
                if (process == null || !process.WaitForExit(60000))
                    throw new InvalidOperationException("Startup did not finish within 60 seconds.");
                if (process.ExitCode != 0)
                    throw new InvalidOperationException("The portable launcher reported a startup error.");
            }
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message + "\r\n\r\nRun Check @PET@.cmd in the extracted folder for diagnostics.",
                "@PET@ Portable", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
