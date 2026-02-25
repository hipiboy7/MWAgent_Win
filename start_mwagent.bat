@echo off
setlocal

:: -----------------------------------------------------------------------------
:: MWAgent Start Script (디버깅 전용)
:: - 이 스크립트는 서비스 없이 콘솔에서 직접 실행할 때만 사용합니다.
:: - 운영 환경에서는 Windows 서비스(net start MWAgent)를 사용하세요.
:: -----------------------------------------------------------------------------

:: 1. 환경 변수 설정 (mwagent-service.xml 설정 반영)
:: 실제 배포 환경에 맞게 USER, HOSTNAME 등을 수정하세요.
if "%USER%"=="" set USER=SYSADMIN
if "%HOSTNAME%"=="" set HOSTNAME=WIN-RVA6N8ACU27
set DOMAIN_NAME=SCP_WINDOW

echo [INFO] Environment Variables:
echo   USER        = %USER%
echo   HOSTNAME    = %HOSTNAME%
echo   DOMAIN_NAME = %DOMAIN_NAME%

:: 2. Java 실행 설정
set JAVA_OPTS=-Djava.util.logging.config.file=log/logging.properties -Xms256m -Xmx256m
set CLASSPATH=.;lib/*;mwagent.jar
set MAIN_CLASS=mwagent.MwAgent
set AGENT_NAME=mwagent.%USER%

:: 3. 실행 (콘솔 모드)
echo.
echo [INFO] Starting MWAgent...
echo [CMD] java -cp "%CLASSPATH%" -Dname=%AGENT_NAME% %JAVA_OPTS% %MAIN_CLASS%
echo.


:: -----------------------------------------------------------------------------
:: Logging Setup
:: -----------------------------------------------------------------------------
if not exist "log" mkdir "log"
set LOG_FILE=log\script_history.log
set CUR_DATE=%date% %time%
echo [%CUR_DATE%] [INFO] [START] Attempting to start MWAgent... >> %LOG_FILE%

java -cp "%CLASSPATH%" -Dname=%AGENT_NAME% %JAVA_OPTS% %MAIN_CLASS%
if %ERRORLEVEL% EQU 0 (
    echo [%date% %time%] [INFO] [START] MWAgent started successfully. >> %LOG_FILE%
) else (
    echo [%date% %time%] [ERROR] [START] Failed to start MWAgent. Error Level: %ERRORLEVEL% >> %LOG_FILE%
)

endlocal
