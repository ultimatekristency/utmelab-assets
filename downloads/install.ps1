# UTME Lab one-line installer (Windows, per-user, no admin).
#
#   iwr -useb https://utmelab.com/downloads/install.ps1 | iex
#
# Resolves the CURRENT release from latest.json (no version is hardcoded
# here, so this script never goes stale), verifies the download against
# SHA256SUMS, then runs the NSIS setup silently into %LOCALAPPDATA%.
# Override the shelf (tests, mirrors) with -BaseUrl.

param([string]$BaseUrl = "https://assets.utmelab.com/downloads")

$ErrorActionPreference = 'Stop'
$work = Join-Path $env:TEMP ("utmelab-install-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    Write-Host 'Fetching release info ...'
    $manifest = Invoke-RestMethod -Uri "$BaseUrl/latest.json"
    $url = $manifest.update.windows_setup_url
    if (-not $url) { throw 'No Windows setup published in the current release.' }
    $name = $url.Split('/')[-1]

    Write-Host "Downloading $name ..."
    $setup = Join-Path $work $name
    Invoke-WebRequest -Uri $url -OutFile $setup
    Invoke-WebRequest -Uri "$BaseUrl/SHA256SUMS" -OutFile (Join-Path $work 'SHA256SUMS')

    $line = Get-Content (Join-Path $work 'SHA256SUMS') | Where-Object { $_ -like "*  $name" } | Select-Object -First 1
    if (-not $line) { throw "No checksum entry for $name." }
    $want = ($line -split '\s+')[0]
    $got = (Get-FileHash $setup -Algorithm SHA256).Hash
    if ($got.ToLowerInvariant() -ne $want.ToLowerInvariant()) { throw "Checksum mismatch for $name - download corrupted, aborting." }

    Write-Host 'Installing (per-user, no admin) ...'
    Start-Process -FilePath $setup -ArgumentList '/S' -Wait

    $exe = Join-Path $env:LOCALAPPDATA 'UTME Lab\utmelab-desktop.exe'
    if (-not (Test-Path $exe)) { throw "Install finished but not found: $exe" }
    Write-Host 'UTME Lab installed.'
}
finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
