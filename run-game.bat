@echo off
setlocal

set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.1-stable_win64.exe"

if not exist "%GODOT_EXE%" (
  echo Godot executable not found.
  echo Install Godot first, or update run-game.bat with your Godot path.
  pause
  exit /b 1
)

start "" "%GODOT_EXE%" --path "%~dp0"
