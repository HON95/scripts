REM Warning:
REM If hibernate is active, this will put the PC into hibernate instead.
REM Disable hibernate (as admin): powercfg -hibernate off

@echo off

%windir%\System32\rundll32.exe powrprof.dll,SetSuspendState 0,1,0
