@echo off
REM Smart Expiry - double-click to start the app in your browser.
REM Keep the black window open while you use the app; close it to stop.
cd /d "%~dp0"

where py >nul 2>nul && (py serve.py 5500 & goto :eof)
where python >nul 2>nul && (python serve.py 5500 & goto :eof)
where npx >nul 2>nul && (start "" http://localhost:5500/ & npx --yes serve -l 5500 . & goto :eof)

echo.
echo   Could not find Python or Node.js on this computer.
echo   Install Python from https://www.python.org/downloads/ (tick "Add python.exe to PATH"),
echo   or open this folder in VS Code and use the "Live Server" extension.
echo.
pause
