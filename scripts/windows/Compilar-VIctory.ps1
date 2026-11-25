[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$portCargo = Join-Path $env:USERPROFILE '.cargo\bin\cargo.exe'
if (-not (Test-Path -LiteralPath $portCargo)) { throw 'No se encuentra Rust/Cargo.' }
$env:PATH = (Split-Path -Parent $portCargo) + ';' + $env:PATH
Push-Location ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')))
try {
    & $portCargo build --profile diag -p victory --features diagnostics --locked
    if ($LASTEXITCODE -ne 0) { throw 'La compilacion de VIctory fallo.' }
} finally {
    Pop-Location
}
