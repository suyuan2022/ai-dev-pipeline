---
name: to-prd
description: Turn the current conversation context into a PRD and publish it to the project issue tracker. Use when user wants to create a PRD from the current context.
---

The next agent has zero access to this conversation. Every decision, constraint, boundary condition, rejected alternative must be listed individually. No "等", no "之类的", no "主要包括", no merging similar items. Missing one item is a defect.

Default to synthesis — derive from code, docs, conversation. Don't ask what you can look up.

## Complexity Grade

| Grade | Signal | Scope |
|-------|--------|-------|
| Trivial | Single-line fix, typo | No PRD — implement directly |
| Simple | Clear goal, 1–2 files | Lightweight: skip *(M/C)* sections, one confirmation at Phase 1 |
| Moderate | Multiple files, some ambiguity | Standard |
| Complex | Architectural choices, vague goal | Full, all sections |

---

## Phase 1 — Explore & Sketch

1. Read `CONTEXT.md`, relevant `docs/adr/`, relevant `docs/specs/`
2. Explore codebase for current state
3. Sketch modules to build/modify — seek deep modules (much functionality, simple testable interface, stable)
4. Consider 1–3 month evolution and failure/edge cases, then converge: in-scope → Requirements, out → Out of Scope

**Output this, then stop and wait for user response:**

> ## Scope Confirmation
>
> Based on [grill discussion / issue / conversation context], this feature covers:
> - [User-visible capability 1] ([repo])
> - [User-visible capability 2] ([repo])
> - ...
>
> Anything missing? Anything that should be excluded?

---

## Phase 1.5 — Context Sufficiency Check *(skip for Trivial/Simple)*

Internally verify you can fill every PRD section from conversation + code + docs:
Problem Statement, Solution, Requirements, AC, Future Considerations, Implementation Decisions (Behavior / Module+Interface), Decisions completeness, Risk Scenarios, Testing Decisions, E2E Plan, Manual Test, Out of Scope, cross-repo routing, context conflicts.

Sections you can derive → derive silently in Phase 2. Technical sections (Testing, technical AC details) → derive from code/docs, write directly into PRD.

**Output ONLY items the user can decide, then stop and wait for user response:**

> ## Before writing the PRD
>
> **1. "Done" — does this cover it?**
> - [plain-language capability that must work]
> - [plain-language capability that must work]
> - ...
>
> **2. E2E verification scope**
> Test these flows:
> - [flow in user language]
> - ...
>
> Blocked until: *(only if dependencies exist)*
> - [prerequisite that must be done/deployed first — e.g. "#120 deployed with session ID injection"]
>
> Verification methods:
> - DB queries: [yes/no — what DB access]
> - curl/API: [yes/no — what endpoints]
> - browser-use: [yes/no/uncertain — needed for what]
> - computer-use: [yes/no/uncertain — needed for what]
>
> Need from you: *(only if something is missing or uncertain)*
> - [missing account / permission / capability — with recommended solution]
>
> **3. Hand-test focus**
> - [thing requiring human judgment]
> - ...
>
> **4. Issue routing** *(only if cross-repo)*
> - [repo]: [update #N / create new]
> - [repo]: [update #N / create new]
>
> **5. Conflicts** *(only if conversation contradicts code)*
> - [issue says X, code does Y — which is correct?]

Sections 4–5 only appear when applicable. All items resolved → Phase 2.

---

## Phase 2 — Write PRD

Fill every section of the template. Sections marked *(M/C)* skip for Simple.

**Filling guidance** (for you only — do NOT output these instructions into the PRD):

| Section | How to fill |
|---------|------------|
| Requirements | `[condition] → [behavior] + [constraint]`. Developer can code from it or break down further |
| Acceptance Criteria | From Requirements. Each → automatable verification: `Action → Expected → verify via [method]` |
| Impl — Behavior | Domain language: how the system behaves |
| Impl — Module+Interface | Which modules change, how interfaces change. Use CONTEXT.md terms |
| Impl — Locator | Paths found during exploration. Reference-only caveat |
| Decisions | Context → Decision → Rejected alternatives + reason. Architectural → also `docs/adr/` |
| Risk Scenarios | Source: grill + `docs/specs/` invariants + CONTEXT.md. Include attribution per item |
| Testing | Requirement → observable behavior → test. AC → failure input → boundary. Search `*.test.*` for prior art. No mock-only tests |
| E2E Plan | Per AC, e2e-verify Step 0-5. Environment: derive from project docs. Agent capabilities: explicitly check browser-use and computer-use availability — never assume, never fabricate. Prerequisites: list what must be deployed/ready before E2E can run |
| 手测 | Human judgment only: subjective UX, visual polish, cross-device feel. Data correctness / UI existence → E2E |

**Completeness:** every non-*(M/C)* section must be non-empty. If empty → missed in Phase 1.5, go back.

Output the complete PRD, then proceed to Phase 3.

---

## Phase 3 — Publish

1. Issue exists → `gh issue edit` replace body
2. No issue → `gh issue create`. Cross-repo per Phase 1.5 routing: `--repo <org/repo>`
3. Multi-repo → linked issues, cross-references in Further Notes
4. Label: `ready-for-agent`
5. Output: `读 gh issue view #N --json body 开始执行`

---

## PRD Template

<prd-template>

# <Title>

## Problem Statement

## Solution

## Requirements

## Acceptance Criteria

- [ ] [Action] → [Expected] — verify via [method]

## Future Considerations *(M/C)*

## Implementation Decisions

### Behavior Layer

### Module + Interface Layer

### Locator Layer

> Reference only — execution agent must explore independently.

## Decisions

- **Context**: ...
- **Decision**: ...
- **Alternatives rejected**: ... — because ...

## Risk Scenarios

Each with source: `From docs/specs/xxx.md: ...` / `From grill: ...` / `From CONTEXT.md: ...`

## Testing Decisions *(M/C)*

- **行为**: [what] — via [method]
- **边界**: [edge] — expect [outcome]
- **参考**: `path/to/similar.test.ts`

## E2E Verification Plan *(M/C)*

- **Environment**: tools, accounts, permissions
- **Step 0 范围**: routes, pages, modules
- **Step 1 前置**: services, DB, migrations, accounts
- **Step 2 冒烟**: API smoke tests
- **Step 3 核心**: by user journey — `[DB]`/`[CURL]`/`[BROWSER]`/`[BLOCK]`
- **Step 4 回归**: affected-but-not-target
- **Step 5 边缘**: high-risk starting states

## 手测 Checklist *(M/C)*

Each tagged `[HUMAN]` or `[AI]`.

## Knowledge Base References

## Out of Scope

## Further Notes

</prd-template>
