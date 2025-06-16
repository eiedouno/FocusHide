param([string]$appName)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("kernel32.dll")]
    public static extern bool FreeConsole();
}
"@

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-WindowTitle {
    param([IntPtr]$hwnd)
    $title = New-Object System.Text.StringBuilder 1024
    [void][Win32]::GetWindowText($hwnd, $title, $title.Capacity)
    return $title.ToString()
}

function Get-AppHWNDs {
    param([string]$AppName)
    Get-Process | Where-Object {
        $_.MainWindowHandle -ne 0 -and $_.ProcessName -like "*$AppName*"
    } | ForEach-Object { $_.MainWindowHandle }
}


if (-not $appName) { exit }
Start-Sleep -Milliseconds 500  # Just to give the console time to fully show
$consoleHWND = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consoleHWND, 0)  # 0 = SW_HIDE

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Text = "App Monitor - $appName"
$notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitItem = $contextMenu.Items.Add("Exit")
$exitItem.Add_Click({
    $global:exitFlag = $true
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})
$notifyIcon.ContextMenuStrip = $contextMenu
$notifyIcon.add_MouseClick({
    if ($_.Button -eq 'Right') {
        $contextMenu.Show([System.Windows.Forms.Cursor]::Position)
    }
})

$minimizedWindows = @{}
$exitFlag = $false

# Use a timer instead of while-loop
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    if ($exitFlag) { return }

    $targetWindows = Get-AppHWNDs -AppName $appName
    $foreground = [Win32]::GetForegroundWindow()

    foreach ($hwnd in $targetWindows) {
        $wasMinimized = $minimizedWindows[$hwnd] -eq $true
        $isVisible = [Win32]::IsWindowVisible($hwnd)

        if ($hwnd -ne $foreground -and $isVisible -and -not $wasMinimized) {
            $title = Get-WindowTitle -hwnd $hwnd
            Write-Host "[INFO] App unfocused: $title -> Minimizing..." -ForegroundColor Yellow
            [Win32]::ShowWindow($hwnd, 6)
            $minimizedWindows[$hwnd] = $true
        } elseif ($hwnd -eq $foreground) {
            $minimizedWindows[$hwnd] = $false
        }
    }
})

$timer.Start()
[System.Windows.Forms.Application]::Run()
