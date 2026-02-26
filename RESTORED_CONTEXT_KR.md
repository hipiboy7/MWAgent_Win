# 맥락 복원 요약 (재설치 후)
> 이 문서는 Antigravity 재설치 후 AI가 파악한 프로젝트 현황을 한국어로 정리한 사용자용 문서입니다.
> 내용을 확인하시고 누락되거나 잘못된 부분이 있으면 알려주세요.
> 작성일: 2026-02-26

---

## 1. 프로젝트 요약

**MWAgent**는 원격 **MWServer**에 연결되는 Java 기반 Windows 서비스 에이전트입니다.

| 항목 | 내용 |
|------|------|
| 목적 | 원격 명령 실행, JAR 자동 업데이트, Kafka를 통한 헬스체크 보고 |
| 실행 환경 | Windows에서 **WinSW** (`mwagent-service.exe`)로 Java 서비스 실행 |
| 통신 | HTTP REST + Kafka (소비자/생산자) |
| 설정 | `agent.properties` (서버 URL, 인증 토큰, 로그 디렉토리) |
| 서비스 ID | `MWAgent` (Windows 서비스 등록명) |
| 서버 | `WIN-RVA6N8ACU27`, 사용자 `SYSADMIN`, 도메인 `SCP_WINDOW` |
| MWServer | `http://mamama.iptime.org:8000` |

### 구조

```
MWServer → HTTP/Kafka → MWAgent (WinSW → java.exe → mwagent.MwAgent)
                          ├── Kafka 소비자 (명령 수신)
                          ├── 명령 실행 스레드
                          ├── 헬스체크 스레드
                          └── 자동 재시작: run.agent.bat → 작업 스케줄러 → restart.bat
```

---

## 2. 핵심 파일

| 파일 | 역할 |
|------|------|
| `mwagent.jar` | Java 메인 프로그램 (컴파일된 상태, 소스 없음) |
| `mwagent-service.exe` | WinSW 바이너리 |
| `mwagent-service.xml` | WinSW 설정 (JVM 인수, 환경변수, 로그 경로) |
| `agent.properties` | 운영 설정 (서버 URL, 토큰, log_dir, log_level) |
| `run.agent.bat` | 재시작 트리거 (SYSTEM 권한 작업 스케줄러 등록) |
| `restart.bat` | 재시작 실행기 (중지 → PID 종료 → JAR 교체 → 시작) |
| `start_mwagent.bat` | 디버깅 전용: Java 직접 실행 |
| `stop_mwagent.bat` | 디버깅 전용: WMIC으로 Java 프로세스 종료 |
| `log/` | 모든 로그 (WinSW + Java 앱 + 스크립트 기록) |
| `lib/` | 의존성 JAR 12개 |
| `docs/` | 날짜별 프로젝트 문서 아카이브 |
| `_old/` | 이전 버전 JAR, 로그, 백업 파일 보관 |

---

## 3. 현재 상태 (2026-02-25 스냅샷 기준)

- ✅ MWAgent가 MWServer에 등록 완료 및 통신 중
- ✅ Windows 서비스 설치 및 실행 중
- ✅ 작업 스케줄러를 통한 자동 재시작 동작 확인
- ✅ JAR 업데이트 흐름 동작 확인 (new_mwagent.jar → 백업 → 교체 → 재시작)
- ✅ 모든 로그가 `log/` 디렉토리로 중앙화됨
- ✅ 모든 스크립트가 Windows 서비스 방식으로 통일됨
- ✅ 프로젝트 문서가 `docs/`에 아카이브됨

---

## 4. 재설치 시점에 진행 중이던 작업

- 🔄 **로그 경로 리다이렉션 검증** — `agent.properties`에 `log_dir=./log`를 추가하여 Java 앱 로그를 프로젝트 루트에서 `log/`로 이동시키는 작업
  - **관찰 사항**: 프로젝트 루트에 `mwagent.0.0.log`(56KB)가 여전히 존재하고, `log/mwagent.0.0.log`(174KB)도 존재함 → 수정이 적용된 것으로 보이나 루트의 이전 파일이 정리되지 않은 상태

---

## 5. 다음 작업 (우선순위 순)

1. **로그 경로 검증** — 서비스 재시작 후 `log/`에만 로그가 생성되는지 확인; 확인 후 루트의 `mwagent.0.0.log` 정리
2. **전체 JAR 업데이트 흐름 테스트** — `new_mwagent.jar` 드롭 후 백업 + 교체 + 재시작 end-to-end 검증
3. **토큰 갱신 확인** — `agent.properties`의 JWT 토큰 만료일이 약 2026-03-10; 자동 갱신 메커니즘 동작 확인
4. **XML 변경 후 서비스 재설치** — `mwagent-service.xml` 변경 시 `uninstall` → `install` 필요

---

## 6. 알려진 주요 제약 사항

| 제약 | 상세 |
|------|------|
| `.bat` 파일은 BOM 없는 ASCII로 저장 | UTF-8 BOM이 있으면 CMD 파싱 에러 발생; PowerShell StreamWriter로 ASCII 저장 |
| 배치 파일 주석은 영문만 | ASCII 인코딩에서 한글이 깨짐 |
| `%date%/%time%`는 `if` 블록 밖에서 캡처 | CMD AutoRun 설정이 있을 때 `if` 블록 내 파싱 오류 |
| `sc stop`은 무한 대기 | `start /b sc stop` + `taskkill /F /PID`를 대신 사용 |
| `run.agent.bat`은 관리자 권한 필요 | `schtasks /RU SYSTEM`이 관리자 권한을 요구 |

---

## 7. Git 히스토리

커밋 1개만 존재합니다:
```
0b51d71 chore: pre-reinstall context snapshot
```
2026-02-25 Antigravity 재설치 직전에 만든 스냅샷입니다.

---

## 8. 불확실한 영역

| 영역 | 신뢰도 | 비고 |
|------|--------|------|
| 전체 구조 및 목적 | **높음** | CONTEXT.md에 상세히 문서화되어 있음 |
| 스크립트 로직 및 설정 | **높음** | 모든 파일을 읽고 이해함 |
| 서비스 현재 실행 상태 | **보통** | `sc query MWAgent` 실행으로 확인 필요 |
| 로그 리다이렉션 동작 여부 | **보통** | 루트와 `log/` 모두에 로그 파일 존재 — 완전 마이그레이션 여부 불분명 |
| 토큰 만료 자동 처리 | **낮음** | 소스 코드 없음; Java 앱 내부 로직에 의존 |
| Java 소스 코드 상세 | **해당 없음** | 이 저장소에 소스 없음 — 컴파일된 JAR만 존재 |
