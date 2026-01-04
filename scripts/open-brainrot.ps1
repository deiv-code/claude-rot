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

Add-Type -AssemblyName System.Windows.Forms

# Get screen dimensions
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Calculate column width (1/4 of screen)
$columnWidth = [math]::Floor($screen.Width / 4)
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

function Open-Windows {
    # Get existing Chrome PIDs before opening
    $existingPids = @(Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

    for ($i = 0; $i -lt $urls.Count; $i++) {
        $url = $urls[$i]
        $xPos = $screen.Left + ($columnWidth * $i)

        Start-Process $chromePath -ArgumentList @(
            "--new-window",
            "--window-position=$xPos,$($screen.Top)",
            "--window-size=$columnWidth,$windowHeight",
            "--app=$url"
        )

        Start-Sleep -Milliseconds 300
    }

    # Wait for processes to start
    Start-Sleep -Milliseconds 1000

    # Get new Chrome PIDs
    $allPids = @(Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    $newPids = $allPids | Where-Object { $_ -notin $existingPids }

    # Save new PIDs
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
