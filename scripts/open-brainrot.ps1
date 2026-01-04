# claude-rot: Open brainrot while Claude works (Windows)
# Usage: .\open-brainrot.ps1 -Action open|close

param(
    [Parameter(Position=0)]
    [ValidateSet("open", "close")]
    [string]$Action = "open"
)

# URLs to open
$urls = @(
    "https://www.tiktok.com/foryou",
    "https://www.instagram.com/reels/",
    #"https://www.youtube.com/shorts",
    "https://x.com/"
)

# Windows API for moving windows
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public static List<IntPtr> windows = new List<IntPtr>();

    public static bool EnumWindowsCallback(IntPtr hWnd, IntPtr lParam) {
        if (IsWindowVisible(hWnd) && GetWindowTextLength(hWnd) > 0) {
            windows.Add(hWnd);
        }
        return true;
    }

    public static List<IntPtr> GetAllWindows() {
        windows.Clear();
        EnumWindows(EnumWindowsCallback, IntPtr.Zero);
        return windows;
    }
}
"@

Add-Type -AssemblyName System.Windows.Forms

# Get screen dimensions
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Calculate column width based on number of URLs
$columnWidth = [math]::Floor($screen.Width / $urls.Count)
$windowHeight = $screen.Height

# Path to Chrome
$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
)

$chromePath = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $chromePath) {
    Write-Error "Chrome not found."
    exit 1
}

$pidFile = [System.IO.Path]::Combine($env:TEMP, "claude-rot-pids.txt")
$handleFile = [System.IO.Path]::Combine($env:TEMP, "claude-rot-handles.txt")

function Open-Windows {
    # Skip if windows are already open
    if (Test-Path $handleFile) {
        $savedHandles = Get-Content $handleFile
        foreach ($h in $savedHandles) {
            if ($h) {
                # Check if window still exists
                $allWindows = [Win32]::GetAllWindows()
                if ($allWindows -contains [IntPtr]::new([long]$h)) {
                    return
                }
            }
        }
        Remove-Item $handleFile -Force -ErrorAction SilentlyContinue
    }

    $newHandles = @()

    # Open each window, wait for it, and move it immediately
    for ($i = 0; $i -lt $urls.Count; $i++) {
        $url = $urls[$i]
        $xPos = $screen.Left + ($columnWidth * $i)

        # Get windows before opening
        $beforeWindows = [Win32]::GetAllWindows() | ForEach-Object { $_.ToInt64() }

        # Open window
        Start-Process $chromePath -ArgumentList "--new-window", "--app=$url"

        # Wait for new window to appear and move it immediately
        $found = $false
        for ($attempt = 0; $attempt -lt 50 -and -not $found; $attempt++) {
            Start-Sleep -Milliseconds 50
            $afterWindows = [Win32]::GetAllWindows()

            foreach ($hwnd in $afterWindows) {
                if ($hwnd.ToInt64() -notin $beforeWindows) {
                    $procId = 0
                    [Win32]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null
                    try {
                        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
                        if ($proc.ProcessName -eq "chrome") {
                            # Move immediately
                            [Win32]::MoveWindow($hwnd, $xPos, $screen.Top, $columnWidth, $windowHeight, $true) | Out-Null
                            $newHandles += $hwnd
                            $found = $true
                            break
                        }
                    } catch {}
                }
            }
        }
    }

    # Save handles for later
    if ($newHandles.Count -gt 0) {
        ($newHandles | ForEach-Object { $_.ToInt64() }) -join "`n" | Set-Content -Path $handleFile -Force
    }
}

function Close-Windows {
    if (Test-Path $handleFile) {
        $savedHandles = Get-Content $handleFile

        # Find processes for these windows and close them
        foreach ($h in $savedHandles) {
            if ($h) {
                try {
                    $hwnd = [IntPtr]::new([long]$h)
                    $procId = 0
                    [Win32]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null
                    if ($procId -gt 0) {
                        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        }
        Remove-Item $handleFile -Force -ErrorAction SilentlyContinue
    }
}

switch ($Action) {
    "open" { Open-Windows }
    "close" { Close-Windows }
}
