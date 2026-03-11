@echo off
setlocal
cd /d %~dp0

:: MWAgent Restart Trigger Script
:: Usage: run.agent.bat [new_jar_file]
:: NOTE: Must be run as Administrator (for schtasks /RU SYSTEM)

if not exist "log" mkdir "log"
set LOG_FILE=log\script_history.log

echo ============================================
echo [DEBUG] MWAgent Restart Trigger - Diagnostics
echo ============================================

:: [STEP 1] 실행 환경 정보 출력
echo.
echo [STEP 1] Execution Environment
echo   Working Dir : %cd%
echo   Script Path : %~dp0
echo   Username    : %USERNAME%
echo   UserDomain  : %USERDOMAIN%
whoami
echo.

:: [STEP 2] 파라미터 확인 및 JAR 스테이징
set NOW=%date% %time%
echo [STEP 2] Parameter Check (NOW=%NOW%)
if "%~1"=="" (
    echo   [INFO] No parameter - Restart only.
    echo [%NOW%] [TRIGGER] Restart triggered. >> %LOG_FILE%
    if exist "new_mwagent.jar" del "new_mwagent.jar"
) else (
    echo   [INFO] Parameter received: %~1
    if not exist "%~1" (
        echo   [ERROR] File not found: %~1
        exit /b 1
    )
    copy /Y "%~1" "new_mwagent.jar" > nul
    echo   [OK] Copied to new_mwagent.jar
    echo [%NOW%] [TRIGGER] Staged: %~1 >> %LOG_FILE%
)
echo.

:: [STEP 3] 기존 예약 작업 삭제
echo [STEP 3] Delete existing scheduled task...
schtasks /Delete /TN "MWAgentRestart" /F > nul 2>&1
echo   ERRORLEVEL = %ERRORLEVEL% (0=deleted, 1=not found, both OK)
echo.

:: [STEP 4] 예약 작업 생성 (SYSTEM 권한)
echo [STEP 4] Create scheduled task as SYSTEM...
echo   Command: schtasks /Create /TN "MWAgentRestart" /TR "%~dp0restart.bat" /SC ONCE /ST 00:00 /SD 01/01/2000 /RU SYSTEM /F
schtasks /Create /TN "MWAgentRestart" /TR "%~dp0restart.bat" /SC ONCE /ST 00:00 /SD 01/01/2000 /RU SYSTEM /F
echo   ERRORLEVEL = %ERRORLEVEL%
if %ERRORLEVEL% NEQ 0 (
    echo   [FAIL] Task creation failed!
    echo.
    echo   --- Possible Causes ---
    echo   1. Security policy blocks /RU SYSTEM
    echo   2. Not running as Administrator
    echo   3. Task Scheduler service not running
    echo.
    echo   --- Checking Task Scheduler service ---
    sc query Schedule | find "STATE"
    echo   -----------------------------------
    exit /b 1
)
echo   [OK] Task created successfully.
echo.

:: [STEP 5] 예약 작업 실행
echo [STEP 5] Run scheduled task...
schtasks /Run /TN "MWAgentRestart"
echo   ERRORLEVEL = %ERRORLEVEL%
if %ERRORLEVEL% NEQ 0 (
    echo   [FAIL] Task run failed!
    exit /b 1
)
echo   [OK] Task triggered successfully.
echo.

echo ============================================
echo [RESULT] All steps completed successfully.
echo ============================================
set NOW=%date% %time%
echo [%NOW%] [TRIGGER] Task registered and triggered. >> %LOG_FILE%

endlocal
