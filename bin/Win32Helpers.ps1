Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class NativeMethods {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
}
"@ -Language CSharp

function Get-WindowTitle {
    param([IntPtr]$hwnd)
    $sb = New-Object System.Text.StringBuilder 1024
    [void][NativeMethods]::GetWindowText($hwnd, $sb, $sb.Capacity)
    return $sb.ToString()
}

function Get-AppHWNDs {
    param([string]$AppName)
    Get-Process |
      Where-Object { $_.MainWindowHandle -ne 0 -and $_.ProcessName -like "*$AppName*" } |
      ForEach-Object { $_.MainWindowHandle }
}
