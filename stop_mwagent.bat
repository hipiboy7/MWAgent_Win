@echo off
setlocal

:: -----------------------------------------------------------------------------
:: MWAgent Stop Script (디버깅 전용)
:: - 이 스크립트는 서비스 없이 콘솔에서 직접 종료할 때만 사용합니다.
:: - 운영 환경에서는 Windows 서비스(net stop MWAgent)를 사용하세요.
:: -----------------------------------------------------------------------------

if "%USER%"=="" set USER=SYSADMIN
set AGENT_NAME=mwagent.%USER%

echo [INFO] Stopping MWAgent process (name: %AGENT_NAME%)...

:: Process 찾아서 종료 (WMIC 사용)
wmic process where "commandline like '%%-Dname=%AGENT_NAME%%%'" call terminate

if %ERRORLEVEL% EQU 0 (
    echo [INFO] MWAgent stopped successfully.
    echo [%date% %time%] [INFO] [STOP] MWAgent stopped successfully. >> log\script_history.log
) else (
    echo [WARN] Could not find running MWAgent process or failed to stop.
    echo [%date% %time%] [WARN] [STOP] Could not find running MWAgent process or failed to stop. >> log\script_history.log
)

endlocal
