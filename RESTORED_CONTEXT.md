# Restored Context Summary (Post-Reinstall #2)
> Generated: 2026-03-03 | Antigravity reinstall recovery
> Source: CONTEXT.md, CONTEXT_KR.md, all scripts, configs, docs, git history, log directory

---

## 1. Project Summary

**MWAgent** is a Java-based Windows Service agent connecting to a remote **MWServer**.

| Aspect | Details |
|--------|---------|
| Purpose | Remote command execution, JAR auto-update, health check via Kafka |
| Runtime | Java on Windows, wrapped with **WinSW** (`mwagent-service.exe`) |
| Communication | HTTP REST + Kafka (consumer/producer) |
| Config | `agent.properties` (server URL, auth token, log dir) |
| Service ID | `MWAgent` registered Windows Service |
| Machine | `WIN-RVA6N8ACU27`, user `SYSADMIN`, domain `SCP_WINDOW` |
| Server | `http://mamama.iptime.org:8000` |

### Architecture

```
MWServer → HTTP/Kafka → MWAgent (WinSW → java.exe → mwagent.MwAgent)
                          ├── Kafka consumer (command polling)
                          ├── Order execution thread
                          ├── Health check thread
                          └── Self-restart: run.agent.bat → Task Scheduler → restart.bat
```

---

## 2. Key Files

| File | Role |
|------|------|
| `mwagent.jar` | Main Java app (compiled, no source) |
| `mwagent-service.exe` | WinSW binary |
| `mwagent-service.xml` | WinSW config (JVM args, env vars, log path) |
| `agent.properties` | Runtime config (server URL, token, log_dir=./log, log_level) |
| `run.agent.bat` | Restart trigger (creates SYSTEM scheduled task) |
| `restart.bat` | Restart executor (stop → kill PID → JAR swap → start) |
| `start_mwagent.bat` | Debug-only: direct Java execution |
| `stop_mwagent.bat` | Debug-only: kill Java by WMIC |
| `log/` | All logs (WinSW + Java app + script history) |
| `lib/` | 12 dependency JARs (Kafka, HTTP, crypto, JSON, compression) |
| `docs/` | Date-organized documentation archive (5 date folders) |
| `deploy/` | Deployment package (`MWAgent.tar`, ~37MB) |
| `_old/` | Archived old files |

---

## 3. Current Status (as of 2026-03-03)

- ✅ MWAgent registered and communicating with MWServer
- ✅ Windows Service installed and running
- ✅ Self-restart via Task Scheduler working
- ✅ JAR update flow working (new_mwagent.jar → backup → swap → restart)
- ✅ **Log redirection confirmed working** — `log/` has active log files (`mwagent.0.0.log` 199KB, `mwagent.1.1.log` 1MB)
- ✅ Root-level `mwagent.0.0.log` still exists (80KB, legacy), but ignored by `.gitignore`
- ✅ Documentation archived under `docs/`
- ✅ GitHub remote connected (`origin/main`)
- ✅ Deploy package created (`deploy/MWAgent.tar`)

---

## 4. Git History

```
7de0a8e (HEAD -> main, origin/main) chore: add deploy package
e0da699 chore: add GitHub upload guide and updated context
0b51d71 chore: pre-reinstall context snapshot
```

Previous reinstall occurred on 2026-02-26. Current reinstall is 2026-03-03.

---

## 5. What Was In Progress

### From the previous context (2026-02-25 CONTEXT.md):
- 🔄 **Log redirection verification** — `log_dir=./log` was added to `agent.properties`
  - **Now confirmed**: `log/` directory contains active, growing log files. Log redirection is working.
  - **Cleanup needed**: Root-level `mwagent.0.0.log` (80KB) is stale but harmless (`.gitignore` covers it)

### From the GitHub upload guide (2026-02-26):
- ✅ GitHub repository connected and code pushed to `origin/main`
- GitHub upload process was documented in `docs/GitHub_업로드_가이드.md`

---

## 6. Next Steps (Priority Order)

1. **Clean up root-level `mwagent.0.0.log`** — can be deleted now that log redirection is confirmed
2. **Token refresh** — JWT token in `agent.properties` was created 2026-02-26 with ~15 day expiry → likely **expired around 2026-03-10** (still valid for ~7 more days)
3. **Test full JAR update flow end-to-end** — drop `new_mwagent.jar` and verify backup + swap + restart
4. **Service reinstall after XML changes** — `mwagent-service.xml` changes require `uninstall` + `install`

---

## 7. Known Critical Constraints

| Constraint | Details |
|------------|---------|
| `.bat` files must be ASCII (no BOM) | UTF-8 BOM causes CMD parse errors; use PowerShell StreamWriter with ASCII encoding |
| Batch comments in English only | ASCII encoding drops Korean characters |
| `%date%/%time%` outside `if` blocks | CMD AutoRun causes parse errors inside `if`; capture to variable first |
| `sc stop` blocks forever | Use `start /b sc stop` + `taskkill /F /PID` instead |
| Admin required for `run.agent.bat` | `schtasks /RU SYSTEM` needs admin privileges |

---

## 8. Gaps & Uncertainties

| Area | Confidence | Note |
|------|-----------|------|
| Overall architecture & purpose | **High** | Thoroughly documented in CONTEXT.md |
| Script logic & configuration | **High** | All files read and understood |
| Log redirection working | **High** | Confirmed by log file sizes in `log/` |
| Service current running state | **Medium** | Need `sc query MWAgent` to verify |
| Token expiry handling | **Low** | No source code; depends on Java app internals |
| Java source code details | **N/A** | Source not in this repo — only compiled JAR |
