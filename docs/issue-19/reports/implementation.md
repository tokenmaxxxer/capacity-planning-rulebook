---
code_under_review:
  - tests/run-gate-tests.sh
type: fix
breaking: false
verdict: pass
loop_state: landed
---

# Implementation record — issue #19

## What was done
Adopting the canonical test-env resolution convention
(`docs/specs/test-env-resolution.md`, issue #551) into
`tests/run-gate-tests.sh` per the approved proposal
`docs/issue-19/proposals/adopt-test-env-resolution.md`.

## Why
Outside the spawn env (no `CLAUDE_PLUGIN_ROOT_CORE`, no resolvable core
sibling), every `run`/`runedit`/etc. case that expects `allow` gets `deny`
instead — a misleading FAIL caused by core being unreachable, not a real
regression. The convention's SKIP contract (explicit message, exit 75)
removes that ambiguity.

## Upstream / basis
docs/issue-19/proposals/adopt-test-env-resolution.md

## Open findings
None.

## What did not work
None.

## Verification run (this session)
- With `CLAUDE_PLUGIN_ROOT_CORE` reachable: `bash tests/run-gate-tests.sh`
  → `pass=72 fail=0`, exit 0.
- With `CLAUDE_PLUGIN_ROOT_CORE` unset and no resolvable sibling
  (`env -u CLAUDE_PLUGIN_ROOT_CORE bash tests/run-gate-tests.sh`) →
  `SKIP: core plugin unreachable — unverifiable outside spawn env` on
  stderr, exit 75.
- `grep -n test-env-resolution tests/run-gate-tests.sh` finds the
  reference comment.

## Doc-placement ladder
- [x] No env var/config key/new dep/migration/setup step introduced — no
  handbook update needed.
- [x] No library-or-format choice over a named alternative and no changed
  public signature/wire format beyond what the proposal's Rationale
  already recorded — no new `docs/issue-19/decisions/` entry needed.
- [x] No benchmark/investigation numbers beyond the verification run
  above — recorded in this record, not a separate report.
