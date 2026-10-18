@echo off
setlocal

:: Détection automatique d'un exécutable Godot disponible (priorité à la version console pour voir les erreurs et logs en direct)
set "GODOT_BIN=C:\Users\Maxence\Desktop\repositories\godot_cli\Godot_v4.3-stable_win64_console.exe"

if not exist "%GODOT_BIN%" (
    set "GODOT_BIN=C:\Users\Maxence\Desktop\repositories\godot_cli\Godot_v4.3-stable_win64.exe"
)

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

echo ===================================================
echo   Lancement de Flip (Mode Console Debug Actif)
echo   Exécutable : %GODOT_BIN%
echo ===================================================
"%GODOT_BIN%" --path "%~dp0." %*

if %errorlevel% neq 0 (
    echo.
    echo [ERREUR CRITIQUE] Le jeu s'est arrêté avec le code %errorlevel%.
    pause
)
