[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Original','Memoria')][string]$Variante,
    [ValidatePattern('^[1-9][0-9]{0,3}x[1-9][0-9]{0,3}$')][string]$Ventana,
    [string]$GameExe,
    [switch]$DesdeGuardado,
    [switch]$Manual,
    [switch]$SerieS,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
# A BAT started from PowerShell 7 may pass its module paths to Windows PowerShell.
$env:PSModulePath = "$PSHOME\Modules;$env:PSModulePath"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$dataRoot = Join-Path (Split-Path $root -Parent) ((Split-Path $root -Leaf) + '-datos')
$original = $Variante -eq 'Original'
if ($SerieS -and $original) { throw 'La prueba original requiere Series X.' }
$profile = if ($SerieS) { 'series-s' } else { 'series-x' }
if (!$Ventana) { $Ventana = if ($original) { '960x540' } else { '800x450' } }
$name = if ($original) { '01-original' } elseif ($SerieS) { '02-memoria' } else { '02-memoria-x' }
$homeTest = Join-Path $dataRoot "pruebas\$name"
$binary = Join-Path $root 'target\diag\victory.exe'
$frozen = Join-Path $homeTest 'bin\victory.exe'
if ($original -and (Test-Path -LiteralPath $frozen)) {
    $binary = $frozen
    if ((Get-FileHash -LiteralPath $binary).Hash -ne '128364546DAE4F156600B8075A358495494FD33D041B2B279F0153C9E8F17384') {
        throw 'La copia congelada de la prueba 01 cambio. Verifica su SHA-256.'
    }
}
if (!(Test-Path -LiteralPath $binary -PathType Leaf)) { throw 'Falta compilar el port. Ejecuta scripts\windows\Compilar-VIctory.ps1.' }
$remember = Join-Path $dataRoot 'ejecutable.txt'
if (!$GameExe -and (Test-Path -LiteralPath $remember)) { $GameExe = (Get-Content -LiteralPath $remember -Raw).Trim() }
if (!$GameExe) { $GameExe = Read-Host 'Ruta completa del .exe del juego' }
$game = (Get-Item -LiteralPath $GameExe.Trim().Trim('"') -ErrorAction Stop).FullName
$gameDir = Split-Path $game -Parent
foreach ($required in @('movies.rpf','shaders.rpf','appdata0.rpf')) {
    if (!(Test-Path -LiteralPath (Join-Path $gameDir $required) -PathType Leaf)) { throw "Falta $required junto al juego." }
}
$seed = Join-Path $homeTest 'guardado-vice-city'
if ($DesdeGuardado -and !(Test-Path -LiteralPath $seed -PathType Container)) { throw 'Falta la copia local guardado-vice-city.' }
Write-Host "Prueba $name | $profile | ventana $Ventana"
Write-Host "Motor: $binary"
if ($CheckOnly) { & $binary --version; exit $LASTEXITCODE }

$session = Join-Path $homeTest ('sesiones\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + $PID)
New-Item -Path $session -ItemType Directory -Force | Out-Null
# Each BAT runs in its own PowerShell process. Ignore switches from older experiments.
Get-ChildItem Env:VICTORY_* | ForEach-Object { Remove-Item -LiteralPath ('Env:' + $_.Name) }
$env:VICTORY_CONFIG = Join-Path $session 'config.toml'
Set-Content -LiteralPath $env:VICTORY_CONFIG -Value '[paths]' -Encoding ASCII
$env:VICTORY_GAME_DIR = $gameDir
$env:VICTORY_WINDOW_MAX = $Ventana
$env:VICTORY_DATA_DIR = Join-Path $session 'data'
if ($DesdeGuardado) { Copy-Item -LiteralPath $seed -Destination $env:VICTORY_DATA_DIR -Recurse }
$env:VICTORY_LOG = 'info'
$env:VICTORY_D3D12_DEBUG = '0'
$env:VICTORY_D3D12_WARP = '0'
if ($original) {
    $env:VICTORY_CACHE_DIR = Join-Path $session 'cache'
    $cacheSeed = Join-Path $homeTest 'cache-inicial'
    if (Test-Path -LiteralPath $cacheSeed) { Copy-Item -LiteralPath $cacheSeed -Destination $env:VICTORY_CACHE_DIR -Recurse }
    $env:VICTORY_LOG = 'info,victory_hle::modules::gameinput=debug'
    $env:VICTORY_CAPTURE = Join-Path $session 'frames'
    $env:VICTORY_CAPTURE_FRAMES = (1..200 | ForEach-Object { $_ * 12 }) -join ','
    $env:VICTORY_AUDIO_CAPTURE = Join-Path $session 'audio.wav'
} else {
    $env:VICTORY_CACHE_DIR = Join-Path $homeTest 'cache'
    $env:VICTORY_DISABLE_FRAME_PROBE = '1'
}
if (!$Manual -and !$DesdeGuardado) {
    $env:VICTORY_KEYS = '43:Enter'
    Write-Host 'Se enviara un solo Enter a los 43 s desde el inicio de la entrada.'
}
Write-Host "Registros: $session"
Write-Host 'En el selector de perfil, Enter = A. Cierra la ventana del juego con Alt+F4.'
$out = Join-Path $session 'stdout.txt'
$err = Join-Path $session 'stderr.txt'
$process = Start-Process -FilePath $binary -WorkingDirectory $root -NoNewWindow -PassThru `
    -ArgumentList @('run', ('"' + $game + '"'), '--execute', '--console', $profile) `
    -RedirectStandardOutput $out -RedirectStandardError $err
$null = $process.Handle
Write-Host "PID del juego: $($process.Id)"
# Read incrementally. The child writes directly to disk even if the terminal falls behind.
$readers = @()
try {
    foreach ($path in @($out,$err)) {
        $stream = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        $readers += [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8)
    }
    do {
        $finished = $process.HasExited
        foreach ($reader in $readers) {
            $chunk = $reader.ReadToEnd()
            if ($chunk) { [Console]::Write($chunk) }
        }
        if (!$finished) { Start-Sleep -Milliseconds 300 }
    } while (!$finished)
    $process.WaitForExit()
    $code = $process.ExitCode
    Write-Host "Salida: $code | Registros: $session"
    exit $code
} finally {
    foreach ($reader in $readers) { $reader.Dispose() }
    $process.Dispose()
}
