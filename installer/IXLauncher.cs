// Infinite Expansion - launcher, "Infinite Expansion.exe" in the game folder.
//
// The setup compiles this file on the player's own PC with the C# compiler that
// comes with Windows (.NET Framework 4, IXSetup.Core.ps1), so the download
// carries no program file. That compiler only knows C# 5, so this file uses
// nothing newer (tools/tests/test_installer.py compiles it with
// /langversion:5).
//
// What it does, from the folder it sits in (the game folder):
//   1. iw7-mod.exe must be there (the setup puts it there).
//   2. Infinite Expansion should be installed in <game>\iw7-mod\; if it is not,
//      it asks whether to start iw7-mod anyway.
//   3. If the game already runs, it says so and stops.
//   4. Updates (README "Updates"): it asks GitHub for the project's newest
//      release (5 seconds at most). When that is newer than the installed
//      version, it starts the setup copy the setup keeps in
//      %LOCALAPPDATA%\InfiniteExpansion\Setup with -Update -Play and ends: the
//      setup downloads and checks the release, its own setup installs it, and
//      then starts the game through a new launcher, with --ix-no-update. No
//      answer from GitHub, or nothing newer: on to step 5. AutoUpdate=0 in
//      %LOCALAPPDATA%\InfiniteExpansion\settings.ini (the setup's AUTO-UPDATE
//      switch) or --ix-no-update skips this step. While the setup window is
//      open (it may be installing), the launcher leaves the game to it.
//   5. iw7-mod only starts while Steam runs with an account signed in: it
//      looks for Steam's window ("Steam") and otherwise shows "Steam must be
//      running to play this game!" (iw7-mod steam_proxy.cpp). So Steam is
//      started if needed, and the launcher waits until Steam's window is there
//      and Steam reports a signed-in account
//      (HKCU\Software\Valve\Steam\ActiveProcess\ActiveUser is not 0).
//   6. It starts iw7-mod.exe from the game folder, passing on any arguments
//      the launcher was given (a shortcut can add "+set ..." commands).
// The game opens on its main menu. iw7-mod's -zombies / -cpMode flags would
// not open Zombies: they only work on a dedicated server (iw7-mod
// dedicated.cpp returns before reading them in the client).
// The mod needs nothing more: iw7-mod loads it from <game>\iw7-mod\ by itself.

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using Microsoft.Win32;

[assembly: AssemblyTitle("Infinite Expansion")]
[assembly: AssemblyProduct("Infinite Expansion")]
[assembly: AssemblyDescription("Starts Call of Duty: Infinite Warfare with the iw7-mod client and Infinite Expansion")]
[assembly: AssemblyVersion("0.0.0.0")]

namespace InfiniteExpansion
{
    public static class Launcher
    {
        private const string Title = "Infinite Expansion";
        private const string ClientExe = "iw7-mod.exe";
        private const string ModFile = @"iw7-mod\custom_scripts\cp\ix_main.gsc";
        private const string VersionFile = @"iw7-mod\custom_scripts\ix\core\bootstrap.gsc";
        private const string ReleaseApi = "https://api.github.com/repos/qwertymakesstuff/Infinite-Expansion/releases/latest";
        private const string NoUpdateFlag = "--ix-no-update";
        private const string SetupTitle = "Infinite Expansion Setup";
        private const int UpdateCheckMilliseconds = 5000;
        private const int SteamWaitSeconds = 300;
        private const int SteamSettleMilliseconds = 3000;
        private const uint IconError = 0x10;
        private const uint IconQuestion = 0x20;
        private const uint IconWarning = 0x30;
        private const uint ButtonsYesNo = 0x4;
        private const int AnswerYes = 6;

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int MessageBoxW(IntPtr owner, string text, string caption, uint type);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr FindWindowW(string className, string windowName);

        [STAThread]
        public static int Main(string[] args)
        {
            bool first;

            // A second double-click while the first one still waits for Steam.
            using (Mutex once = new Mutex(true, "InfiniteExpansionLauncher", out first))
            {
                if (!first)
                {
                    return 0;
                }

                return Run(args);
            }
        }

        private static int Run(string[] args)
        {
            string gameDir = AppDomain.CurrentDomain.BaseDirectory;
            string client = Path.Combine(gameDir, ClientExe);
            // The setup passes --ix-no-update when it starts the game; iw7-mod never sees it.
            string[] gameArgs = WithoutFlag(args, NoUpdateFlag);
            bool checkUpdates = gameArgs.Length == args.Length;
            args = gameArgs;

            if (!File.Exists(client))
            {
                Show(ClientExe + " is not in this folder:\n" + gameDir + "\n\nRun Infinite Expansion Setup, which puts it there.", IconError);
                return 1;
            }

            if (!File.Exists(Path.Combine(gameDir, ModFile)))
            {
                string question = "Infinite Expansion is not installed in this game folder. Run Infinite Expansion Setup to install it.\n\nStart iw7-mod without it?";

                if (MessageBoxW(IntPtr.Zero, question, Title, IconQuestion | ButtonsYesNo) != AnswerYes)
                {
                    return 1;
                }
            }

            if (IsRunning("iw7-mod") || IsRunning("iw7_ship"))
            {
                Show("Infinite Warfare is already running.", IconWarning);
                return 0;
            }

            if (checkUpdates)
            {
                if (FindWindowW(null, SetupTitle) != IntPtr.Zero)
                {
                    Show("Infinite Expansion Setup is open, and may be installing an update. Start the game there with PLAY, or close the setup first.", IconWarning);
                    return 0;
                }

                if (StartUpdate(gameDir, args))
                {
                    return 0;
                }
            }

            if (!WaitForSteam())
            {
                Show("Steam is not running, or no account is signed in.\n\nStart Steam, sign in, then open Infinite Expansion again.", IconError);
                return 1;
            }

            ProcessStartInfo start = new ProcessStartInfo(client, BuildArguments(args));
            start.WorkingDirectory = gameDir;
            start.UseShellExecute = true;
            Process.Start(start);
            return 0;
        }

        // The arguments as one command line, each quoted the way Windows programs
        // split them again (CommandLineToArgvW rules).
        public static string BuildArguments(string[] args)
        {
            StringBuilder line = new StringBuilder();

            foreach (string arg in args)
            {
                if (line.Length > 0)
                {
                    line.Append(' ');
                }

                line.Append(Quote(arg));
            }

            return line.ToString();
        }

        public static string Quote(string arg)
        {
            if (arg.Length > 0 && arg.IndexOfAny(new char[] { ' ', '\t', '\n', '\v', '"' }) < 0)
            {
                return arg;
            }

            StringBuilder quoted = new StringBuilder("\"");
            int backslashes = 0;

            foreach (char c in arg)
            {
                if (c == '\\')
                {
                    backslashes++;
                    continue;
                }

                // Backslashes before a quote are doubled, and the quote escaped.
                if (c == '"')
                {
                    quoted.Append('\\', backslashes * 2 + 1);
                }
                else
                {
                    quoted.Append('\\', backslashes);
                }

                backslashes = 0;
                quoted.Append(c);
            }

            // Backslashes before the closing quote are doubled too.
            quoted.Append('\\', backslashes * 2);
            quoted.Append('"');
            return quoted.ToString();
        }

        private static bool IsRunning(string name)
        {
            return Process.GetProcessesByName(name).Length > 0;
        }

        // When updates are on and GitHub has a release newer than the installed
        // version, starts the setup copy to install it (the game follows) and
        // returns true. Anything in the way: false, and the game starts as it is.
        private static bool StartUpdate(string gameDir, string[] args)
        {
            try
            {
                string dataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "InfiniteExpansion");
                string setup = Path.Combine(dataDir, @"Setup\installer\IXSetup.ps1");
                string settings = Path.Combine(dataDir, "settings.ini");
                string installed = VersionInScript(ReadText(Path.Combine(gameDir, VersionFile)));

                if (!File.Exists(setup) || installed == null || !AutoUpdateOn(ReadText(settings)))
                {
                    return false;
                }

                string latest = LatestVersion();

                if (latest == null || CompareVersions(latest, installed) <= 0)
                {
                    return false;
                }

                string powerShell = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe");
                ProcessStartInfo start = new ProcessStartInfo(File.Exists(powerShell) ? powerShell : "powershell.exe", UpdateArguments(setup, gameDir, args));
                start.UseShellExecute = false;
                start.CreateNoWindow = true;
                start.WorkingDirectory = gameDir;
                Process.Start(start);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        // The version of the project's newest GitHub release, or null.
        private static string LatestVersion()
        {
            // TLS 1.2, which GitHub requires; .NET Framework 4 may not offer it by default.
            ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072;
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(ReleaseApi);
            request.UserAgent = "InfiniteExpansionLauncher";
            request.Accept = "application/vnd.github+json";
            request.Timeout = UpdateCheckMilliseconds;
            request.ReadWriteTimeout = UpdateCheckMilliseconds;

            using (WebResponse response = request.GetResponse())
            using (StreamReader reader = new StreamReader(response.GetResponseStream(), Encoding.UTF8))
            {
                return ReleaseVersion(reader.ReadToEnd());
            }
        }

        private static string ReadText(string path)
        {
            return File.Exists(path) ? File.ReadAllText(path) : null;
        }

        // PowerShell's arguments for the setup copy's update: the game's own
        // arguments travel as Base64, which needs no quoting.
        public static string UpdateArguments(string setup, string gameDir, string[] gameArgs)
        {
            string line = "-NoProfile -ExecutionPolicy Bypass -STA -File " + Quote(setup) +
                " -Update -Play -GameDir " + Quote(gameDir.TrimEnd('\\', '/'));

            if (gameArgs.Length > 0)
            {
                line += " -PlayArgs " + Convert.ToBase64String(Encoding.UTF8.GetBytes(BuildArguments(gameArgs)));
            }

            return line;
        }

        public static string[] WithoutFlag(string[] args, string flag)
        {
            List<string> kept = new List<string>();

            foreach (string arg in args)
            {
                if (!string.Equals(arg, flag, StringComparison.OrdinalIgnoreCase))
                {
                    kept.Add(arg);
                }
            }

            return kept.ToArray();
        }

        // "v0.3.2" or "0.3.2" as "0.3.2"; null unless it is one to four numbers
        // (the setup's ConvertTo-IXVersion).
        public static string ParseVersion(string text)
        {
            if (text == null)
            {
                return null;
            }

            string value = text.Trim();

            if (value.StartsWith("v", StringComparison.OrdinalIgnoreCase))
            {
                value = value.Substring(1);
            }

            return Regex.IsMatch(value, @"^\d{1,6}(\.\d{1,6}){0,3}$") ? value : null;
        }

        // 1, 0 or -1 as version a is newer than, the same as or older than b;
        // missing numbers count as 0 (the setup's Compare-IXVersion).
        public static int CompareVersions(string a, string b)
        {
            string[] left = (ParseVersion(a) ?? "0").Split('.');
            string[] right = (ParseVersion(b) ?? "0").Split('.');

            for (int i = 0; i < 4; i++)
            {
                int x = i < left.Length ? int.Parse(left[i], CultureInfo.InvariantCulture) : 0;
                int y = i < right.Length ? int.Parse(right[i], CultureInfo.InvariantCulture) : 0;

                if (x != y)
                {
                    return x > y ? 1 : -1;
                }
            }

            return 0;
        }

        // The version named by "tag_name" in GitHub's release JSON, or null.
        public static string ReleaseVersion(string json)
        {
            Match match = Regex.Match(json ?? "", "\"tag_name\"\\s*:\\s*\"([^\"]*)\"");
            return match.Success ? ParseVersion(match.Groups[1].Value) : null;
        }

        // The version a bootstrap.gsc sets (level.ix.version = "0.3.2";), or null.
        public static string VersionInScript(string text)
        {
            Match match = Regex.Match(text ?? "", "level\\.ix\\.version\\s*=\\s*\"([^\"]+)\"");
            return match.Success ? ParseVersion(match.Groups[1].Value) : null;
        }

        // settings.ini, which the setup writes: "AutoUpdate=0" turns updates off.
        public static bool AutoUpdateOn(string settings)
        {
            return settings == null || !Regex.IsMatch(settings, @"^\s*AutoUpdate\s*=\s*0\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase);
        }

        // Starts Steam when it is not running, then waits until it is ready.
        private static bool WaitForSteam()
        {
            if (SteamReady())
            {
                return true;
            }

            if (!IsRunning("steam"))
            {
                try
                {
                    ProcessStartInfo steam = new ProcessStartInfo("steam://open/main");
                    steam.UseShellExecute = true;
                    Process.Start(steam);
                }
                catch (Exception)
                {
                    return false;
                }
            }

            // Steam shows its own window meanwhile: an update, or the sign-in.
            Stopwatch waited = Stopwatch.StartNew();

            while (waited.Elapsed.TotalSeconds < SteamWaitSeconds)
            {
                Thread.Sleep(1000);

                if (SteamReady())
                {
                    // Steam reports the account a moment before games can use it.
                    Thread.Sleep(SteamSettleMilliseconds);
                    return true;
                }
            }

            return false;
        }

        // What iw7-mod needs: Steam's window, and a signed-in account.
        private static bool SteamReady()
        {
            if (!IsRunning("steam") || FindWindowW(null, "Steam") == IntPtr.Zero)
            {
                return false;
            }

            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam\ActiveProcess"))
            {
                if (key == null)
                {
                    return false;
                }

                object user = key.GetValue("ActiveUser");
                return user is int && (int)user != 0;
            }
        }

        private static void Show(string text, uint icon)
        {
            MessageBoxW(IntPtr.Zero, text, Title, icon);
        }
    }
}
