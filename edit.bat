@echo off
setlocal

set "GODOT_BIN=C:\Users\Maxence\Desktop\repositories\godot_cli\Godot_v4.3-stable_win64.exe"

if not exist "%GODOT_BIN%" (
    set "GODOT_BIN=C:\Users\Maxence\Downloads\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe"
)

if not exist "%GODOT_BIN%" (
    where godot >nul 2>&1
    if %errorlevel% equ 0 (
        set "GODOT_BIN=godot"
    ) else (
        echo [ERREUR] Aucun exécutable Godot trouvé.
        pause
        exit /b 1
    )
)

echo Ouverture de Flip dans l'editeur Godot...
start "" "%GODOT_BIN%" -e --path "%~dp0." %*
