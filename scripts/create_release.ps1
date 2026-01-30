<#
.SYNOPSIS
  Create and publish a GitHub release for this repository.

.DESCRIPTION
  Uses `gh` if available. If `gh` is not installed, prompts for a GitHub PAT and
  uses the REST API to create a release and upload an optional asset.

.PARAMETER TagName
  Tag to create (default v1.0.0)

.PARAMETER Title
  Release title (defaults to TagName)

.PARAMETER NotesFile
  Path to a file containing release notes (default: RELEASE.md)

.PARAMETER AssetPath
  Optional path to an asset to upload (default: docs/demo.gif)

.PARAMETER Draft
  If present, create the release as a draft. Default: $false (publish immediately)

Examples:
  .\create_release.ps1 -TagName v1.0.0
  .\create_release.ps1 -TagName v1.0.0 -Draft:$true
#>

param(
    [string]$TagName = 'v1.0.0',
    [string]$Title = '',
    [string]$NotesFile = 'RELEASE.md',
    [string]$AssetPath = 'docs/demo.gif',
    [switch]$Draft
)

if (-not $Title) { $Title = $TagName }

$Owner = 'careed23'
$Repo = 'hybrid-cloud-automation-engine'

Write-Host "Preparing to create release $TagName for $Owner/$Repo (draft: $($Draft.IsPresent))"

# prefer gh if present
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "Using gh CLI to create release..."
    $args = @($TagName, '--title', $Title, '--notes-file', $NotesFile)
    if ($Draft) { $args += '--draft' }
    # attach asset if it exists
    if (Test-Path $AssetPath) { $args += @('--assets', $AssetPath) }

    gh release create @args
    if ($LASTEXITCODE -eq 0) { Write-Host "Release created successfully via gh." } else { Write-Host "gh returned exit code $LASTEXITCODE" }
    exit $LASTEXITCODE
}

Write-Host "gh CLI not found — will use GitHub REST API. You need a PAT with 'repo' scope."

# prompt for PAT securely
$securePat = Read-Host -Prompt 'Enter GitHub PAT (repo scope) — it will not be stored' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePat))
$headers = @{ Authorization = "token $ptr"; 'User-Agent' = 'powershell' }

if (-not (Test-Path $NotesFile)) {
    Write-Host "Notes file '$NotesFile' not found. Creating a simple body from tag." -ForegroundColor Yellow
    $bodyText = "Release $TagName"
} else {
    $bodyText = Get-Content -Raw -Path $NotesFile
}

$body = @{ tag_name = $TagName; name = $Title; body = $bodyText; draft = [bool]$Draft.IsPresent; prerelease = $false } | ConvertTo-Json -Depth 6

try {
    $uri = "https://api.github.com/repos/$Owner/$Repo/releases"
    Write-Host "Creating release via REST API..."
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType 'application/json'
    Write-Host "Release created: $($response.html_url)"
} catch {
    Write-Error "Failed to create release: $_"
    exit 1
}

if (Test-Path $AssetPath) {
    try {
  $assetName = [IO.Path]::GetFileName($AssetPath)
  # clean the templated upload_url (it contains a trailing {...}) and append the asset name
  $uploadUrl = $response.upload_url
  $uploadUrl = $uploadUrl -replace '\{.*\}$',''
  $uploadUrl = "$uploadUrl?name=$assetName"
  Write-Host "Uploading asset $assetName to $uploadUrl"
    # upload by reading bytes and POSTing as the body (PowerShell 5.1 compatible)
    $bytes = [System.IO.File]::ReadAllBytes($AssetPath)
    $uploadResponse = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $headers -Body $bytes -ContentType "application/octet-stream"
    if ($uploadResponse -ne $null -and $uploadResponse.browser_download_url) {
      Write-Host "Uploaded asset: $($uploadResponse.browser_download_url)"
    } else {
      Write-Host "Upload completed; response: $uploadResponse"
    }
    } catch {
        Write-Warning "Asset upload failed: $_"
    }
} else {
    Write-Host "Asset not found at $AssetPath — skipping upload." -ForegroundColor Yellow
}

Write-Host "Done. Release URL: $($response.html_url)"
