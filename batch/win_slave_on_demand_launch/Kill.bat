@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

FOR /F "TOKENS=2 DELIMS=," %%F IN ('TASKLIST /nh /fi "WindowTitle eq Jenkins *" /V /fo csv') do set PID=%%F

echo %PID%

IF NOT "%PID%" == "" taskkill /PID %PID% /T

taskkill /F /IM javaw.exe