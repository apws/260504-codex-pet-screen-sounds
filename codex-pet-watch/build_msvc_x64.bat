@echo off
setlocal
cmake -S . -B build-x64 -A x64
if errorlevel 1 exit /b %errorlevel%
cmake --build build-x64 --config Release
