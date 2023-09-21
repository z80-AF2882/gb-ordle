# This script is used to compile the entire project.

# User parameters
param (
    [string]$OutputFile = "GBordle.gb",
    [string]$SymFile = "GBordle.sym",
    [string]$OutputTitle = "GBORDLE",
    [string]$OutputMapFile = "GBordle.map",
    [string]$RGBDSHome = $PSScriptRoot + "\rgbds",    
    [string]$BGBHome = $PSScriptRoot + "\bgb",
    [switch]$Clean,
    [switch]$Run,
    [switch]$RunAndWait
)

# Settings
$RGBASM = "$RGBDSHome\rgbasm.exe"
$RGBLINK = "$RGBDSHome\rgblink.exe"
$RGBFIX = "$RGBDSHome\rgbfix.exe"
$PROJECT_DIR = (Split-Path -Path $PSScriptRoot -Parent)
$SRC_DIR = "$PROJECT_DIR\src"
$INC_DIR = "$PROJECT_DIR\inc"
$GFX_DIR = "$PROJECT_DIR\gfx"
$OUT_DIR = "$PROJECT_DIR\out"

# Check if RGBDS_HOME exists
if (-not (Test-Path $RGBDSHome)) {
    Write-Error "RGBDS_HOME directory $RGBDSHome does not exist. Please ensure the RGBDS tools are available in this directory." -ErrorAction Stop
}

# Check for individual tool existence
$tools = @('rgbasm.exe', 'rgblink.exe', 'rgbfix.exe')
foreach ($tool in $tools) {
    if (-not (Test-Path "$RGBDSHome\$tool")) {
        Write-Error "$tool not found in $RGBDSHome. Please download it from the web and place it into the RGBDS_HOME folder." -ErrorAction Stop
    }
}

# Ensure out folder exists
if (-not (Test-Path $OUT_DIR)) {
    New-Item -Path $OUT_DIR -ItemType Directory -ErrorAction Stop | Out-Null
}

# Clean out directory if files exist
Write-Host "Cleaning out directory $OUT_DIR"
Get-ChildItem -Path "$OUT_DIR\*" -Force | Remove-Item -Force -ErrorAction Stop

# Compile all from src
Write-Host "Compiling from $SRC_DIR to $OUT_DIR ..."
Get-ChildItem -Path "$SRC_DIR\*.asm" | ForEach-Object {
    Write-Output " ... $($_.Name)"
    # RGBASM
    & $RGBASM -Wall -Weverything -i "$INC_DIR\" -i "$GFX_DIR\" -o "$OUT_DIR\$($_.BaseName).o" "$SRC_DIR\$($_.Name)"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation failed for $($_.Name)" -ErrorAction Stop
        Exit -1
    }
}

# Link
$OBJ_PATTERN = "$OUT_DIR\*.o"
Write-Host "Linking $OBJ_PATTERN to $OutputFile ..."
$OBJ_FILES = (Get-ChildItem -Path $OBJ_PATTERN).FullName
$argumentList = @("-o", "$OUT_DIR\$OutputFile", "-map", "$OUT_DIR\$OutputMapFile", "-n", "$OUT_DIR\$SymFile") + $OBJ_FILES
Start-Process -FilePath $RGBLINK -ArgumentList $argumentList -NoNewWindow -Wait

if ($LASTEXITCODE -ne 0) {
    Write-Error "Linking failed" -ErrorAction Stop
    Exit -1
}

# Fix
& $RGBFIX -f hg "$OUT_DIR\$OutputFile"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Fixing failed" -ErrorAction Stop
    Exit -1
}

Write-Output "Successfully built $OutputFile"

if (-not ($Run -or $RunAndWait)) {
    Write-Output "Run with -Run or -RunAndWait switch"
    Exit 0    
}

# Run
$EMULATOR = "$BGBHome\bgb.exe"
if (-not (Test-Path $EMULATOR)) {
    Write-Error "Emulator $EMULATOR not found. Please download it from the web and place it into the bin folder." -ErrorAction Stop
}

Write-Output "Running $OutputFile"

$argumentList = @("$OUT_DIR\$OutputFile", "-t", "$OutputTitle", "-m", "$OUT_DIR\$OutputMapFile", "-l", "$OUT_DIR\$SymFile")
if ($RunAndWait) {
    Start-Process -FilePath $EMULATOR -ArgumentList $argumentList -NoNewWindow -Wait
} else {
    Start-Process -FilePath $EMULATOR -ArgumentList $argumentList -NoNewWindow
}

