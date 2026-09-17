@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-skills.ps1" %*
exit /b %ERRORLEVEL%
