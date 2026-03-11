@echo off
setlocal EnableDelayedExpansion
cd /d %~dp0

:: MWAgent Service Restart Script
:: Auto-elevation to Administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Requesting administrative privileges...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)
:: End of Auto-elevation

if not exist "log" mkdir "log"
set LOG_FILE=log\script_history.log
set NOW=%date% %time%

echo [INFO] Restarting MWAgent Service...
echo [%NOW%] [INFO] [RESTART] Service restart initiated. >> %LOG_FILE%

:: 1. Get service PID before stopping
set SERVICE_PID=
for /f "tokens=3" %%a in ('sc queryex MWAgent ^| find "PID"') do set SERVICE_PID=%%a
echo [INFO] MWAgent service PID: %SERVICE_PID%
set NOW=%date% %time%
echo [%NOW%] [INFO] [RESTART] Service PID: %SERVICE_PID% >> %LOG_FILE%

:: 2. Send stop signal (non-blocking) then force kill by PID
echo [INFO] Sending stop signal...
start /b sc stop MWAgent
ping 127.0.0.1 -n 4 > nul

:: 3. Force kill java.exe by PID
if defined SERVICE_PID (
    echo [INFO] Force killing PID %SERVICE_PID%...
    taskkill /F /PID %SERVICE_PID% > nul 2>&1
    ping 127.0.0.1 -n 3 > nul
    set NOW=%date% %time%
    echo [!NOW!] [INFO] [RESTART] PID %SERVICE_PID% terminated. >> %LOG_FILE%
)
set NOW=%date% %time%
echo [%NOW%] [INFO] [RESTART] Service stopped. >> %LOG_FILE%

:: 4. JAR update (if new_mwagent.jar exists)
if exist "new_mwagent.jar" (
    echo [INFO] New JAR detected. Updating...
    set CUR_YYYY=%date:~0,4%
    set CUR_MM=%date:~5,2%
    set CUR_DD=%date:~8,2%
    set CUR_HH=%time:~0,2%
    set CUR_HH=!CUR_HH: =0!
    set CUR_MIN=%time:~3,2%
    set CUR_SS=%time:~6,2%
    set BACKUP_NAME=mwagent.jar.bak_!CUR_YYYY!!CUR_MM!!CUR_DD!_!CUR_HH!!CUR_MIN!!CUR_SS!
    if exist "mwagent.jar" (
        copy "mwagent.jar" "!BACKUP_NAME!" > nul
        set NOW=%date% %time%
        echo [!NOW!] [INFO] [RESTART] Backed up to !BACKUP_NAME! >> %LOG_FILE%
    )
    copy /Y "new_mwagent.jar" "mwagent.jar" > nul
    del "new_mwagent.jar"
    set NOW=%date% %time%
    echo [!NOW!] [INFO] [RESTART] JAR updated. >> %LOG_FILE%
) else (
    echo [INFO] No JAR update. Restarting service only.
    set NOW=%date% %time%
    echo [!NOW!] [INFO] [RESTART] No JAR update. Restart only. >> %LOG_FILE%
)

:: 5. Start service
echo [INFO] Starting MWAgent Service...
net start MWAgent

set NOW=%date% %time%
if %ERRORLEVEL% EQU 0 (
    echo [%NOW%] [INFO] [RESTART] Service restarted successfully. >> %LOG_FILE%
) else (
    echo [%NOW%] [ERROR] [RESTART] Service restart failed. >> %LOG_FILE%
)

:: 6. Cleanup scheduled task
schtasks /Delete /TN "MWAgentRestart" /F > nul 2>&1

endlocal
