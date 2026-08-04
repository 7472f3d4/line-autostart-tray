# =====================================================================
# LINE スタートアップ常駐スクリプト（高速・安定版）
#   - ログイン時にLINEを起動
#   - メインウィンドウ出現後 +2.5秒 でトレイへ格納（WM_CLOSE）
#     ※ LINEは「出現の約1.9秒後」に1回だけウィンドウを再表示するため、
#       それを越えた2.5秒後に閉じると定着する（実測値）
#   - プロセスは終了させない（バックグラウンド常駐）
#   - 対象は 可視 / title に "LINE" / class が *QWindowIcon / トップレベル のみ
# =====================================================================

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;

public class LineWin {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern int  GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern int  GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint cmd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);

    public static List<IntPtr> FindMainWindows() {
        var list = new List<IntPtr>();
        EnumWindows((h, p) => {
            if (!IsWindowVisible(h)) return true;
            if (GetWindow(h, 4) != IntPtr.Zero) return true;       // 所有された子は除外
            var t = new StringBuilder(256); GetWindowText(h, t, 256);
            if (!t.ToString().Contains("LINE")) return true;
            var c = new StringBuilder(256); GetClassName(h, c, 256);
            if (!c.ToString().EndsWith("QWindowIcon")) return true;
            list.Add(h);
            return true;
        }, IntPtr.Zero);
        return list;
    }
    public static void Close(IntPtr h) { PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); }
}
"@

# レジストリとスタートアップフォルダーの両方から呼ばれても一重起動にする。
$lineMutexCreated = $false
$lineMutex = New-Object System.Threading.Mutex($true, "LineAutostartTrayApp", ([ref]$lineMutexCreated))
if (-not $lineMutexCreated) { exit 0 }

$lineExe = "$env:LOCALAPPDATA\LINE\bin\LineLauncher.exe"

# --- 起動（未起動のときだけ） ---
if (-not (Get-Process -Name "LINE" -ErrorAction SilentlyContinue)) {
    Start-Process $lineExe
}

# --- メインウィンドウ出現待ち（最大40秒） ---
$appearDeadline = (Get-Date).AddSeconds(40)
$appeared = $false
while ((Get-Date) -lt $appearDeadline) {
    if (([LineWin]::FindMainWindows()).Count -gt 0) { $appeared = $true; break }
    Start-Sleep -Milliseconds 50
}

# --- 再表示イベント(約1.9秒)を越えるまで待つ ---
if ($appeared) {
    Start-Sleep -Milliseconds 2500
}

# --- メインウィンドウをトレイへ格納（万一の再表示に最大3回まで対応） ---
for ($attempt = 1; $attempt -le 3; $attempt++) {
    $mains = [LineWin]::FindMainWindows()
    if ($mains.Count -eq 0) { break }
    foreach ($h in $mains) { [LineWin]::Close($h) }
    Start-Sleep -Seconds 2
}
