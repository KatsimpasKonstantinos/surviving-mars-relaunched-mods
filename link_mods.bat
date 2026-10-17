@echo off
setlocal

:: Automatically gets the folder where this script is located + "Mods Konsti"
set "REPO_MODS=%~dp0Mods Konsti"

:: Automatically gets the current Windows user's AppData\Roaming folder
set "GAME_MODS=%AppData%\Surviving Mars Relaunched\Mods"

echo Source Repo : "%REPO_MODS%"
echo Game Folder : "%GAME_MODS%"
echo.

:: Check if "Mods Konsti" exists next to the script
if not exist "%REPO_MODS%" (
    echo [ERROR] Could not find folder: "%REPO_MODS%"
    echo Make sure link_mods.bat is in the root of the repository.
    pause
    exit /b 1
)

:: Create the game's Mods folder if the user hasn't created one yet
if not exist "%GAME_MODS%" (
    echo Game Mods folder not found. Creating "%GAME_MODS%"...
    mkdir "%GAME_MODS%"
)

:: Loop through every mod folder and create a junction
for /d %%D in ("%REPO_MODS%\*") do (
    if not exist "%GAME_MODS%\%%~nxD" (
        mklink /J "%GAME_MODS%\%%~nxD" "%%~fD"
    ) else (
        echo Already exists in game folder: %%~nxD
    )
)

echo.
echo All mods linked successfully!
pause