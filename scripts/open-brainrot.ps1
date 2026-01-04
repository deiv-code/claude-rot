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
    "https://www.youtube.com/shorts",
    "https://x.com/"
)

# Windows API for moving windows
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
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
$dataDir = [System.IO.Path]::Combine($env:TEMP, "claude-rot-chrome")

function Open-Windows {
    # Skip if windows are already open
    if (Test-Path $pidFile) {
        $savedPids = Get-Content $pidFile
        foreach ($p in $savedPids) {
            if ($p) {
                try {
                    $proc = Get-Process -Id ([int]$p) -ErrorAction SilentlyContinue
                    if ($proc) {
                        return
                    }
                } catch {}
            }
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }

    $newPids = @()

    # Open each window with its own Chrome profile
    for ($i = 0; $i -lt $urls.Count; $i++) {
        $url = $urls[$i]
        $xPos = $screen.Left + ($columnWidth * $i)
        $profileDir = "$dataDir\profile$i"

        $proc = Start-Process $chromePath -ArgumentList @(
            "--user-data-dir=`"$profileDir`"",
            "--window-position=$xPos,$($screen.Top)",
            "--window-size=$columnWidth,$windowHeight",
            "--app=$url"
        ) -PassThru

        $newPids += $proc.Id
        Start-Sleep -Milliseconds 300
    }

    # Wait for windows to appear
    Start-Sleep -Milliseconds 2000

    # Move windows using Win32 API
    for ($i = 0; $i -lt $urls.Count; $i++) {
        $xPos = $screen.Left + ($columnWidth * $i)

        try {
            $proc = Get-Process -Id $newPids[$i] -ErrorAction SilentlyContinue
            if ($proc) {
                # Wait for main window
                for ($attempt = 0; $attempt -lt 10; $attempt++) {
                    $proc.Refresh()
                    if ($proc.MainWindowHandle -ne 0) {
                        [Win32]::MoveWindow($proc.MainWindowHandle, $xPos, $screen.Top, $columnWidth, $windowHeight, $true) | Out-Null
                        break
                    }
                    Start-Sleep -Milliseconds 200
                }
            }
        } catch {}
    }

    if ($newPids.Count -gt 0) {
        $newPids -join "`n" | Set-Content -Path $pidFile -Force
    }
}

function Close-Windows {
    if (Test-Path $pidFile) {
        $savedPids = Get-Content $pidFile
        foreach ($p in $savedPids) {
            if ($p) {
                try {
                    Stop-Process -Id ([int]$p) -Force -ErrorAction SilentlyContinue
                } catch {}
            }
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }
}

switch ($Action) {
    "open" { Open-Windows }
    "close" { Close-Windows }
}
