@echo off
setlocal
if not exist build mkdir build
rc /nologo /fo build\resources.res resources.rc
if errorlevel 1 exit /b %errorlevel%
cl /nologo /EHsc /std:c++17 /W4 /DUNICODE /D_UNICODE /DWIN32_LEAN_AND_MEAN /DNOMINMAX /D_WIN32_WINNT=0x0A00 src\main.cpp build\resources.res /Fe:build\codex_pet_watch.exe /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib winmm.lib shcore.lib shell32.lib
if errorlevel 1 exit /b %errorlevel%
