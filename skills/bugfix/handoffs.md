# Skill handoffs

### Entry points (how you get to /bugfix)

- `/standup` recommends a bug Issue → /bugfix
- E2E verification fails → /bugfix directly (no "try once first" — E2E failures go straight to /bugfix)
- `/functional-test` discovers a bug → if current window context is long → `/handoff` → new window /bugfix; otherwise /bugfix in current window
- Production user/colleague feedback → create Bug Issue → /bugfix
- During development, you hit a bug → /bugfix directly, or `file an Issue first then /bugfix
- User invokes /bugfix directly

### Exit points (where you go after /bugfix)

> **Gate: Phase 6 complete?** Before taking ANY exit path below, verify Phase 6 (cleanup + knowledge capture) has been completed. If not → go back and complete Phase 6 first. No exceptions.

- **Fixed** → Phase 6 knowledge capture → return to original flow
  - If entered from E2E → re-run `/e2e-verify #N` with round M+1/3 and previous E2E report
  - If entered from functional-test → return to functional-test window, verify fix + continue remaining tests
- **Architectural issue** → `/improve-codebase-architecture`
- **Design flaw (not a bug)** → `/grill-with-docs` → `/to-prd`
- **Additional problems discovered** → file new Issues on your tracker
