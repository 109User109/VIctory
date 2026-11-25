[CmdletBinding()]
param(
    [string]$GameExe,
    [switch]$CheckOnly,
    [switch]$Software
)
$ErrorActionPreference = 'Stop'
$portRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$portBinary = Join-Path $portRoot 'target\diag\victory.exe'
$portData = Join-Path (Split-Path -Parent $portRoot) ((Split-Path -Leaf $portRoot) + '-datos')
$portRemember = Join-Path $portData 'ejecutable.txt'
if (-not (Test-Path -LiteralPath $portBinary -PathType Leaf)) {
    throw 'Falta compilar VIctory: no se encuentra target\diag\victory.exe.'
}
$env:VICTORY_CONFIG = Join-Path $portData 'launcher.toml'
$env:VICTORY_CACHE_DIR = Join-Path $portData 'cache'
$env:VICTORY_DATA_DIR = Join-Path $portData 'partidas'
$env:VICTORY_GAME_DIR = Join-Path $portData 'juego'
foreach ($portDirectory in @($portData, $env:VICTORY_CACHE_DIR, $env:VICTORY_DATA_DIR, $env:VICTORY_GAME_DIR)) {
    New-Item -ItemType Directory -Path $portDirectory -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $env:VICTORY_CONFIG)) {
    Set-Content -LiteralPath $env:VICTORY_CONFIG -Value '[paths]' -Encoding ASCII
}
$env:VICTORY_WINDOW_MAX = '1280x720'
$env:VICTORY_LOG = 'info'
$env:VICTORY_D3D12_WARP = if ($Software) { '1' } else { '0' }
if ($CheckOnly) {
    & $portBinary --version
    if ($LASTEXITCODE -ne 0) { throw 'Fallo al iniciar el ejecutable de VIctory.' }
    & $portBinary config
    if ($LASTEXITCODE -ne 0) { throw 'Configuracion invalida.' }
    Write-Host 'Herramienta comprobada. El video y los menus requieren los archivos del juego.'
    return
}
if (-not $GameExe -and (Test-Path -LiteralPath $portRemember)) {
    $GameExe = (Get-Content -LiteralPath $portRemember -Raw).Trim()
}
if (-not $GameExe) {
    Write-Host 'Pega la ruta completa del ejecutable del JUEGO, junto a sus recursos.'
    $GameExe = Read-Host 'Ruta del .exe'
}
$GameExe = $GameExe.Trim().Trim('"')
if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) {
    throw "No existe el ejecutable: $GameExe"
}
$GameExe = (Resolve-Path -LiteralPath $GameExe).Path
$portSource = $portRoot.TrimEnd('\') + '\'
if ($GameExe.StartsWith($portSource, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'El juego debe estar fuera del repositorio. Usa la carpeta hermana de datos u otra ubicacion.'
}
$env:VICTORY_GAME_DIR = Split-Path -Parent $GameExe
foreach ($portRequired in @('appdata0.rpf', 'shaders.rpf')) {
    if (-not (Test-Path -LiteralPath (Join-Path $env:VICTORY_GAME_DIR $portRequired))) {
        throw "Falta $portRequired junto al ejecutable. Revisa que el conjunto de archivos este completo."
    }
}
Set-Content -LiteralPath $portRemember -Value $GameExe -Encoding UTF8
$portLogs = Join-Path $portData 'logs'
New-Item -ItemType Directory -Path $portLogs -Force | Out-Null
$portLog = Join-Path $portLogs ('sesion-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
Start-Transcript -Path $portLog | Out-Null
try {
    Write-Host 'Objetivo: video inicial y menus. No seleccionar modo historia en esta prueba.'
    Write-Host 'Enter = A; Backspace = B; flechas = cruceta; Esc = Menu.'
    Write-Host 'La primera ejecucion puede tardar mientras traduce shaders.'
    Write-Host 'El limite de ventana 1280x720 solo ajusta el tamano visible.'
    & $portBinary run $GameExe --execute --console series-s
    $portExit = $LASTEXITCODE
    Write-Host "Codigo de salida: $portExit. Registro: $portLog"
    if ($portExit -ne 0) { throw "VIctory termino con codigo $portExit. Conservar el registro y crashes.log." }
} finally {
    Stop-Transcript | Out-Null
}
