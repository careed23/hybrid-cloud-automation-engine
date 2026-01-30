<#
Publish the repository to GitHub and configure basic protections.

This script uses the GitHub CLI (`gh`) and local `git` to:
- add a remote (if needed) and push the current branch
- create a lightweight release tag and push it
- create branch protection rules (via `gh api`)
- add repository secrets via `gh secret set` (prompts for values)

Important: This script does not store secrets in plaintext. It prompts for values and sets them via the GitHub CLI.

Prerequisites:
- Install and authenticate `gh`: https://cli.github.com/manual/installation and `gh auth login`
- Ensure `git` is configured with your name/email and you have push access to the target repo

Usage:
  # interactive: will prompt for repo URL and branch name
  .\scripts\publish_repo.ps1

  # non-interactive:
  .\scripts\publish_repo.ps1 -RepoUrl https://github.com/careed23/hybrid-cloud-automation-engine.git -Branch main

#>

[CmdletBinding()]
param(
  [string]$RepoUrl = "",
  [string]$Branch = "main"
)

Set-StrictMode -Version Latest

function Ensure-Gh {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "gh (GitHub CLI) is required. Install from https://cli.github.com/"
    exit 1
  }
}

Ensure-Gh

if (-not $RepoUrl) {
  $RepoUrl = Read-Host "Enter target GitHub repo URL (e.g. https://github.com/your-org/hybrid-cloud-automation-engine.git)"
}

Write-Host "Using repo: $RepoUrl"

# Ensure remote exists
$existing = git remote get-url origin 2>$null
if (-not $existing) {
  git remote add origin $RepoUrl
  Write-Host "Added remote origin -> $RepoUrl"
} else {
  Write-Host "Remote origin already configured: $existing"
}

# Push branch
Write-Host "Pushing branch $Branch to origin..."
git push -u origin $Branch

# Create a lightweight release tag
$tag = "v$(Get-Date -Format 'yyyy.MM.dd')"
Write-Host "Creating tag $tag"
git tag $tag
git push origin $tag

Write-Host "Attempting to configure basic branch protection (requires repo admin privileges)."
Write-Host "This step uses the gh api to set a simple protection requiring PR reviews and status checks (best-effort)."

try {
  # Example protection payload. You can customize rules as needed.
  $ownerRepo = ($RepoUrl -replace '^https://github.com/','') -replace '\.git$',''
  $apiPath = "/repos/$ownerRepo/branches/$Branch/protection"
  $body = @{
    required_status_checks = @{ strict = $false; contexts = @() }
    enforce_admins = $true
    required_pull_request_reviews = @{ dismissal_restrictions = @{}; dismiss_stale_reviews = $true; require_code_owner_reviews = $false; required_approving_review_count = 1 }
    restrictions = $null
  } | ConvertTo-Json -Depth 10

  gh api -X PUT $apiPath -F body="$body" 2>$null
  Write-Host "Branch protection API request sent (check repo settings to confirm)."
}
catch {
  Write-Warning "Branch protection configuration failed: $_"
}

# Optionally set repository secrets
if ((Read-Host "Do you want to add repository secrets now? (y/N)") -match '^[Yy]') {
  while ($true) {
    $name = Read-Host "Secret name (empty to finish)"
    if (-not $name) { break }
    $value = Read-Host -AsSecureString "Secret value (input will be hidden)"
    # Convert securestring to plain for gh; we avoid writing it to disk
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    gh secret set $name --body "$plain" --repo $ownerRepo
    Write-Host "Set secret: $name"
  }
}

Write-Host "Publish steps completed. Verify settings on GitHub: $RepoUrl"
