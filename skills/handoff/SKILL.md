---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
---

# /handoff

Write a handoff document so a fresh session can continue the work.

## Step 1 — Get current session ID

```bash
SESSION_ID=$(cat "$HOME/.claude/.session-pids/$PPID" 2>/dev/null)
```

If empty, fall back to the most recently modified JSONL:
```bash
SESSION_ID=$(ls -t ~/.claude/projects/$(echo "$PWD" | sed 's|/|-|g')/*.jsonl 2>/dev/null | head -1 | xargs basename | sed 's/.jsonl//')
```

## Step 2 — Write the handoff

### Naming convention

**Format**: `docs/handoff-<topic-slug>-<MMDD>.md`

- **topic-slug**: lowercase, hyphen-separated, 2-4 words describing the task (e.g., `invite-email`, `lifecycle-pipeline`, `edgeone-cdn`). Not required to include issue numbers — handoffs cover dev, research, planning, ops, anything.
- **MMDD**: month-day the handoff was created.
- **Same topic, new session**: update the existing handoff file, don't create a new one alongside it. Update the session ID in the header + Current state + Next steps.
- If the user specified a path, use that instead.

The handoff document must include:

### Header (always)

```
Previous session: <SESSION_ID>
JSONL: ~/.claude/projects/<project-dir>/<SESSION_ID>.jsonl
To review: use /agent-log skill with the JSONL path above
```

### Body (always)

- **Context**: what was being worked on and why
- **Current state**: what's done, what's not
- **Key files**: list every file the next session will need to read or edit, with one-line purpose. Include source files, configs, test files, skill files, docs — anything touched or discovered. The next session has zero context; a missing path means wasted exploration.
- **Next steps**: what the next session should do
- **Suggested skills**: which skills to invoke (e.g., `/bugfix`, `/e2e-verify #N`)

### Debug Chain (only when coming from /bugfix)

If the current conversation involved /bugfix debugging, add a Debug Chain section:

```
## Debug Chain

- Session 1 [<SESSION_ID>]: Phase 1-3 complete.
    Built failing test (test/xxx.test.ts:42).
    Ruled out:
      - hypothesis 1 (race condition). Evidence: added 10s sleep, bug still reproduced → not timing.
      - hypothesis 2 (cache stale). Evidence: cleared all caches, same failure → not cache.
    Pending: hypothesis 3 (description).
    Key discovery: <domain knowledge learned>.
    Next step: <what to try next>.
```

Each entry must include: phase reached, feedback loop built, hypotheses ruled out (with evidence), hypotheses pending, key discoveries, next step suggestion.

## Step 3 — Archive completed handoffs

When creating a new handoff, check if any existing handoffs in `docs/` are for completed tasks. A handoff is "completed" if its Next Steps have all been done or the task has been closed/merged.

Move completed handoffs to `docs/archive/`:

```bash
mkdir -p docs/archive
mv docs/handoff-<completed-topic>-<MMDD>.md docs/archive/
```

Don't spend time auditing all handoffs — just move the ones you know are done from this session's context.

## Step 4 — Flush decisions to durable docs

Before writing the handoff, check: did this session produce domain decisions, terminology changes, or architectural choices?

- **Terminology / domain model changes** → update `CONTEXT.md`
- **Architectural or design decisions** → create/update ADR in `docs/adr/`
- **Pipeline / workflow decisions** → update the relevant skill or CLAUDE.md

Handoff documents are ephemeral — they get archived once the task is done. Decisions that outlive the task must live in durable docs. If you're unsure whether something is a "decision", ask: would a future session need this even if it's working on a different task? Yes → durable doc. No → handoff only.

Do this flush before writing the handoff, so the handoff can reference the durable doc paths instead of inlining the decisions.

## Rules

- Do not duplicate content in other artifacts (PRDs, ADRs, issues, commits). Reference by path or URL.
- If the user passed arguments, treat them as focus description for the next session.
- Keep it concise — the next session should be able to start working within 1 minute of reading.
