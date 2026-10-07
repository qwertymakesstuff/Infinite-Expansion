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
//   4. iw7-mod only starts while Steam runs with an account signed in: it
//      looks for Steam's window ("Steam") and otherwise shows "Steam must be
//      running to play this game!" (iw7-mod steam_proxy.cpp). So Steam is
//      started if needed, and the launcher waits until Steam's window is there
//      and Steam reports a signed-in account
//      (HKCU\Software\Valve\Steam\ActiveProcess\ActiveUser is not 0).
//   5. It starts iw7-mod.exe from the game folder, passing on any arguments
//      the launcher was given (a shortcut can add "+set ..." commands).
// The game opens on its main menu. iw7-mod's -zombies / -cpMode flags would
// not open Zombies: they only work on a dedicated server (iw7-mod
// dedicated.cpp returns before reading them in the client).
// The mod needs nothing more: iw7-mod loads it from <game>\iw7-mod\ by itself.

using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
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
