$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "ISLA de Datos Urbanos 2025-2026 - Instalador Windows" -ForegroundColor Cyan
Write-Host ""

function Test-Command {
    param ([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

if (-not (Test-Command "docker")) {
    Write-Host "ERROR: Docker no esta instalado o no esta en PATH." -ForegroundColor Red
    Write-Host "Instala Docker Desktop y vuelve a ejecutar este instalador."
    exit 1
}

try {
    docker compose version | Out-Null
} catch {
    Write-Host "ERROR: Docker Compose v2 no esta disponible." -ForegroundColor Red
    Write-Host "Asegurate de tener Docker Desktop actualizado y abierto."
    exit 1
}

try {
    docker info | Out-Null
} catch {
    Write-Host "ERROR: Docker no esta corriendo." -ForegroundColor Red
    Write-Host "Abre Docker Desktop y vuelve a ejecutar este instalador."
    exit 1
}

$DefaultInstallDir = "C:\ISLA"
$InstallDir = Read-Host "Directorio de instalacion [$DefaultInstallDir]"

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = $DefaultInstallDir
}

$RepoZip = "https://github.com/ROKOPM/isla-installer/archive/refs/heads/main.zip"
$ZipPath = Join-Path $env:TEMP "isla-installer.zip"
$ExtractRoot = Join-Path $env:TEMP "isla-installer-main"

Write-Host ""
Write-Host "Descargando instalador publico..." -ForegroundColor Yellow

if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Invoke-WebRequest -Uri $RepoZip -OutFile $ZipPath

if (Test-Path $ExtractRoot) {
    Remove-Item $ExtractRoot -Recurse -Force
}

Expand-Archive -Path $ZipPath -DestinationPath $env:TEMP -Force

if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

Write-Host "Copiando archivos a $InstallDir..." -ForegroundColor Yellow
Copy-Item "$ExtractRoot\*" $InstallDir -Recurse -Force

Set-Location $InstallDir

if (!(Test-Path ".env")) {
    if (!(Test-Path ".env.template")) {
        Write-Host "ERROR: No se encontro .env.template." -ForegroundColor Red
        exit 1
    }

    Copy-Item ".env.template" ".env"

    Write-Host ""
    Write-Host "Configuracion Davis WeatherLink" -ForegroundColor Cyan
    $DavisKey = Read-Host "Davis API key"
    $DavisSecret = Read-Host "Davis API secret"
    $DavisStation = Read-Host "Davis station ID"

    $EnvContent = Get-Content ".env"

    $EnvContent = $EnvContent `
        -replace "^DAVIS_API_KEY=.*", "DAVIS_API_KEY=$DavisKey" `
        -replace "^DAVIS_API_SECRET=.*", "DAVIS_API_SECRET=$DavisSecret" `
        -replace "^DAVIS_STATION_ID=.*", "DAVIS_STATION_ID=$DavisStation"

    $EnvContent | Set-Content ".env"
} else {
    Write-Host "Se encontro .env existente. No se sobrescribira." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Descargando imagenes Docker..." -ForegroundColor Yellow
docker compose pull

Write-Host ""
Write-Host "Levantando servicios..." -ForegroundColor Yellow
docker compose up -d

Write-Host ""
Write-Host "ISLA de Datos Urbanos esta levantando." -ForegroundColor Green
Write-Host "Abre: http://localhost" -ForegroundColor Cyan
Write-Host ""
Write-Host "Comandos utiles:" -ForegroundColor Cyan
Write-Host "  cd $InstallDir"
Write-Host "  docker compose ps"
Write-Host "  docker compose logs -f nginx"
Write-Host "  docker compose logs -f django"
Write-Host "  docker compose down"
Write-Host ""
