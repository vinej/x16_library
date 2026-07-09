@echo off
setlocal
rem ---------------------------------------------------------------------
rem x16lib :: run.bat -- assemble an example and run it in the emulator
rem
rem   run.bat                 assembles and runs examples\hello.asm
rem   run.bat bounce          assembles and runs examples\bounce.asm
rem   run.bat bounce 3        ...at window scale 3
rem
rem Runs windowed, WITHOUT -testbench: that mode is headless and raises
rem no VSYNC interrupt, so anything calling vsync_wait would hang there.
rem ---------------------------------------------------------------------

rem Work from the repo root, wherever this file was launched from.
cd /d "%~dp0"

set "NAME=%~1"
if "%NAME%"=="" set "NAME=hello"

set "SCALE=%~2"
if "%SCALE%"=="" set "SCALE=2"

set "ACME=acme\acme.exe"
set "EMU=emulator\x16emu.exe"
set "ROM=emulator\rom.bin"
set "SRC=examples\%NAME%.asm"
set "PRG=build\%NAME%.prg"

if not exist "%ACME%" echo ERROR: %ACME% not found. See README.md, "Prerequisites". & goto fail
if not exist "%EMU%"  echo ERROR: %EMU% not found. See README.md, "Prerequisites."  & goto fail
if not exist "%ROM%"  echo ERROR: %ROM% not found. See README.md, "Prerequisites."  & goto fail
if not exist "%SRC%"  goto no_source

if not exist build mkdir build

echo acme   %SRC% -^> %PRG%
"%ACME%" -I src -f cbm -o "%PRG%" "%SRC%"
if errorlevel 1 echo ERROR: assembly failed. & goto fail

echo x16emu %PRG%   (close the emulator window to stop)
"%EMU%" -rom "%ROM%" -prg "%PRG%" -run -scale %SCALE%
exit /b 0

:no_source
echo ERROR: %SRC% not found.
echo.
echo Available examples:
for %%F in (examples\*.asm) do echo     run.bat %%~nF
goto fail

:fail
echo.
pause
exit /b 1
