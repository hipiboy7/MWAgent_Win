@echo off
setlocal
cd /d %~dp0

:: MWAgent Restart Trigger Script
:: Usage: run.agent.bat [new_jar_file]
:: NOTE: Must be run as Administrator (for schtasks /RU SYSTEM)

if not exist "log" mkdir "log"
set LOG_FILE=log\script_history.log

:: Capture timestamp BEFORE if-block to avoid parse-time expansion issues
set NOW=%date% %time%

if "%~1"=="" (
    echo [INFO] Restart only.
    echo [%NOW%] [TRIGGER] Restart triggered. >> %LOG_FILE%
    if exist "new_mwagent.jar" del "new_mwagent.jar"
) else (
    if not exist "%~1" (
        echo [ERROR] File not found: %~1
        exit /b 1
    )
    copy /Y "%~1" "new_mwagent.jar" > nul
    echo [%NOW%] [TRIGGER] Staged: %~1 >> %LOG_FILE%
)

:: Delete existing task
schtasks /Delete /TN "MWAgentRestart" /F > nul 2>&1

:: Create task as SYSTEM (has service control privileges)
schtasks /Create /TN "MWAgentRestart" /TR "%~dp0restart.bat" /SC ONCE /ST 00:00 /SD 01/01/2000 /RU SYSTEM /F > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to create task. Run as Administrator.
    exit /b 1
)

schtasks /Run /TN "MWAgentRestart" > nul 2>&1
echo [INFO] Restart task triggered.
set NOW=%date% %time%
echo [%NOW%] [TRIGGER] Task registered and triggered. >> %LOG_FILE%

endlocal
