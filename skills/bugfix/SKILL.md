---
name: bugfix
description: >
  All bugs start here. Disciplined 7-phase diagnosis loop (Phase 0-6) for bugs and performance regressions.
  Load context → build feedback loop → reproduce → hypothesise → instrument → fix → knowledge capture.
  Use when user says "bugfix" / "fix this bug" / reports a bug / says something is broken/throwing/failing /
  describes a performance regression, or when E2E verification fails.
---

# /bugfix

All bugs start here. Skip phases only when explicitly justified.

Core methodology: Matt Pocock's 6-phase diagnose loop (Phase 1-6), with Phase 0 (context loading) and enhanced Phase 5-6.

**Phase declaration rule**: Every phase transition must be declared: `## Entering Phase N` / `## Phase N complete`. Never silently skip.

---

## Phase 0 — Load context

Before touching code, read (skip if not present):

1. **CONTEXT.md** — domain terms and concept relationships
2. **docs/specs/\<area\>.md** — known pitfalls, invariants. Check if this bug matches an existing pitfall first.
3. **Relevant docs/adr/** — architectural decisions in the area
4. **Bug context** — Issue full text, PRD + E2E report (if from E2E failure), or conversation context

If the Issue has a Debug Chain (see [multi-session.md](multi-session.md)), continue from the last state — do not re-test ruled-out hypotheses.

---

## Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a fast, deterministic, agent-runnable pass/fail signal for the bug, you will find the cause — bisection, hypothesis-testing, and instrumentation all just consume that signal. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

### Ways to construct one — try them in roughly this order

1. **Failing test** at whatever seam reaches the bug — unit, integration, e2e.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) — drives the UI, asserts on DOM/console/network.
5. **Replay a captured trace.** Save a real network request / payload / event log to disk; replay it through the code path in isolation.
6. **Throwaway harness.** Spin up a minimal subset of the system (one service, mocked deps) that exercises the bug code path with a single function call.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit, dataset, version), automate "boot at state X, check, repeat" so you can `git bisect run` it.
9. **Differential loop.** Run the same input through old-version vs new-version (or two configs) and diff outputs.
10. **HITL bash script.** Last resort. If a human must click, drive _them_ with `scripts/hitl-loop.template.sh` so the loop is still structured. Captured output feeds back to you.

Build the right feedback loop, and the bug is 90% fixed.

### Iterate on the loop itself

Treat the loop as a product. Once you have _a_ loop, ask:

- Can I make it faster? (Cache setup, skip unrelated init, narrow the test scope.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

A 30-second flaky loop is barely better than no loop. A 2-second deterministic loop is a debugging superpower.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop the trigger 100x, parallelise, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; 1% is not — keep raising the rate until it's debuggable.

### When you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Ask the user for: (a) access to whatever environment reproduces it, (b) a captured artifact (HAR file, log dump, core dump, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Do **not** proceed to hypothesise without a loop.

Do not proceed to Phase 2 until you have a loop you believe in.

---

## Phase 2 — Reproduce

Run the loop. Watch the bug appear.

Confirm:

- [ ] The loop produces the failure mode the **user** described — not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] The failure is reproducible across multiple runs (or, for non-deterministic bugs, reproducible at a high enough rate to debug against).
- [ ] You have captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually addresses it.

Do not proceed until you reproduce the bug.

---

## Phase 3 — Hypothesise

Generate **3-5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If \<X\> is the cause, then \<changing Y\> will make the bug disappear / \<changing Z\> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe — discard or sharpen it.

**Root-cause depth**: Your hypothesis should explain WHY the bug occurs, not just WHAT occurs. "User object is null" is a symptom. "User query returns null because the session cache expires before the token does" is a root cause. Keep asking "why?" until you reach a cause that, if fixed, eliminates the symptom without special-casing.

**Show the ranked list to the user before testing.** They often have domain knowledge that re-ranks instantly ("we just deployed a change to #3"), or know hypotheses they've already ruled out. Cheap checkpoint, big time saver. Don't block on it — proceed with your ranking if the user is AFK.

If uncertain about fix approach for multi-module / state-machine / migration bugs, use `/prototype` to validate before modifying production code.

---

## Phase 4 — Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger / REPL inspection** if the env supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

**Perf branch.** For performance regressions, logs are usually wrong. Instead: establish a baseline measurement (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.

---

## Phase 5 — Fix + regression test

### Fix anti-patterns (read before writing any fix code)

- **Fixing at the symptom site**: If your fix is a null check, try-catch, or fallback at the crash point, you're hiding the bug, not fixing it. Trace back to where the incorrect state was created.
- **Fixing by addition only**: Bug fixes should often REMOVE or CORRECT code, not add new code. If your fix is purely additive (new if-branch, new wrapper, new special case), ask whether existing code is wrong rather than missing.
- **Fixing by loosening**: If your fix makes validation more permissive, accepts wider input, or skips a check — you're probably creating a new bug to hide the current one.
- **Fixing by duplication**: If your fix copies existing logic to handle the edge case separately, you now have two places to maintain. Extend the original logic instead.
- **Fixing with unexplained magic**: If your fix works but you can't explain the causal chain from fix → symptom disappears, you haven't found the root cause. A correct fix has an obvious, explainable connection to the hypothesis from Phase 3.

### Regression test

Write the regression test **before the fix** — but only if there is a **correct seam** for it.

> **Do not write tests that merely restate the implementation.** A test that mocks all dependencies and then asserts the mocks were called provides zero confidence — it will pass even if the implementation is completely wrong. Tests must verify observable behavior through real (or realistically integrated) code paths.

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (single-caller test when the bug needs multiple callers, unit test that can't replicate the chain that triggered the bug), a regression test there gives false confidence.

**If no correct seam exists, that itself is the finding.** Note it. The codebase architecture is preventing the bug from being locked down. Flag this for Phase 6.

If a correct seam exists:

1. Turn the minimised repro into a failing test at that seam.
2. Watch it fail.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario.

---

## Phase 6 — Cleanup + knowledge capture (NEVER SKIP)

Cleanup checklist:

- [ ] Original repro no longer reproduces (re-run Phase 1 loop)
- [ ] Regression test passes (or absence of seam documented)
- [ ] All `[DEBUG-...]` instrumentation removed
- [ ] The correct hypothesis is stated in the commit message

Knowledge capture — answer all three, even if the answer is "none":

**Q1: "What domain knowledge did I learn that I didn't know before?"**
→ update `CONTEXT.md` (new terms, concept relationships, corrections). Format: follow `CONTEXT-FORMAT.md`.

**Q2: "What pitfalls should the next person writing code here know?"**
→ write/update `docs/specs/<area>.md`. Format: `[condition] → [invariant] + [consequence of violation]`.
- Example: "When modifying SubscriptionCredit.expiresAt, must sync tokenRemainQuota on the gateway side. Violation: quota mismatch between gateway and billing."
- Example: "Trial credit cleanup only triggers on first payment, not on renewal. Violation: user's historical quota zeroed on renewal."

**Q3: "What architectural change would fundamentally prevent this class of bug?"**
→ hand off to `/improve-codebase-architecture` with specifics, or record "none".

Path escalation: design flaw (not bug) → `/grill-with-docs` → `/to-prd`. Scope exceeds Issue → file a new Issue.

Exit routing: if entered from E2E failure → re-run `/e2e-verify` after fix. If entered from `/functional-test` → return and continue remaining tests.

Methodology flaw noticed? Tell user directly, or append to `bugfix/IMPROVEMENTS.md` if autonomous.

---

See [multi-session.md](multi-session.md) for handoff protocol and debug chain format.
See [handoffs.md](handoffs.md) for full entry/exit point reference.

