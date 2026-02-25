# MWAgent — Project Context Snapshot
> Generated: 2026-02-25 | Pre-Antigravity-reinstall snapshot
> Korean version: CONTEXT_KR.md

---

## 1. Project Purpose

**MWAgent** is a Windows Service that acts as a managed agent connecting to a central **MWServer**.
It registers itself with the server, polls for commands, executes them on the local machine, and reports results back.

Primary uses:
- Remote command execution (shell scripts, file operations, agent functions)
- Remote JAR update + service self-restart triggered from the server
- Health check reporting via Kafka

---

## 2. Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Java (compiled, no source in this repo — `.class` files in `mwagent.jar`) |
| Service Wrapper | **WinSW** (`mwagent-service.exe`) — wraps Java as a Windows Service |
| Communication | HTTP REST + **Kafka** (MwConsumerThread, MwProducer) |
| Config | `agent.properties` (Java Properties format) |
| Logging | `java.util.logging` — configured via `log/logging.properties` |
| Scripts | Windows Batch (`.bat`) — PowerShell/StreamWriter saved (ASCII, no BOM) |
| OS | Windows (tested: Windows Server, `WIN-RVA6N8ACU27`) |

---

## 3. Architecture Overview

```
MWServer (remote)
    │  HTTP REST / Kafka
    ▼
MWAgent (this machine)
    ├── mwagent-service.exe   ← WinSW wrapper (Windows Service: "MWAgent")
    │       └── java.exe      ← actual JVM running mwagent.MwAgent
    │               ├── MwConsumerThread   (Kafka polling)
    │               ├── OrderCallerThread  (command execution)
    │               ├── MwHealthCheckThread
    │               └── GracefulShutdownHandler
    │
    ├── agent.properties      ← runtime config (server URL, token, log_dir, etc.)
    ├── mwagent-service.xml   ← WinSW config (JVM args, env vars, logpath)
    ├── log/                  ← ALL logs go here (service + java app)
    │
    └── Self-Restart Flow:
            Java → run.agent.bat → Task Scheduler (SYSTEM) → restart.bat
                                                               ├── sc stop (async)
                                                               ├── taskkill /PID
                                                               ├── [JAR swap if new_mwagent.jar exists]
                                                               └── net start MWAgent
```

---

## 4. Key Files

| File | Role |
|------|------|
| `mwagent.jar` | Main Java application |
| `mwagent-service.exe` | WinSW binary (Windows Service wrapper) |
| `mwagent-service.xml` | WinSW configuration (JVM args, env, logpath, workingdir) |
| `agent.properties` | Runtime config: server_url, token, log_dir, log_level, etc. |
| `run.agent.bat` | **Restart trigger** — called by Java; creates SYSTEM-privileged scheduled task |
| `restart.bat` | **Restart executor** — run by Task Scheduler as SYSTEM; stops/kills/starts service |
| `start_mwagent.bat` | Debug-only: starts Java directly without service wrapper |
| `stop_mwagent.bat` | Debug-only: kills Java process by wmic |
| `log/logging.properties` | Java util logging config |
| `lib/` | Java dependency JARs |
| `docs/` | Project documentation archive (date-organized) |
| `_old/` | Archived/deprecated files |

---

## 5. Current Status (as of 2026-02-25)

- ✅ MWAgent registered and communicating with MWServer
- ✅ Windows Service configured (`mwagent-service.exe install`)
- ✅ Self-restart mechanism working (`run.agent.bat` → `restart.bat` via Task Scheduler as SYSTEM)
- ✅ JAR update flow working (drop `new_mwagent.jar` → triggers backup + swap + restart)
- ✅ All logs redirected to `log/` directory (`log_dir=./log` in `agent.properties`)
- ✅ Scripts unified to Windows Service model (`net start/stop MWAgent`)
- ✅ Documentation archived under `docs/`

---

## 6. Work In Progress

- 🔄 Verifying `log_dir=./log` (added to `agent.properties`) correctly redirects Java app logs
  - Previously: `mwagent.0.0.log` was appearing in project root
  - Fix applied: `log_dir=./log` in `agent.properties` (Linux convention, same key on Windows)

---

## 7. Known Issues & Workarounds

### A. `run.agent.bat` — Must run as Administrator
- **Issue**: `schtasks /Create /RU SYSTEM` requires admin rights
- **Production**: Not a problem — Java service runs as SYSTEM, which has admin rights
- **Manual test**: Must open CMD as Administrator

### B. Batch files must be saved as ASCII (no BOM)
- **Issue**: Any tool that saves `.bat` files with UTF-8 BOM causes `. was unexpected at this time.` parse error at runtime
- **Workaround**: Always save `.bat` files using PowerShell StreamWriter with `[System.Text.Encoding]::ASCII`
  ```powershell
  $sw = New-Object System.IO.StreamWriter('path.bat', $false, [System.Text.Encoding]::ASCII)
  ```
- **Implication**: All comments in `.bat` files must be in English (no Korean)

### C. `%date%/%time%` inside `if` blocks
- **Issue**: Using `%date% %time%` directly inside CMD `if (...)` blocks causes parse errors when CMD AutoRun registry settings are present
- **Workaround**: Capture timestamp into variable BEFORE the if block
  ```bat
  set NOW=%date% %time%
  if ... ( echo [%NOW%] ... )
  ```

### D. `sc stop` blocks indefinitely
- **Issue**: `sc stop MWAgent` blocks until service reaches STOPPED state; if Java hangs, script hangs forever
- **Workaround**: Use `start /b sc stop MWAgent` (non-blocking) then `taskkill /F /PID <PID>` using PID obtained from `sc queryex`

---

## 8. Next Steps (Priority Order)

1. **Verify log redirection** — confirm `log_dir=./log` moves java logs to `log/` after service restart
2. **Test full JAR update flow** — drop a `new_mwagent.jar` and verify backup + swap + restart works end-to-end
3. **Token refresh mechanism** — `token` in `agent.properties` has an expiry; confirm auto-refresh is working
4. **Service reinstall after XML change** — `mwagent-service.xml` changes require `mwagent-service.exe uninstall` then `install`

---

## 9. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Use WinSW for service | Standard, lightweight Java→Windows Service wrapper; no code changes needed |
| Task Scheduler for restart | Java cannot restart its own JVM; offload to OS scheduler running as SYSTEM |
| `start /b sc stop` + `taskkill /PID` | `sc stop` blocks; `net stop` blocks; `taskkill` by PID is the only reliable async kill |
| ASCII-only batch files | BOM in UTF-8 causes CMD parse failures; ASCII is safe across all CMD environments |
| `set NOW=` before if blocks | CMD AutoRun interference with `%date%/%time%` inside if-blocks |
| Logs to `log/` | Centralize all logs; WinSW `<logpath>` + Java `log_dir` property both point to `log/` |

---

## 10. External Dependencies

| Dependency | Details |
|-----------|---------|
| MWServer | `server_url` in `agent.properties` (`http://mamama.iptime.org:8000`) |
| Auth Token | JWT refresh token in `agent.properties` (`token=...`); has expiry (~15 days) |
| Kafka | Embedded in MWServer; agent connects as consumer/producer |
| Java | OpenJDK (x64); must be on PATH |
| Environment vars | `USER=SYSADMIN`, `HOSTNAME=WIN-RVA6N8ACU27`, `DOMAIN_NAME=SCP_WINDOW` (set in `mwagent-service.xml`) |

---

## 11. Service Management Commands

```cmd
:: Install / Uninstall service (run as Administrator)
mwagent-service.exe install
mwagent-service.exe uninstall

:: Start / Stop (run as Administrator)
net start MWAgent
net stop MWAgent

:: Trigger restart (run as Administrator — calls Task Scheduler)
run.agent.bat

:: Trigger JAR update + restart (run as Administrator)
run.agent.bat new_mwagent.jar

:: Check service status
sc query MWAgent

:: Check logs
dir log\
type log\script_history.log
```
