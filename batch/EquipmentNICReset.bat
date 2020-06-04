@echo off

set NIC_IP=<YOUR NETWORK INTERFACE CARD IP>
set EQUIPMENT_IP=<YOUR EQUIPMENT IP>
set EQUIPMENT_POWER_ON=<YOUR EQUIPMENT POWER ON SCRIPT/COMMAND>
set EQUIPMENT_REBOOT=<YOUR EQUIPMENT REBOOT SCRIPT/COMMAND>

echo.
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ++++ Checking Equipment, resetting network interface as needed
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

ping -n 1 %EQUIPMENT_IP% >nul: 2>nul:
if not %errorlevel%==0 (
@echo [INFO] Equipment is getting a ping timeout, will try to reset its network adapter.
goto :reset_nic
)
echo [INFO] Equipment is good to go.
goto :end

:reset_nic
setlocal
setlocal enabledelayedexpansion
set "_adapter="
set "_ip="
for /f "tokens=1* delims=:" %%g in ('ipconfig /all') do (
  set "_tmp=%%~g"
  if "!_tmp:adapter=!"=="!_tmp!" (
    if not "!_tmp:IPv4 Address=!"=="!_tmp!" (
      for %%i in (%%~h) do (
      if not "%%~i"=="" set "_ip=%%~i"
      )
    set "_ip=!_ip:(Preferred)=!"
    if "!_ip!"=="%NIC_IP%" (
        @echo [INFO] Resetting network interface: !_adapter!
        netsh interface set interface "!_adapter!" disable
        ping -n 20 127.1>nul
        netsh interface set interface "!_adapter!" enable
        ping -n 20 127.1>nul
        echo [INFO] Done resetting network interface: !_adapter!
      )
    )
  ) else (
    set "_ip="
    set "_adapter=!_tmp:*adapter =!"
  )
)

endlocal

ping -n 1 %EQUIPMENT_IP% >nul: 2>nul:
if not %errorlevel%==0 (
goto :power_on
)
echo [INFO] Equipment is now good to go.
goto :end

:power_on
cd /d D:\CI\CI_TOOL\
if exist %EQUIPMENT_POWER_ON% (
echo [INFO] Equipment might be powered-off, powering it on...
%EQUIPMENT_POWER_ON%
goto :final_verify
)
if exist %EQUIPMENT_REBOOT% (
%EQUIPMENT_REBOOT%
ping -n 30 127.1>nul
goto :final_verify
)
echo [FATAL] %EQUIPMENT_REBOOT% script is missing!
echo [FATAL] Testing process will fail without this script.
exit 1

:final_verify
ping -n 1 %EQUIPMENT_IP% >nul: 2>nul:
if "%errorlevel%"=="0" (
echo [INFO] Equipment is now up. Proceeding...
goto :end
)
echo [FATAL] Equipment is unreachable even after resetting the network interface and rebooting it on.
echo [FATAL] This needs to be raised to lab support.
exit 1

:end
exit