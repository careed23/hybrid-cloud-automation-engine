<#
.SYNOPSIS
  Run Terraform in the example root and generate an Ansible inventory from outputs.

.DESCRIPTION
  This script initializes and applies Terraform in `examples/terraform`, then runs the
  `scripts/generate_inventory.py` helper to create `ansible/inventory.tf.ini`.

.PARAMETER TfDir
  Path to the Terraform root relative to the repository root. Default: examples/terraform

.PARAMETER AutoApprove
  If present, Terraform will be applied with -auto-approve. Otherwise the plan will be shown
  and the user will be prompted to confirm apply.

EXAMPLE
  .\scripts\deploy_and_inventory.ps1 -AutoApprove

#>

[CmdletBinding()]
param(
    [string]$TfDir = "examples/terraform",
    [switch]$AutoApprove
)

Set-StrictMode -Version Latest

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$fullTfDir = Join-Path $scriptRoot $TfDir

if (-not (Test-Path $fullTfDir)) {
    Write-Error "Terraform directory not found: $fullTfDir"
    exit 1
}

Push-Location $fullTfDir
try {
    Write-Host "Initializing Terraform in $fullTfDir..."
    terraform init -input=false | Write-Host

    if ($AutoApprove) {
        Write-Host "Applying Terraform (auto-approve)..."
        terraform apply -auto-approve | Write-Host
    }
    else {
        Write-Host "Showing plan (no auto-approve). Review and confirm apply if desired."
        terraform plan -out tfplan | Write-Host
        $apply = Read-Host "Run 'terraform apply tfplan'? (y/N)"
        if ($apply -eq 'y' -or $apply -eq 'Y') {
            terraform apply tfplan | Write-Host
        }
        else {
            Write-Host "Skipping apply. Inventory will not be generated until apply is run."
            Pop-Location
            exit 0
        }
    }
}
catch {
    Write-Error "Terraform failed: $_"
    Pop-Location
    exit 2
}
finally {
    Pop-Location
}

# Determine Python executable: prefer .venv in repo if present, otherwise rely on PATH
$venvPython = Join-Path $scriptRoot ".venv\Scripts\python.exe"
if (Test-Path $venvPython) {
    $python = $venvPython
}
else {
    $python = "python"
}

$genScript = Join-Path $scriptRoot "scripts\generate_inventory.py"
if (-not (Test-Path $genScript)) {
    Write-Error "Inventory generator not found: $genScript"
    exit 3
}

Write-Host "Generating Ansible inventory from Terraform outputs..."
& $python $genScript --tfdir $fullTfDir --out (Join-Path $scriptRoot "ansible\inventory.tf.ini")

Write-Host "Inventory generation complete. You can now run:"
Write-Host "    ansible-playbook -i ansible/inventory.tf.ini ansible/site.yml"

exit 0
