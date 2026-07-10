@echo off
setlocal
rem ---------------------------------------------------------------------
rem x16lib :: test.bat -- run the headless regression suite
rem
rem Thin wrapper over build_acme.ps1 -Test, which assembles test\runner.asm,
rem runs it under x16emu -testbench, and fails on any FAIL, on a pass
rem count that disagrees with the program's own total, or on a run that
rem never reports DONE.
rem ---------------------------------------------------------------------
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "build_acme.ps1" -Test
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo TESTS PASSED
    exit /b 0
)

rem Pause only on failure, so a double-clicked run leaves the error on
rem screen while a scripted one returns straight to the caller.
echo TESTS FAILED  ^(exit %RC%^)
echo.
pause
exit /b %RC%
