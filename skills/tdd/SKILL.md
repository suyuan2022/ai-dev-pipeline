---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification - "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 0. Context Loading

Before planning anything, load the execution context:

1. **Read the issue/PRD**: `gh issue view <N>` — extract Requirements and Acceptance Criteria. These are your test behavior source. If no issue number is available (interactive CC session), use conversation context.
2. **Read domain context**: `CONTEXT.md` + relevant specs from `docs/specs/` + relevant ADRs from `docs/adr/`. Match test names and interface vocabulary to the project's domain language.
3. **Read Agent Brief** (if exists): Check issue comments for an `## Agent Brief` section from recon — it contains affected files, domain constraints, and dependency analysis. Don't repeat this research.

The issue body is your spec. Tests verify the behaviors described in Requirements and AC, not behaviors you imagine.

### 1. Planning

Before writing any code:

- [ ] Derive interface changes from PRD Requirements
- [ ] Extract testable behaviors from Requirements + Acceptance Criteria
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](interface-design.md)
- [ ] List the behaviors to test (not implementation steps) — prioritize: AC items first, then critical paths, then complex logic
- [ ] **Autonomous mode** (Codex): proceed with the plan. **Interactive mode** (CC): confirm with user.
- [ ] **Create todo items**: Use the todo tool to create one task per behavior. Each task = one RED→GREEN cycle. Mark `in_progress` before starting, `completed` after GREEN passes. This is your drift anchor — don't skip behaviors, don't invent new ones mid-flight.

**You can't test everything.** Focus testing effort on AC items and critical paths, not every possible edge case.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

GREEN-stage guardrails (check before moving on):

- If your GREEN code adds a conditional into an unrelated flow, stop. That logic belongs behind its own abstraction, not scattered across existing paths.
- If your GREEN code creates a helper/wrapper called from only one place, delete it. Inline until REFACTOR proves the abstraction is earned.
- Before writing new utility code, search the codebase for existing helpers that already do this.
- If your GREEN code pushes any file past 1000 lines, stop and decompose before continuing.

### 4. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] **Code judo check**: Can you change the model, interface, or data structure so that whole branches of code disappear? Don't tidy complexity — delete it.
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

### 5. Cleanup

After all behaviors are implemented and refactored:

- [ ] Remove test scaffolding, debug logging, and temporary fixtures
- [ ] Delete unused imports and dead code introduced during GREEN iterations
- [ ] Verify no test relies on implementation details that survived from early iterations
- [ ] Run full test suite one final time

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
[ ] Test is NOT a restatement of implementation logic
```

## Zero-Value Test Prohibition

**Do not add tests that merely restate implementation.** These tests provide zero confidence:

- Mocking all dependencies then verifying the mock was called — you're testing that your mock works, not that your code works
- Asserting the return value of a function you just wrote by copying its logic into the test
- Testing that a wrapper calls the thing it wraps

If removing the implementation and replacing it with something completely different (but behaviorally equivalent) would break your test, the test is coupled to implementation, not behavior. Delete it.
