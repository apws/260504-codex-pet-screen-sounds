@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0tools\build.ps1" %*
