@echo off
rem Double-click me. Assembles and runs examples\numbers.asm.
rem
rem A tour of the number libraries: 16-bit integers, 32-bit integers,
rem 8.8 fixed point, and floating point. Each line prints an expression
rem and its result.
call "%~dp0run.bat" numbers %*
