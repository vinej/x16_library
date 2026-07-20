@echo off
rem Double-click me. Assembles and runs examples\polyspin.asm.
rem
rem A filled polygon spinning in place, to show the rotation argument in
rem motion. Press any key in the emulator to stop.
call "%~dp0run.bat" polyspin %*
