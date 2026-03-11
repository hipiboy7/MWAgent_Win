@echo off
setlocal
cd /d %~dp0

:: MWAgent Restart Trigger Script
:: Usage: run.agent.bat [new_jar_file]
:: Uses WMIC to spawn independent restart process
:: (schtasks /RU SYSTEM requires elevated privileges, which is unavailable
::  when called from MWAgent service running as non-elevated jeus account)

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

:: Spawn restart.bat as an independent process using WMIC
:: WMIC creates a process detached from the parent, so it survives service stop
wmic process call create "cmd.exe /c %~dp0restart.bat" > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] WMIC failed, trying PowerShell fallback...
    set NOW=%date% %time%
    echo [%NOW%] [TRIGGER] WMIC failed, trying PowerShell fallback. >> %LOG_FILE%
    powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c %~dp0restart.bat' -WindowStyle Hidden" > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] All methods failed to launch restart.bat.
        set NOW=%date% %time%
        echo [%NOW%] [ERROR] [TRIGGER] All launch methods failed. >> %LOG_FILE%
        exit /b 1
    )
)

echo [INFO] Restart process launched.
set NOW=%date% %time%
echo [%NOW%] [TRIGGER] Restart process launched via WMIC. >> %LOG_FILE%

endlocal
