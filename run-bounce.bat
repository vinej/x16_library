@echo off
rem Double-click me. Assembles and runs examples\bounce.asm.
rem
rem Bouncing sprite with a PSG blip on each wall hit and an FM note while
rem it overlaps the target box. Press any key in the emulator to stop.
call "%~dp0run.bat" bounce %*
