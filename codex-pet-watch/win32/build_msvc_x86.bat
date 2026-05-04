@echo off
setlocal
cmake -S . -B build-x86 -A Win32
if errorlevel 1 exit /b %errorlevel%
cmake --build build-x86 --config Release
