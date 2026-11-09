    @echo off
setlocal
cd /d "%~dp0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-local.ps1"
if errorlevel 1 (
    echo.
    echo Supermarket could not start. Check the messages above.
    pause
    exit /b 1
)
start "" "http://127.0.0.1:8088/supermarket/"
