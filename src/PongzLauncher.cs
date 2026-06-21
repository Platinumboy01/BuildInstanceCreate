// ============================================================
//  Pongz BlueStacks Launcher - simple GUI front-end.
//  Each button just runs one of the existing .ps1 scripts that
//  live next to this .exe, so all logic stays in those scripts.
//
//  Built with the in-box C# compiler (csc.exe) - no installs.
//  See build-launcher.ps1 / Build-Launcher.bat to (re)compile.
// ============================================================
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

public class PongzLauncher : Form
{
    // Folder the .exe is run from = the toolkit folder (portable).
    static readonly string BaseDir = AppDomain.CurrentDomain.BaseDirectory;

    [STAThread]
    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new PongzLauncher());
    }

    public PongzLauncher()
    {
        Text = "Pongz  -  BlueStacks Test Kit";
        ClientSize = new Size(360, 648);
        FormBorderStyle = FormBorderStyle.FixedSingle;   // not resizable
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(33, 37, 43);
        Font = new Font("Segoe UI", 9.75f);

        // Title-bar / taskbar icon (same app.ico embedded in the .exe).
        try
        {
            string icoPath = Path.Combine(BaseDir, "app.ico");
            if (File.Exists(icoPath)) Icon = new Icon(icoPath);
        }
        catch { /* icon is cosmetic - ignore if missing/locked */ }

        int y = 16;

        y = AddHeader("PONGZ", "BlueStacks Multi-Instance Test Kit", y);

        y = AddSection("Launch", y);
        y = AddButton("Launch  Portrait  instances", Color.FromArgb(45, 120, 220),
            (s, e) => RunScript("launch-all.ps1", "portrait"), y);
        y = AddButton("Launch  Landscape  instances", Color.FromArgb(45, 120, 220),
            (s, e) => RunScript("launch-all.ps1", "landscape"), y);
        y = AddButton("Launch  ALL  instances", Color.FromArgb(60, 90, 160),
            (s, e) => RunScript("launch-all.ps1", "all"), y);
        y = AddButton("Close  ALL  instances", Color.FromArgb(200, 65, 65),
            (s, e) => RunScript("close-all.ps1", ""), y);

        y = AddSection("Build / Game", y);
        y = AddButton("Install Build to ALL", Color.FromArgb(40, 160, 90),
            (s, e) => RunScript("install-all.ps1", ""), y);
        y = AddButton("Open App on all instances", Color.FromArgb(40, 160, 90),
            (s, e) => RunScript("open-game.ps1", ""), y);

        y = AddSection("Windows", y);
        y = AddButton("Arrange / Tile windows", Color.FromArgb(120, 90, 200),
            (s, e) => RunScript("arrange-windows.ps1", ""), y);

        y = AddSection("Setup", y);
        y = AddButton("Enable ADB  (first time only)", Color.FromArgb(180, 120, 40),
            (s, e) => RunScript("enable-adb.ps1", ""), y);
        y = AddButton("Setup Guide  (how to use)", Color.FromArgb(80, 84, 92),
            (s, e) => ShowGuide(), y);
    }

    // ---- UI builders -------------------------------------------------

    int AddHeader(string title, string subtitle, int y)
    {
        var t = new Label {
            Text = title, ForeColor = Color.White,
            Font = new Font("Segoe UI", 20f, FontStyle.Bold),
            AutoSize = false, TextAlign = ContentAlignment.MiddleCenter,
            Location = new Point(0, y), Size = new Size(ClientSize.Width, 34)
        };
        var s = new Label {
            Text = subtitle, ForeColor = Color.FromArgb(150, 156, 165),
            AutoSize = false, TextAlign = ContentAlignment.MiddleCenter,
            Location = new Point(0, y + 34), Size = new Size(ClientSize.Width, 20)
        };
        Controls.Add(t); Controls.Add(s);
        return y + 64;
    }

    int AddSection(string label, int y)
    {
        var l = new Label {
            Text = label.ToUpper(), ForeColor = Color.FromArgb(120, 126, 135),
            Font = new Font("Segoe UI", 8f, FontStyle.Bold),
            AutoSize = false, TextAlign = ContentAlignment.MiddleLeft,
            Location = new Point(20, y + 6), Size = new Size(ClientSize.Width - 40, 18)
        };
        Controls.Add(l);
        return y + 26;
    }

    int AddButton(string text, Color color, EventHandler onClick, int y)
    {
        var b = new Button {
            Text = text, ForeColor = Color.White, BackColor = color,
            FlatStyle = FlatStyle.Flat,
            Location = new Point(20, y), Size = new Size(ClientSize.Width - 40, 38),
            TextAlign = ContentAlignment.MiddleCenter, Cursor = Cursors.Hand
        };
        b.FlatAppearance.BorderSize = 0;
        b.Click += onClick;
        Controls.Add(b);
        return y + 46;
    }

    // ---- Actions -----------------------------------------------------

    void RunScript(string scriptName, string args)
    {
        string path = Path.Combine(BaseDir, scriptName);
        if (!File.Exists(path))
        {
            MessageBox.Show("Script not found:\n" + path +
                "\n\nKeep this program in the same folder as the toolkit scripts.",
                "Pongz Launcher", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                // -NoExit keeps the window open so the user can read the result.
                Arguments = "-NoProfile -ExecutionPolicy Bypass -NoExit -File \"" + path + "\" " + args,
                WorkingDirectory = BaseDir,
                UseShellExecute = true
            };
            Process.Start(psi);
        }
        catch (Exception ex)
        {
            MessageBox.Show("Could not run script:\n" + ex.Message,
                "Pongz Launcher", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    void ShowGuide()
    {
        string guideText =
            "PONGZ  -  Quick Setup Guide\r\n" +
            "===========================\r\n\r\n" +
            "FIRST TIME ON THIS PC (do once):\r\n" +
            "  1. In BlueStacks Multi-Instance Manager, create your\r\n" +
            "     instances. Use Portrait (e.g. 1080x1920) for portrait\r\n" +
            "     players and Landscape (e.g. 1600x900) for landscape.\r\n" +
            "  2. Click  'Enable ADB (first time only)'  in this app.\r\n" +
            "     It closes BlueStacks, turns on ADB, then you reopen.\r\n" +
            "  3. Put your Pongz .apk into the  Builds  folder\r\n" +
            "     (must be .apk, not .aab).\r\n\r\n" +
            "DAILY USE:\r\n" +
            "  * Launch Portrait / Landscape / ALL  -> boots the\r\n" +
            "    instances and opens the game, then tidies the windows.\r\n" +
            "  * Install Build to ALL  -> installs the newest .apk from\r\n" +
            "    the Builds folder onto every running instance.\r\n" +
            "    (Wait until instances are fully booted first.)\r\n" +
            "  * Open App on all instances  -> relaunches the game\r\n" +
            "    without rebooting the instances.\r\n" +
            "  * Arrange / Tile windows  -> re-tiles if they get messy.\r\n\r\n" +
            "TROUBLESHOOTING:\r\n" +
            "  * Install says 0 succeeded / 'connect error'  -> ADB is\r\n" +
            "    off. Click 'Enable ADB', relaunch instances, retry.\r\n" +
            "  * 'No instances found'  -> create them in the\r\n" +
            "    Multi-Instance Manager first.\r\n" +
            "  * 'No .apk found'  -> put an .apk in the Builds folder.\r\n\r\n" +
            "Tweak window sizes, spacing, package name, etc. in\r\n" +
            "config.ps1.  Full details are in SETUP-GUIDE.txt.";

        var dlg = new Form
        {
            Text = "Pongz - Setup Guide",
            ClientSize = new Size(560, 480),
            StartPosition = FormStartPosition.CenterParent,
            BackColor = Color.FromArgb(33, 37, 43),
            MinimizeBox = false, MaximizeBox = false,
            FormBorderStyle = FormBorderStyle.FixedDialog
        };

        var box = new TextBox
        {
            Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical,
            Text = guideText, BackColor = Color.FromArgb(24, 27, 32),
            ForeColor = Color.FromArgb(220, 224, 230), BorderStyle = BorderStyle.None,
            Font = new Font("Consolas", 9.5f),
            Location = new Point(12, 12), Size = new Size(536, 410)
        };

        var open = new Button
        {
            Text = "Open full SETUP-GUIDE.txt", ForeColor = Color.White,
            BackColor = Color.FromArgb(80, 84, 92), FlatStyle = FlatStyle.Flat,
            Location = new Point(12, 432), Size = new Size(536, 34), Cursor = Cursors.Hand
        };
        open.FlatAppearance.BorderSize = 0;
        open.Click += (s, e) =>
        {
            string guidePath = Path.Combine(BaseDir, "SETUP-GUIDE.txt");
            if (File.Exists(guidePath))
                Process.Start(new ProcessStartInfo(guidePath) { UseShellExecute = true });
            else
                MessageBox.Show("SETUP-GUIDE.txt not found next to this program.",
                    "Pongz Launcher", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        };

        dlg.Controls.Add(box);
        dlg.Controls.Add(open);
        dlg.ShowDialog(this);
    }
}
