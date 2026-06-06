# Multi-session debugging

### When to handoff

- Context window approaching limit (conversation is very long, tool calls slowing down)
- Same hypothesis attempted 3 times without success — need a fresh approach
- User requests switching to a new window

### Handoff format — Debug Chain

When using `/handoff`, include a Debug Chain section:

```
## Debug Chain

- Session 1 [<JSONL-filename>]: Phase 1-3 complete.
    Built failing test (test/xxx.test.ts:42).
    Ruled out hypothesis 1 (race condition), hypothesis 2 (cache stale), hypothesis 3 (wrong query).
    Hypothesis 4 (cross-module state sync) pending verification.
    Key discovery: Credit.expiresAt update does not trigger tokenSync.

- Session 2 [<JSONL-filename>] (current): Verifying hypothesis 4.
    Fix approach A (add syncToken call in updateExpiry) introduced regression —
    token double-issued on renewal.
    Next step suggestion: approach B — intercept expiresAt changes at middleware layer.
```

Each session entry must include:
1. Which Phase was reached
2. The feedback loop that was built (specific file:line)
3. Hypotheses ruled out (each + the evidence that ruled it out)
4. Hypotheses not yet verified
5. Key discoveries (new domain knowledge or code behavior)
6. Next step suggestion

### Continuation rules

A new session's /bugfix:
1. Read the handoff's Debug Chain — do not start from scratch
2. Continue from the debug chain's last state
3. Do not re-test hypotheses that were conclusively ruled out (unless new evidence overturns the ruling)
4. First verify the previous session's "next step suggestion"

### Post-mortem (triggered when debug chain has > 1 session)

After the bug is finally fixed, if the debug chain contains more than 1 session entry, automatically run a post-mortem:

**1. Review where each session got stuck**
- How many turns did Session N take? Which Phase did it stall at?
- Which hypothesis wasted the most time?

**2. Identify: what information, if available from the start, would have saved an entire session?**
- Example: "If docs/specs/billing.md had documented the Credit.expiresAt ↔ tokenSync relationship, Session 1 would not have spent time ruling out the first 3 hypotheses"

**3. Outputs**:
- Write to `docs/specs/` — so the next agent has this information from the start (Phase 0 will read it)
- Update `CONTEXT.md` — if new domain relationships were discovered
- If the flaw is in /bugfix methodology itself → follow 6d (IMPROVEMENTS.md or tell the user)
