# MWAgent 업데이트 가이드

## 1. 개요
본 문서는 MWAgent의 Jar 파일을 새로운 버전으로 업데이트하는 절차를 설명합니다.

## 2. 사전 준비
- 새로운 Jar 파일(예: `mwagent-0.9.19.jar`)을 `C:\Users\SYSADMIN\MWAgent` 폴더에 복사해 두어야 합니다.
- 현재 실행 중인 MWAgent가 있다면, 스크립트가 자동으로 중지시키므로 별도로 중지할 필요는 없습니다.

## 3. 업데이트 명령어
```cmd
cd C:\Users\SYSADMIN\MWAgent
run.agent.bat mwagent-0.9.19.jar
```
*(파일명은 실제 다운로드 받은 파일명으로 변경하여 입력하세요.)*

## 4. 스크립트 동작 과정
`run.agent.bat`는 다음 작업을 순차적으로 수행합니다:

1.  **JAR 스테이징**: 새 JAR 파일을 `new_mwagent.jar`로 복사
2.  **작업 스케줄러 등록**: `MWAgentRestart` 작업을 등록하여 `restart.bat` 실행
3.  **restart.bat 실행**: 프로세스 중지 → 기존 JAR 백업 → 새 JAR 교체 → 재시작
4.  **로깅**: 모든 과정은 `log\script_history.log`에 기록

## 5. 결과 확인
- **로그 경로**: `C:\Users\SYSADMIN\MWAgent\log\script_history.log`

## 6. 롤백 (문제 발생 시)
1.  MWAgent 중지: `stop_mwagent.bat` 실행
2.  현재 `mwagent.jar` 삭제 또는 이름 변경
3.  백업 파일(`mwagent.jar.bak_...`)의 이름을 `mwagent.jar`로 변경
4.  MWAgent 시작: `start_mwagent.bat` 실행
