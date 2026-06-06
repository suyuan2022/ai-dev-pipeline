---
name: e2e-verify
description: >
  E2E verification agent. Reads PRD Acceptance Criteria from a GitHub Issue, runs structured
  verification (prerequisites → smoke → core AC → regression → edge states), and reports
  pass/fail evidence. Uses the best method per scenario: DB/curl for data, browser for UI.
  Never gives fix suggestions — only facts.
  Use when user says "e2e-verify" / "e2e" / "验收" / "验证一下" / "跑一下 AC",
  or when the execution flow reaches stage 3c after code review.
---

# /e2e-verify

Verify PRD Acceptance Criteria and regression safety against running code. Report facts. Never suggest fixes.

Position in the execution flow:

```
TDD Coding → Code Review → **E2E Verify (this)** → Commit + PR → Functional Test
```

---

## Input

Issue number. Example: `/e2e-verify #42`

The caller (user or main thread) provides:
- **Round indicator**: `0/3`, `1/3`, `2/3`, `3/3`. If omitted, assume `0/3` (first run).
- **Previous report** (rounds 1/3+): the caller pastes the previous round's report so you know which items failed and what evidence was collected. If not provided, run all items from scratch.

---

## Step 0 — Context & Scope

### Read the PRD

```bash
gh issue view <N> --json body --jq .body
```

Extract:
1. **Acceptance Criteria** — the checklist of verifiable conditions
2. **Verification Setup** — prepared accounts, tools, permissions, environment prerequisites
3. **Low-confidence Areas** — areas where AI verification is unreliable (still test them, but flag results for human re-verification)

Also read:
- Project `.env` / `.env.local` for DB connection, API base URL
- `package.json` scripts for available dev commands

### Read Agent Brief

Check issue comments for `## Agent Brief` from recon — affected files, domain constraints, dependency analysis. Don't repeat this research.

### Determine test scope

Derive the test plan from AC + Verification Setup:

1. **From diff** (if available): extract changed exported symbols → `codegraph_impact` depth=3 → affected API routes + page components
2. **From issue description**: `codegraph_context` with issue keywords → supplement with related modules impact might miss
3. **From file types in diff**: schema changes → grep who uses affected fields/tables; i18n changes → affected pages; template changes → affected render scenarios

Three layers merge → deduplicate → output:
- **Core scope**: AC items (always test all)
- **Regression scope**: impact-hit areas not in AC (test key paths)
- **Edge states**: high-risk starting states for affected user types

**Recommended codegraph usage** (fall back to grep + Read if codegraph unavailable):
- `codegraph_impact <symbol>` → affected downstream modules
- `codegraph_context <keywords>` → broad module survey
- `codegraph_explore <symbols>` → read source of multiple related symbols at once

---

## Step 1 — Prerequisites [BLOCK]

These must pass before any verification. Failure → mark ALL subsequent items as BLOCKED.

| Check | Method | On failure |
|-------|--------|------------|
| Services running | `curl` health check endpoints | All BLOCKED |
| DB accessible | Simple SQL query | All BLOCKED |
| Schema applied | Compare table structure to expected | All BLOCKED |
| Test accounts exist (per state) | DB query | Note which missing, create if possible |
| Environment config correct | Check `.env` key values | Note anomalies |

---

## Step 2 — Data Layer Smoke [BLOCK]

Quick sanity check before going deeper. If APIs return wrong structure, testing UI is pointless.

| Check | Method |
|-------|--------|
| Core APIs return correct structure and values | `curl` + validate response body fields |
| DB state consistent after changes | SQL on affected tables |
| Cross-system data aligned | Compare web DB vs gateway API for same field |

If any smoke check fails → report as FAIL, continue remaining steps but note the smoke failure context.

---

## Step 3 — Core AC Verification

**Verify every AC item.** Principle: **use the lightest method that produces reliable evidence.** Only escalate when a lighter method cannot prove the thing you need to prove.

Weight ladder (lightest → heaviest):

| Weight | Method | Use when |
|--------|--------|----------|
| 1 | DB query / logs / debug probes | Data truth: row exists, field value, constraint, error log entry |
| 2 | curl / API call | Service behavior: endpoint response, side effects, status codes |
| 3 | browser (`/agent-browser`) | UI rendering: element visible, value displayed, page layout |
| 4 | computer-use | Non-web interface: desktop app, native UI |

Rules:
- **Don't escalate needlessly.** If a DB query proves the value is correct, don't open a browser to read the same number off screen — unless the AC specifically requires verifying the UI displays it.
- **Don't read browser console for data you can get from logs or DB.** Console screenshots are unreliable; direct data access is not.
- **UI display requires browser.** Don't just query DB and assume the UI shows it correctly.
- **Cross-layer alignment = both.** DB query + browser to verify data matches display.

Output the plan before executing:

```
Verification plan:
- AC#1: [DB] SELECT ... WHERE ... → expect row exists
- AC#2: [CURL] POST /api/... → expect 200 + body.field == X
- AC#3: [BROWSER] open /settings/billing → check "已用/总额" display
- AC#4: [DB+BROWSER] query grantedRmb → open page → compare values
- AC#5: [SKIP→手测] UX interaction feel
```

---

## Step 4 — Regression Check

**Test areas identified in Step 0 scope analysis.** Not a full test — targeted checks on impact-hit modules.

For each regression area:
1. Identify the key user path through that module
2. Run one representative verification (DB/curl/browser as appropriate)
3. Pass → sufficient. Fail → regression, report as FAIL.

Label regression items separately in the report: `REG#1`, `REG#2`, etc.

---

## Step 5 — Edge States

**Enumerate high-risk starting states** for users affected by the change. Only test states where failure is plausible:

Examples:
- Expired account → does feature degrade gracefully?
- Zero-balance account → no division-by-zero errors?
- Never-activated account → feature area correctly hidden?
- Paid user → trial-specific UI not shown?

Label edge items: `EDGE#1`, `EDGE#2`, etc.

---

## Report

Output format — no deviation:

```
## E2E Verification Report — Issue #N (round M/3)

### Scope
- Core: X AC items
- Regression: Y impact-hit areas
- Edge: Z starting states

### PASS
- AC#1: [method] [action] → [actual result] → [evidence]
- REG#1: [method] [action] → [actual result]
- EDGE#1: [method] [action] → [actual result]

### FAIL
- AC#2:
  - Method: [DB/curl/browser]
  - Action: [what was done]
  - Expected: [from PRD]
  - Actual: [what happened]
  - Evidence: [query result / response body / observation]
  - PRD ref: Acceptance Criteria #2

### SKIP (needs human verification)
- AC#5: UI interaction feel → mark for /functional-test

### BLOCKED (could not execute)
- AC#4: DB connection refused — check if dev server is running
```

Rules:
- Every AC item must appear in exactly one category
- Regression and edge items also categorized (PASS / FAIL / BLOCKED)
- FAIL items: include enough evidence to locate the problem — but NO fix suggestions
- SKIP items: explain why automated verification is not possible
- BLOCKED items: include the error so the caller can unblock

---

## Round rules

The caller tracks rounds. This skill receives the round indicator as input.

| Round | Trigger |
|-------|---------|
| 0/3 | First run after code review |
| 1/3 | Re-run after first fix attempt |
| 2/3 | Re-run after second fix attempt |
| 3/3 | Final attempt — if still failing, escalate |

On rounds 1/3, 2/3, 3/3: focus on previously FAILed items, but also re-verify PASSed items to catch regressions.

---

## Exit conditions

After producing the report, state the verdict:

- **All PASS, no BLOCKED** (SKIP is acceptable) → "Ready for commit + PR"
- **All PASS but BLOCKED exists** → "Unverified items remain. Resolve BLOCKED before commit."
- **FAIL exists, round < 3/3** → "FAIL detected. Escalate to /bugfix. Next round: M+1/3"
- **Same FAIL on round 3/3** → "3 rounds exhausted. Stop and report to human."
- **New FAIL appeared that was PASS before** → "Regression detected. Escalate to /bugfix"

On any escalation to /bugfix: include in the report which items failed, what evidence was collected across rounds, and what was tried. This becomes the input context for /bugfix Phase 0.

---

## Boundaries

- This skill verifies. It does not fix, refactor, or suggest code changes.
- This skill reads code for verification purposes only (e.g., checking a config value). It does not modify files.
- If the PRD has no Acceptance Criteria, refuse to run. Say: "No Acceptance Criteria in Issue #N. Cannot verify."
- If all AC items are SKIP (all require human verification), say so and recommend /functional-test directly.
