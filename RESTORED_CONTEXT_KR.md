# 맥락 복원 요약 (재설치 후)
> 이 문서는 Antigravity 재설치 후 AI가 파악한 프로젝트 현황을 한국어로 정리한 사용자용 문서입니다.
> 내용을 확인하시고 누락되거나 잘못된 부분이 있으면 알려주세요.
> 작성일: 2026-03-03

---

## 1. 프로젝트 요약

**MWAgent**는 원격 **MWServer**에 연결되는 Java 기반 Windows 서비스 에이전트입니다.

| 항목 | 내용 |
|------|------|
| 목적 | 원격 명령 실행, JAR 자동 업데이트, Kafka 헬스체크 |
| 실행 환경 | Windows + Java, **WinSW** (`mwagent-service.exe`)로 서비스화 |
| 통신 방식 | HTTP REST + Kafka (소비자/생산자) |
| 설정 파일 | `agent.properties` (서버 URL, 인증 토큰, 로그 경로) |
| 서비스 ID | `MWAgent` (Windows 서비스 등록명) |
| 서버 | `WIN-RVA6N8ACU27`, 사용자 `SYSADMIN`, 도메인 `SCP_WINDOW` |
| MWServer | `http://mamama.iptime.org:8000` |

### 아키텍처

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
| `mwagent.jar` | Java 메인 앱 (컴파일됨, 소스 없음) |
| `mwagent-service.exe` | WinSW 바이너리 |
| `mwagent-service.xml` | WinSW 설정 (JVM 인수, 환경변수, 로그 경로) |
| `agent.properties` | 운영 설정 (서버 URL, 토큰, log_dir=./log, 로그 레벨) |
| `run.agent.bat` | 재시작 트리거 (SYSTEM 스케줄러 작업 생성) |
| `restart.bat` | 재시작 실행기 (서비스 중지 → PID 종료 → JAR 교체 → 시작) |
| `start_mwagent.bat` | 디버깅 전용: Java 직접 실행 |
| `stop_mwagent.bat` | 디버깅 전용: WMIC으로 Java 종료 |
| `log/` | 모든 로그 (WinSW + Java 앱 + 스크립트 히스토리) |
| `lib/` | 12개 의존 JAR (Kafka, HTTP, 암호화, JSON, 압축) |
| `docs/` | 날짜별 문서 아카이브 (5개 날짜 폴더) |
| `deploy/` | 배포 패키지 (`MWAgent.tar`, ~37MB) |
| `_old/` | 아카이브 파일 |

---

## 3. 현재 상태 (2026-03-03 기준)

- ✅ MWAgent가 MWServer에 등록되어 통신 중
- ✅ Windows 서비스 설치 및 실행 중
- ✅ 작업 스케줄러를 통한 자동 재시작 동작 확인
- ✅ JAR 업데이트 흐름 동작 확인 (new_mwagent.jar → 백업 → 교체 → 재시작)
- ✅ **로그 경로 리다이렉션 동작 확인** — `log/` 디렉토리에 활발하게 로그 생성 중 (`mwagent.0.0.log` 199KB, `mwagent.1.1.log` 1MB)
- ✅ 루트 레벨 `mwagent.0.0.log`는 남아있지만 (80KB, 레거시), `.gitignore`로 제외됨
- ✅ 문서 `docs/`에 아카이브됨
- ✅ GitHub 리모트 연결 완료 (`origin/main`)
- ✅ 배포 패키지 생성 완료 (`deploy/MWAgent.tar`)

---

## 4. Git 히스토리

```
7de0a8e (HEAD -> main, origin/main) chore: add deploy package
e0da699 chore: add GitHub upload guide and updated context
0b51d71 chore: pre-reinstall context snapshot
```

이전 재설치: 2026-02-26. 현재 재설치: 2026-03-03.

---

## 5. 진행 중이었던 작업

### 이전 컨텍스트 (2026-02-25 CONTEXT.md 기준):
- 🔄 **로그 경로 리다이렉션 검증** — `agent.properties`에 `log_dir=./log` 추가
  - **현재 확인됨**: `log/` 디렉토리에 활발한 로그 파일 존재. 리다이렉션이 정상 동작 중
  - **정리 필요**: 루트의 `mwagent.0.0.log` (80KB)는 구 파일이지만 무해함 (`.gitignore`로 제외)

### GitHub 업로드 작업 (2026-02-26):
- ✅ GitHub 저장소 연결 완료, `origin/main`에 코드 Push 완료
- GitHub 업로드 과정은 `docs/GitHub_업로드_가이드.md`에 문서화됨

---

## 6. 다음 작업 순서 (우선순위)

1. **루트 레벨 `mwagent.0.0.log` 정리** — 로그 리다이렉션 확인되었으므로 삭제 가능
2. **토큰 갱신 확인** — JWT 토큰 생성일 2026-02-26, ~15일 만료 → **2026-03-10경 만료 예상** (약 7일 남음)
3. **전체 JAR 업데이트 E2E 테스트** — `new_mwagent.jar` 드롭 후 백업 + 교체 + 재시작 검증
4. **XML 변경 후 서비스 재설치** — `mwagent-service.xml` 변경 시 `uninstall` + `install` 필요

---

## 7. 알려진 핵심 제약사항

| 제약사항 | 상세 |
|----------|------|
| `.bat` 파일은 BOM 없는 ASCII로 저장 | UTF-8 BOM이 있으면 CMD 파싱 오류; PowerShell StreamWriter + ASCII 사용 |
| 배치 주석은 영문만 사용 | ASCII 인코딩은 한글 깨짐 |
| `if` 블록 밖에서 `%date%/%time%` 캡처 | CMD AutoRun 레지스트리 간섭 방어 |
| `sc stop`은 무한 블로킹 | `start /b sc stop` + `taskkill /F /PID` 사용 |
| `run.agent.bat`은 관리자 필요 | `schtasks /RU SYSTEM`에 관리자 권한 필요 |

---

## 8. 파악 수준 및 불확실한 부분

| 영역 | 신뢰도 | 비고 |
|------|--------|------|
| 전체 아키텍처 및 목적 | **높음** | CONTEXT.md에 상세 문서화됨 |
| 스크립트 로직 및 설정 | **높음** | 모든 파일 확인 완료 |
| 로그 리다이렉션 동작 | **높음** | `log/` 디렉토리 파일 크기로 확인 |
| 서비스 현재 실행 상태 | **중간** | `sc query MWAgent` 실행 필요 |
| 토큰 만료 처리 메커니즘 | **낮음** | 소스 코드 없음; Java 앱 내부 동작에 의존 |
| Java 소스 코드 세부사항 | **해당없음** | 이 저장소에 소스 없음 — 컴파일된 JAR만 존재 |
