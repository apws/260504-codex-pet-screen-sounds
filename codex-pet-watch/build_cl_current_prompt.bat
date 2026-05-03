@echo off
setlocal
if not exist build mkdir build
cl /nologo /EHsc /std:c++17 /W4 /DUNICODE /D_UNICODE /DWIN32_LEAN_AND_MEAN /DNOMINMAX /D_WIN32_WINNT=0x0A00 src\main.cpp /Fe:build\codex_pet_watch.exe user32.lib gdi32.lib winmm.lib shcore.lib
