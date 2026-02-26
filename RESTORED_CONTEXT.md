# Restored Context Summary (Post-Reinstall)
> Generated: 2026-02-26 | Antigravity reinstall recovery
> Source: CONTEXT.md, CONTEXT_KR.md, all scripts, configs, docs, and git history

---

## 1. Project Summary

**MWAgent** is a Java-based Windows Service agent that connects to a remote **MWServer**.

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
| `agent.properties` | Runtime config (server URL, token, log_dir, log_level) |
| `run.agent.bat` | Restart trigger (creates SYSTEM scheduled task) |
| `restart.bat` | Restart executor (stop → kill PID → JAR swap → start) |
| `start_mwagent.bat` | Debug-only: direct Java execution |
| `stop_mwagent.bat` | Debug-only: kill Java by WMIC |
| `log/` | All logs (WinSW + Java app + script history) |
| `lib/` | 12 dependency JARs |
| `docs/` | Date-organized documentation archive |
| `_old/` | Archived old files (old JARs, logs, backups) |

---

## 3. Current Status (as of 2026-02-25 snapshot)

- ✅ MWAgent registered and communicating with MWServer
- ✅ Windows Service installed and running
- ✅ Self-restart via Task Scheduler working
- ✅ JAR update flow working (new_mwagent.jar → backup → swap → restart)
- ✅ Logs centralized to `log/` directory
- ✅ All scripts unified to Windows Service model
- ✅ Documentation archived under `docs/`

---

## 4. What Was In Progress at Time of Reinstall

- 🔄 **Log redirection verification** — `log_dir=./log` was added to `agent.properties` to move Java app logs from project root to `log/`. Needs confirmation after restart.
  - **Observation**: `mwagent.0.0.log` still exists in project root (56KB), but `log/mwagent.0.0.log` also exists (174KB) — suggests the fix may be working but the old root file wasn't cleaned up.

---

## 5. Next Steps (Priority Order)

1. **Verify log redirection** — confirm `log/` is the sole log destination after service restart; clean up root-level `mwagent.0.0.log` if confirmed
2. **Test full JAR update flow end-to-end** — drop `new_mwagent.jar` and verify backup + swap + restart
3. **Token refresh** — current JWT token in `agent.properties` expires ~2026-03-10; verify auto-refresh mechanism
4. **Service reinstall after XML changes** — `mwagent-service.xml` changes require `uninstall` + `install`

---

## 6. Known Critical Constraints

| Constraint | Details |
|------------|---------|
| `.bat` files must be ASCII (no BOM) | UTF-8 BOM causes CMD parse errors; use PowerShell StreamWriter with ASCII encoding |
| Batch comments in English only | ASCII encoding drops Korean characters |
| `%date%/%time%` outside `if` blocks | CMD AutoRun causes parse errors inside `if`; capture to variable first |
| `sc stop` blocks forever | Use `start /b sc stop` + `taskkill /F /PID` instead |
| Admin required for `run.agent.bat` | `schtasks /RU SYSTEM` needs admin privileges |

---

## 7. Git History

Only 1 commit exists:
```
0b51d71 chore: pre-reinstall context snapshot
```

This was the snapshot taken just before the Antigravity reinstallation on 2026-02-25.

---

## 8. Gaps & Uncertainties

| Area | Confidence | Note |
|------|-----------|------|
| Overall architecture & purpose | **High** | Thoroughly documented in CONTEXT.md |
| Script logic & configuration | **High** | All files read and understood |
| Service current running state | **Medium** | Need to run `sc query MWAgent` to verify |
| Log redirection working | **Medium** | Both root and `log/` have log files — unclear if fully migrated |
| Token expiry handling | **Low** | No source code available; depends on Java app internals |
| Java source code details | **N/A** | Source not in this repo — only compiled JAR |
