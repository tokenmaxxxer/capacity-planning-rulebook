---
status: proposed
files:
  - tests/run-gate-tests.sh
---

## Request
Adopt the canonical test-env resolution convention landed at
`docs/specs/test-env-resolution.md` (issue #551) in this rulebook's
gate-test script: outside the spawn env (no `CLAUDE_PLUGIN_ROOT_CORE`, no
resolvable core sibling), the run should SKIP with the convention's
explicit message and distinct exit code instead of reporting misleading
`FAIL`s. Assertions that run when core is reachable must not weaken.

## Constraints
- Scout skipped: the spec fully specifies the resolution order, the SKIP
  contract, and the "Bash test runner" adoption recipe — no open design
  decision to research externally (see survey.md).
- The `missingcore()` case group (lines 343-354 of
  `tests/run-gate-tests.sh`) asserts fail-closed deny when core is
  genuinely unreachable — it must keep running unconditionally, since it
  is testing the guard itself, not core-dependent gate behavior.
- No new dependency manifest, `.env.example`, or migration is implicated.

## Rationale
Considered vendoring the on-the-record reference module
(`gates/test_env_resolve.py`) into this repo and invoking it via
`python3 -m gates.test_env_resolve <candidates...>` per the doc's literal
"Bash test runner" recipe. Rejected: this repo has no Python test
infrastructure at all (single bash harness, no `gates/` package, no
pytest), so vendoring a Python module and package scaffold for one CLI
call is a heavier footprint than the change needs and adds a
cross-language dependency this repo doesn't otherwise have. Instead,
implement the same resolution order and SKIP contract (env var → sibling
candidates → SKIP message + exit 75) directly in bash inside
`tests/run-gate-tests.sh`, referencing the convention doc by path so the
adoption is traceable and the exit-code contract matches exactly.

## What will be done
- At the top of `tests/run-gate-tests.sh`, add a `resolve_core()` step
  that: checks `$CLAUDE_PLUGIN_ROOT_CORE` for a non-empty
  `hooks/lib/gate-lib.sh`; else checks sibling candidates (`../core`,
  `../../core`, `../../tokenmaxxxer-core/core`); else prints
  `SKIP: core plugin unreachable — unverifiable outside spawn env` to
  stderr and exits 75, without running any core-dependent case group.
- Export the resolved path as `CLAUDE_PLUGIN_ROOT_CORE` for the rest of
  the run so gate hooks under test resolve core consistently.
- Add a one-line comment referencing
  `docs/specs/test-env-resolution.md` (issue #551) so `grep -r
  test-env-resolution` finds the adoption.
- Leave the `missingcore()` group's own `CLAUDE_PLUGIN_ROOT_CORE`
  override untouched — it deliberately forces core-unreachable and
  asserts deny, independent of the new top-of-script resolution.
- Run the test script once locally (with and, if a core sibling is
  reachable, without the override) to confirm the SKIP path and the
  reachable-core path both behave as specified.

## Out of scope
- Vendoring the Python reference module or adding a `gates/` package.
- Changing gate hook scripts themselves (`*-gate.sh`, `directive.sh`) —
  their own `${CLAUDE_PLUGIN_ROOT_CORE:-...}` fallback is unchanged;
  only the test runner's resolution/skip behavior changes.
- Any other rulebook repo's adoption (tracked per-repo per issue #551's
  own scope note).

## How you'll know it worked
- On a plain checkout with `CLAUDE_PLUGIN_ROOT_CORE` unset and no
  resolvable sibling: running `tests/run-gate-tests.sh` prints the SKIP
  message and exits 75, with zero misleading `FAIL` lines.
- With `CLAUDE_PLUGIN_ROOT_CORE` pointed at a real core checkout: all
  previously-passing `run`/`missingcore` assertions still pass unchanged.
- `grep -rn test-env-resolution tests/` finds the reference.
