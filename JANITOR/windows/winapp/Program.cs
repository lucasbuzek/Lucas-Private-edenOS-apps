using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Janitor;

static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}

/// Thin adapter: every operation is performed by the embedded janitor.ps1 (the tested safety contract).
/// The window only chooses what to run, shows the output, and asks for confirmation.
/// Targets .NET Framework 4.5 so it runs from Windows 7 SP1 to Windows 11. Needs Windows PowerShell 3.0+ (WMF 5.1 on Windows 7).
class MainForm : Form
{
    readonly string state = Environment.GetEnvironmentVariable("JANITOR_HOME")
        ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "JANITOR");
    readonly string qroot = Environment.GetEnvironmentVariable("JANITOR_QUARANTINE")
        ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads", "#Review&Delete", "JANITOR");
    string script;
    bool busy;

    readonly ListView grid = new ListView { View = View.Details, CheckBoxes = true, FullRowSelect = true, Dock = DockStyle.Fill, HideSelection = false };
    readonly TextBox log = new TextBox { Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Dock = DockStyle.Bottom, Height = 180, Font = new Font("Consolas", 9) };
    readonly FlowLayoutPanel bar = new FlowLayoutPanel { Dock = DockStyle.Top, AutoSize = true, Padding = new Padding(6) };
    readonly Label summary = new Label { Dock = DockStyle.Top, Height = 24, Padding = new Padding(8, 4, 0, 0), Text = "JANITOR 0.1.2 - nothing changes without review and confirmation." };

    public MainForm()
    {
        Text = "JANITOR";
        Width = 1050; Height = 720; StartPosition = FormStartPosition.CenterScreen;
        Directory.CreateDirectory(state);
        script = Path.Combine(state, "janitor.ps1");
        using (var s = Assembly.GetExecutingAssembly().GetManifestResourceStream("janitor.ps1"))
        using (var f = File.Create(script)) s.CopyTo(f);

        grid.Columns.Add("ID", 45); grid.Columns.Add("Safety", 70); grid.Columns.Add("Size", 90);
        grid.Columns.Add("Category", 130); grid.Columns.Add("Path / kept copy", 650);

        AddButton("Quick Scan", async () => { await Run("scan quick"); LoadCandidates(); });
        AddButton("Full Scan", async () => { await Run("scan full"); LoadCandidates(); });
        AddButton("Exact Duplicates...", async () =>
        {
            using (var d = new FolderBrowserDialog { Description = "Choose a folder (leave Cancel for Videos/Music/Pictures/Downloads). Your profile folder is refused." })
            {
                var arg = d.ShowDialog() == DialogResult.OK ? $"dupes \"{d.SelectedPath}\"" : "dupes";
                await Run(arg); LoadCandidates();
            }
        });
        AddButton("Quarantine selected", () => Act("quarantine", false));
        AddButton("Delete selected...", () => Act("delete", true));
        AddButton("Quarantine / Recovery...", () => { new QuarantineForm(this, qroot).ShowDialog(this); return Task.FromResult(0); });
        AddButton("Processes", () => Run("inventory processes"));
        AddButton("Startup", () => Run("inventory startup"));
        AddButton("Installed apps", () => Run("inventory apps"));
        AddButton("Storage", () => Run("inventory storage"));
        AddButton("Cloud boundaries", () => Run("inventory cloud"));
        AddButton("Diagnostics", () => Run("diag"));
        AddButton("Open logs", () => { System.Diagnostics.Process.Start(new ProcessStartInfo(state) { UseShellExecute = true }); return Task.FromResult(0); });

        Controls.Add(grid); Controls.Add(summary); Controls.Add(bar); Controls.Add(log);
        bar.BringToFront(); summary.BringToFront(); grid.BringToFront();
    }

    void AddButton(string text, Func<Task> click)
    {
        var b = new Button { Text = text, AutoSize = true, Padding = new Padding(6, 2, 6, 2) };
        b.Click += async (_, __) => { if (busy) return; await click(); };
        bar.Controls.Add(b);
    }

    public void Append(string line)
    {
        if (InvokeRequired) { BeginInvoke((MethodInvoker)(() => Append(line))); return; }
        log.AppendText(line + Environment.NewLine);
    }

    public async Task<int> Run(string args)
    {
        busy = true; UseWaitCursor = true;
        Append($"> janitor {args}");
        var psi = new ProcessStartInfo("powershell.exe", $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\" {args}")
        {
            RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true,
            StandardOutputEncoding = Encoding.UTF8, StandardErrorEncoding = Encoding.UTF8
        };
        try
        {
            using (var p = Process.Start(psi))
            {
                p.OutputDataReceived += (_, e) => { if (e.Data != null) Append(e.Data); };
                p.ErrorDataReceived += (_, e) => { if (e.Data != null) Append(e.Data); };
                p.BeginOutputReadLine(); p.BeginErrorReadLine();
                await Task.Run(() => p.WaitForExit());   // also flushes the async output readers
                return p.ExitCode;
            }
        }
        catch (Exception ex) { Append("Could not start PowerShell: " + ex.Message); return -1; }
        finally { busy = false; UseWaitCursor = false; }
    }

    void LoadCandidates()
    {
        grid.Items.Clear();
        var path = Path.Combine(state, "last-scan.tsv");
        if (!File.Exists(path)) return;
        long safeKb = 0;
        foreach (var line in File.ReadAllLines(path, Encoding.UTF8))
        {
            var c = line.Split('\t');
            if (c.Length < 5) continue;
            long kb; long.TryParse(c[2], out kb);
            var it = new ListViewItem(c[0]) { Checked = c[1] == "SAFE" };
            it.SubItems.Add(c[1]); it.SubItems.Add(kb >= 1024 ? $"{kb / 1024.0:N1} MB" : $"{kb} KB"); it.SubItems.Add(c[3]);
            it.SubItems.Add(c.Length > 5 && c[5].Length > 0 ? $"{c[4]}   (keeps: {c[5]})" : c[4]);
            if (c[1] != "SAFE") it.ForeColor = Color.DarkOrange; else safeKb += kb;
            grid.Items.Add(it);
        }
        summary.Text = $"{grid.Items.Count} candidate(s) - SAFE items are pre-checked ({safeKb / 1024.0:N1} MB). Unknown is never junk: REVIEW items are unchecked.";
    }

    async Task Act(string verb, bool destructive)
    {
        var ids = grid.CheckedItems.Cast<ListViewItem>().Select(i => i.Text).ToList();
        if (ids.Count == 0) { MessageBox.Show(this, "Nothing is checked.", "JANITOR"); return; }
        var q = destructive
            ? $"PERMANENTLY delete {ids.Count} item(s)?\n\nThis cannot be undone. Choose Quarantine instead if you may want them back."
            : $"Move {ids.Count} item(s) to quarantine?\n\nThey stay recoverable under Quarantine / Recovery. Each move is verified.";
        var r = MessageBox.Show(this, q, "JANITOR", MessageBoxButtons.YesNo,
            destructive ? MessageBoxIcon.Warning : MessageBoxIcon.Question, MessageBoxDefaultButton.Button2);
        if (r != DialogResult.Yes) return;
        await Run($"{verb} {string.Join(" ", ids)} -Yes");
        grid.Items.Clear();
        summary.Text = "Done - run a scan again before further changes (IDs refer to the previous scan).";
    }
}

class QuarantineForm : Form
{
    readonly MainForm owner; readonly string qroot;
    readonly ListBox ops = new ListBox { Dock = DockStyle.Left, Width = 260 };
    readonly ListView items = new ListView { View = View.Details, FullRowSelect = true, CheckBoxes = true, Dock = DockStyle.Fill };
    readonly FlowLayoutPanel bar = new FlowLayoutPanel { Dock = DockStyle.Bottom, AutoSize = true, Padding = new Padding(6) };

    public QuarantineForm(MainForm owner, string qroot)
    {
        this.owner = owner; this.qroot = qroot;
        Text = "Quarantine / Recovery"; Width = 900; Height = 520; StartPosition = FormStartPosition.CenterParent;
        items.Columns.Add("#", 40); items.Columns.Add("State", 80); items.Columns.Add("Original path", 650);
        Controls.Add(items); Controls.Add(ops); Controls.Add(bar);
        Button B(string t, Func<Task> a) { var b = new Button { Text = t, AutoSize = true }; b.Click += async (_, __) => await a(); bar.Controls.Add(b); return b; }
        B("Restore selected", () => Restore(true)); B("Restore all", () => Restore(false));
        B("Reveal", () => { var o = Current(); if (o != null) System.Diagnostics.Process.Start(new ProcessStartInfo(Path.Combine(qroot, o)) { UseShellExecute = true }); return Task.FromResult(0); });
        B("Purge operation...", Purge); B("Refresh", async () => { await owner.Run("list"); LoadOps(); });
        ops.SelectedIndexChanged += (_, __) => LoadItems();
        Shown += async (_, __) => { await owner.Run("list"); LoadOps(); };
    }

    string Current() { return ops.SelectedItem as string; }

    void LoadOps()
    {
        ops.Items.Clear();
        if (!Directory.Exists(qroot)) return;
        foreach (var d in Directory.GetDirectories(qroot).OrderByDescending(x => x))
            if (File.Exists(Path.Combine(d, "manifest.tsv"))) ops.Items.Add(Path.GetFileName(d));
    }

    void LoadItems()
    {
        items.Items.Clear();
        var op = Current(); if (op == null) return;
        int n = 0;
        foreach (var line in File.ReadAllLines(Path.Combine(qroot, op, "manifest.tsv"), Encoding.UTF8))
        {
            if (line.Length == 0 || line[0] == '#') continue;
            var c = line.Split('\t'); n++;
            var state = c[0] == "MOVED" && c.Length > 2 && !File.Exists(c[2]) && !Directory.Exists(c[2]) ? "MISSING" : c[0];
            var it = new ListViewItem(n.ToString()); it.SubItems.Add(state); it.SubItems.Add(c.Length > 1 ? c[1] : "");
            items.Items.Add(it);
        }
    }

    async Task Restore(bool selectedOnly)
    {
        var op = Current(); if (op == null) return;
        var picks = selectedOnly ? string.Join(" ", items.CheckedItems.Cast<ListViewItem>().Select(i => i.Text)) : "";
        if (selectedOnly && picks.Length == 0) { MessageBox.Show(this, "Check the items to restore.", "JANITOR"); return; }
        await owner.Run($"restore {op} {picks}".Trim()); await owner.Run("list"); LoadItems();
    }

    async Task Purge()
    {
        var op = Current(); if (op == null) return;
        var r = MessageBox.Show(this, $"Permanently delete {op}?\n\nItems still inside can no longer be restored.", "JANITOR",
            MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2);
        if (r != DialogResult.Yes) return;
        await owner.Run($"purge {op} -Yes"); LoadOps(); items.Items.Clear();
    }
}
