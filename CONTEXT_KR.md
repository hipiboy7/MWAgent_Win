# 프로젝트 현황 요약 (재설치 전 스냅샷)
> 이 문서는 Antigravity 재설치 전 현재 상태를 한국어로 정리한 사용자용 문서입니다.
> AI용 원본 문서는 CONTEXT.md를 참고하세요.
> 작성일: 2026-02-25

---

## 1. 프로젝트 목적

**MWAgent**는 Windows 서비스로 실행되는 Java 에이전트 프로그램입니다.
중앙 서버인 **MWServer**에 연결해 자신을 등록하고, 서버에서 보내는 명령을 받아 로컬 PC에서 실행한 뒤 결과를 돌려줍니다.

주요 기능:
- 원격 명령 실행 (쉘 스크립트, 파일 처리, 에이전트 전용 함수)
- 새 JAR 파일 수신 후 자동 교체 + 서비스 재시작
- Kafka를 통한 헬스체크 보고

---

## 2. 기술 스택

| 구분 | 기술 |
|------|------|
| 언어 | Java (컴파일된 상태, 소스 없음 — `mwagent.jar` 안에 `.class` 파일) |
| 서비스 래퍼 | **WinSW** (`mwagent-service.exe`) — Java를 Windows 서비스로 감싸주는 도구 |
| 통신 | HTTP REST + **Kafka** |
| 설정 파일 | `agent.properties` (Java Properties 형식) |
| 로깅 | `java.util.logging` — `log/logging.properties`로 설정 |
| 스크립트 | Windows 배치(.bat) — ASCII 인코딩 필수 (BOM 없음) |
| 운영 OS | Windows (`WIN-RVA6N8ACU27`) |

---

## 3. 구조 개요

```
MWServer (원격 서버)
    │  HTTP REST / Kafka 통신
    ▼
MWAgent (이 PC)
    ├── mwagent-service.exe   ← Windows 서비스 래퍼 (WinSW)
    │       └── java.exe      ← 실제 MWAgent Java 프로세스
    │               ├── Kafka 소비자 스레드 (명령 수신)
    │               ├── 명령 실행 스레드
    │               ├── 헬스체크 스레드
    │               └── 종료 핸들러
    │
    ├── agent.properties      ← 운영 설정 (서버 URL, 토큰, 로그 디렉토리 등)
    ├── mwagent-service.xml   ← WinSW 설정 (JVM 인수, 환경 변수, 로그 경로)
    ├── log/                  ← 모든 로그 저장 위치
    │
    └── 자동 재시작 흐름:
            Java → run.agent.bat → 작업 스케줄러(SYSTEM 권한) → restart.bat
                                                                   ├── 서비스 중지 (비동기)
                                                                   ├── java.exe 강제 종료 (PID)
                                                                   ├── [new_mwagent.jar 있으면 JAR 교체]
                                                                   └── 서비스 시작
```

---

## 4. 핵심 파일 설명

| 파일 | 역할 |
|------|------|
| `mwagent.jar` | Java 메인 프로그램 |
| `mwagent-service.exe` | WinSW 바이너리 (Windows 서비스 래퍼) |
| `mwagent-service.xml` | WinSW 설정 (JVM 인수, 환경변수, 로그 경로, 작업 디렉토리) |
| `agent.properties` | 운영 설정: 서버 URL, 인증 토큰, 로그 디렉토리 등 |
| `run.agent.bat` | **재시작 트리거** — Java가 호출; SYSTEM 권한 작업 스케줄러 등록 |
| `restart.bat` | **재시작 실행기** — 작업 스케줄러가 SYSTEM으로 실행; 서비스 중지/종료/시작 |
| `start_mwagent.bat` | 디버깅 전용: 서비스 없이 Java 직접 실행 |
| `stop_mwagent.bat` | 디버깅 전용: Java 프로세스 wmic으로 종료 |
| `log/logging.properties` | Java 로깅 설정 |
| `lib/` | Java 의존성 JAR 파일들 |
| `docs/` | 날짜별 프로젝트 문서 아카이브 |
| `_old/` | 더 이상 사용하지 않는 파일 보관 |

---

## 5. 현재 상태 (2026-02-25 기준)

- ✅ MWAgent MWServer에 등록 완료 및 통신 중
- ✅ Windows 서비스 설치 완료 (`mwagent-service.exe install`)
- ✅ 자동 재시작 동작 확인 (`run.agent.bat` → `restart.bat` → SYSTEM 스케줄러)
- ✅ JAR 교체 + 재시작 흐름 동작 확인 (`new_mwagent.jar` 드롭 → 백업 + 교체 + 재시작)
- ✅ 모든 로그가 `log/` 디렉토리로 이동됨 (`agent.properties`에 `log_dir=./log` 추가)
- ✅ 스크립트가 Windows 서비스 방식으로 통일됨
- ✅ 프로젝트 문서 `docs/`에 아카이브됨

---

## 6. 진행 중인 작업

- 🔄 `log_dir=./log` 설정 최종 검증 중
  - 이전: `mwagent.0.0.log`가 프로젝트 루트에 생성됨
  - 수정: `agent.properties`에 `log_dir=./log` 추가 (리눅스와 동일한 키 사용)
  - 검증 필요: 재시작 후 `log/` 디렉토리에만 생성되는지 확인

---

## 7. 알려진 문제 및 해결 방법

### A. `run.agent.bat` — 반드시 관리자 CMD에서 실행
- **문제**: `schtasks /Create /RU SYSTEM`은 관리자 권한 필요
- **운영 환경**: 문제 없음 — Java 서비스가 SYSTEM으로 실행되므로 자동으로 권한 충족
- **수동 테스트 시**: 반드시 **관리자 CMD**에서 실행

### B. 배치 파일은 BOM 없는 ASCII로 저장해야 함
- **문제**: `.bat` 파일에 UTF-8 BOM이 포함되면 `. was unexpected at this time.` 에러 발생
- **해결**: PowerShell StreamWriter로 ASCII 저장
  ```powershell
  $sw = New-Object System.IO.StreamWriter('파일.bat', $false, [System.Text.Encoding]::ASCII)
  ```
- **주의**: 이 방식으로 저장하면 한글이 깨짐 → **배치 파일 주석은 영문 사용**

### C. `if` 블록 안에서 `%date%/%time%` 직접 사용 금지
- **문제**: CMD AutoRun 레지스트리 설정이 있을 때 `if` 블록 안에서 파싱 오류 발생
- **해결**: 블록 진입 전에 미리 변수에 저장
  ```bat
  set NOW=%date% %time%
  if ... ( echo [%NOW%] ... )
  ```

### D. `sc stop`이 무한 대기(블로킹)
- **문제**: `sc stop MWAgent`는 서비스가 STOPPED 상태가 될 때까지 무한 대기
- **해결**: `start /b sc stop`으로 비동기 실행 후, `sc queryex`로 PID 확보해 `taskkill /F /PID`로 직접 종료

---

## 8. 다음 작업 순서 (우선순위)

1. **로그 경로 검증** — `log_dir=./log` 설정 후 `log/`에만 로그 생성되는지 재확인
2. **전체 JAR 업데이트 흐름 테스트** — `new_mwagent.jar` 드롭 → 백업 + 교체 + 재시작 end-to-end 검증
3. **토큰 자동 갱신 확인** — `agent.properties`의 `token`은 만료 기간 있음(~15일); 자동 갱신 동작 확인
4. **XML 변경 후 서비스 재설치** — `mwagent-service.xml` 변경 시 `uninstall` → `install` 필요

---

## 9. 주요 설계 결정 사항

| 결정 | 이유 |
|------|------|
| WinSW 사용 | Java를 코드 수정 없이 Windows 서비스로 등록할 수 있는 가장 간단한 방법 |
| 작업 스케줄러 방식 재시작 | Java가 자기 자신(JVM)을 재시작할 수 없어 OS 스케줄러에게 위임 |
| `start /b` + `taskkill /PID` | `sc stop`, `net stop` 모두 블로킹; PID 직접 종료만이 신뢰할 수 있는 비동기 방법 |
| ASCII 배치 파일 | BOM이 있으면 CMD 파싱 실패; ASCII가 모든 환경에서 안전 |
| 타임스탬프 사전 캡처 | CMD AutoRun에서 `if` 블록 내 `%date%/%time%` 파싱 오류 방어 |
| 로그 → `log/` 중앙화 | WinSW `<logpath>` + Java `log_dir` 모두 `log/` 지정 |

---

## 10. 외부 의존성 및 환경 변수

| 항목 | 내용 |
|------|------|
| MWServer URL | `agent.properties`의 `server_url` (`http://mamama.iptime.org:8000`) |
| 인증 토큰 | `agent.properties`의 `token` — JWT 리프레시 토큰, 약 15일 만료 |
| Kafka | MWServer 내장; 에이전트가 소비자/생산자로 연결 |
| Java | OpenJDK (x64); PATH에 등록되어 있어야 함 |
| 환경 변수 | `USER=SYSADMIN`, `HOSTNAME=WIN-RVA6N8ACU27`, `DOMAIN_NAME=SCP_WINDOW` (`mwagent-service.xml`에 설정) |

---

## 11. 서비스 관리 명령어 (관리자 CMD 필요)

```cmd
:: 서비스 등록 / 해제
mwagent-service.exe install
mwagent-service.exe uninstall

:: 서비스 시작 / 중지
net start MWAgent
net stop MWAgent

:: 재시작 트리거 (관리자 CMD)
run.agent.bat

:: JAR 업데이트 + 재시작
run.agent.bat new_mwagent.jar

:: 서비스 상태 확인
sc query MWAgent

:: 로그 확인
dir log\
type log\script_history.log
```
