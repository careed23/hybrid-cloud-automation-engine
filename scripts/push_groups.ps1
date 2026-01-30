<#
Create and push grouped branches for the repository.

This script stages files matching configured patterns into a new branch per group,
commits with a sensible message, pushes the branch to the configured remote, and
optionally opens a Pull Request using the GitHub CLI (`gh`).

Usage (from repo root):
  .\scripts\push_groups.ps1

Options:
  -OpenPR : Prompt to open a PR for each pushed branch (requires `gh auth login`)

Notes:
- This script does not modify the current branch; it creates feature branches off the
  current HEAD. Ensure your working tree is clean or stash changes you don't want included.
- Requires `git` and optionally `gh` on PATH.
#>

[CmdletBinding()]
param(
  [switch]$OpenPR
)

Set-StrictMode -Version Latest

if (-not (Test-Path .git)) { Write-Error "Not a git repository. Run this from repository root."; exit 1 }

function Sanitize-BranchName($s) {
  # Lowercase, replace spaces and '/' with '-', remove invalid chars
  $s = $s.ToLower() -replace '[^a-z0-9\-\_ ]','' -replace '[ \/]+','-'
  return $s
}

$groups = @(
  @{ name = 'scaffold-initial-files'; patterns = @('.gitignore','README.md','requirements.txt') },
  @{ name = 'terraform-modules-aws-oci'; patterns = @('modules/aws/**','modules/oci/**') },
  @{ name = 'examples-terraform-root'; patterns = @('examples/terraform/**') },
  @{ name = 'ansible-role-playbook'; patterns = @('ansible/**') },
  @{ name = 'scripts-helpers'; patterns = @('scripts/*.py','scripts/*.ps1') },
  @{ name = 'ci-workflows'; patterns = @('.github/workflows/**') },
  @{ name = 'docs-and-diagrams'; patterns = @('docs/**','RELEASE.md') },
  @{ name = 'license-contributing-templates'; patterns = @('LICENSE','CONTRIBUTING.md','CODE_OF_CONDUCT.md','.github/**','PULL_REQUEST_TEMPLATE.md') },
  @{ name = 'makefile-and-tfvars-example'; patterns = @('Makefile','examples/terraform/terraform.tfvars.example') },
  @{ name = 'readme-badges-quickstart'; patterns = @('README.md') }
)

$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Current branch: $currentBranch"

foreach ($g in $groups) {
  $branchBase = "group/$($g.name)"
  $branch = Sanitize-BranchName($branchBase)
  Write-Host "\nProcessing group: $($g.name) -> branch: $branch"

  # Create branch from current HEAD
  git branch --no-track $branch $currentBranch 2>$null | Out-Null

  # Checkout new branch
  git checkout $branch

  # Stage patterns
  $stagedAny = $false
  foreach ($p in $g.patterns) {
    git add --force $p 2>$null
    $added = git diff --cached --name-only | Select-String -Pattern '^' -Quiet
    if ($added) { $stagedAny = $true }
  }

  if (-not $stagedAny) {
    Write-Host "No files matched/staged for group $($g.name). Skipping branch push and deleting branch."
    git checkout $currentBranch
    git branch -D $branch 2>$null | Out-Null
    continue
  }

  # Commit
  $msg = Read-Host "Enter commit message for branch '$branch' (default: $($g.name))"
  if (-not $msg) { $msg = $g.name }
  git commit -m "$msg"

  # Push branch
  git push -u origin $branch
  Write-Host "Pushed branch: $branch"

  if ($OpenPR) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
      gh pr create --fill --base $currentBranch --head $branch
      Write-Host "Opened PR for $branch -> $currentBranch"
    } else {
      Write-Warning "gh CLI not available; cannot open PR automatically. Install and auth 'gh' to enable PR creation."
    }
  }

  # Return to main branch
  git checkout $currentBranch
}

Write-Host "All groups processed. You can review branches with 'git branch -r' and open PRs on GitHub."
