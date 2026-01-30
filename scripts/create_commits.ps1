<#
Create logical, separate commits for this repo's changes.

This helper stages and commits files in groups so you end up with a set of focused commits
that reflect the work done (modules, ansible, scripts, docs, CI, etc.). It uses interactive
confirmation before performing each commit and will not push any changes.

Usage (from repo root):
  .\scripts\create_commits.ps1

Notes:
- Requires `git` available on PATH and that you run this script from the repository root.
- Review the groups below and adjust patterns if you want different grouping.
#>

Set-StrictMode -Version Latest

function Confirm-Or-Exit($msg) {
  $r = Read-Host "$msg (y/N)"
  if ($r -notmatch '^[Yy]') { Write-Host "Aborting."; exit 1 }
}

if (-not (Test-Path .git)) {
  Write-Error "This folder is not a git repository (no .git). Initialize or run from repo root."
  exit 1
}

Write-Host "This script will create a sequence of commits grouping related files."
Confirm-Or-Exit "Proceed with creating grouped commits?"

$groups = @(
  @{ name = 'scaffold: initial repo files'; patterns = @('.gitignore','README.md','requirements.txt') },
  @{ name = 'terraform modules: aws and oci skeletons'; patterns = @('modules/aws/**','modules/oci/**') },
  @{ name = 'examples: terraform root and outputs'; patterns = @('examples/terraform/**') },
  @{ name = 'ansible: playbook, role, templates'; patterns = @('ansible/**') },
  @{ name = 'scripts: health check, inventory generator, helpers'; patterns = @('scripts/*.py','scripts/*.ps1') },
  @{ name = 'ci: github workflows'; patterns = @('.github/workflows/**') },
  @{ name = 'docs: diagrams, demo GIF, RELEASE.md'; patterns = @('docs/**','RELEASE.md') },
  @{ name = 'license & contributing'; patterns = @('LICENSE','CONTRIBUTING.md','CODE_OF_CONDUCT.md','.github/**','PULL_REQUEST_TEMPLATE.md') },
  @{ name = 'makefile & tfvars example'; patterns = @('Makefile','examples/terraform/terraform.tfvars.example') },
  @{ name = 'README updates & badges'; patterns = @('README.md') }
)

foreach ($g in $groups) {
  Write-Host "\nGroup: $($g.name)"
  Write-Host "Patterns: $($g.patterns -join ', ')"
  $confirm = Read-Host "Stage and commit these patterns now? (y/N)"
  if ($confirm -match '^[Yy]') {
    # Stage files matching the patterns
    foreach ($p in $g.patterns) {
      git add --force $p 2>$null
    }

    # Show staged files
    $staged = git diff --cached --name-only
    if (-not $staged) {
      Write-Host "No files staged for this group. Skipping commit."
      continue
    }
    Write-Host "Staged files:\n$staged"
    $msg = Read-Host "Enter commit message for this group (default: $($g.name))"
    if (-not $msg) { $msg = $g.name }
    git commit -m "$msg"
    Write-Host "Committed: $msg"
  }
  else {
    Write-Host "Skipped group: $($g.name)"
  }
}

Write-Host "All groups processed. Review your commits with 'git log --oneline'."
