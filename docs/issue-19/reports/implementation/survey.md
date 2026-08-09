# Survey — issue #19 (adopt test-env resolution convention)

## Scout: skipped
Skip condition: the spec (on-the-record `docs/specs/test-env-resolution.md`,
issue #551) leaves no open design decision — it gives the exact resolution
order, the SKIP contract (message + exit 75), and a per-consumer-shape
adoption recipe including the "Bash test runner" case that matches this
repo's harness. Nothing to scout externally; only local adoption remains.

## Current state
- Test surface: exactly one test script, `tests/run-gate-tests.sh` — a bash
  harness that spawns each gate hook as a subprocess and asserts its exit
  code (0=allow, 2=deny). No pytest/python test suite exists in this repo.
- Every gate hook it drives (`capacity-forecast-method/hooks/forecast-method-gate.sh`,
  `capacity-order-enforcement/hooks/citation-gate.sh`,
  `capacity-threshold-decomposition/hooks/threshold-gate.sh`,
  `capacity-headroom-costnote/hooks/headroom-gate.sh`,
  `capacity-planning/hooks/capacity-fields-gate.sh`) sources core's
  `hooks/lib/gate-lib.sh` via:
  `. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd .../../../core && pwd -P)}/hooks/lib/gate-lib.sh" || exit 2`
  — i.e. env var first, else a hardcoded `../../core` sibling guess, else
  exit 2 (deny/fail-closed).
- On a plain `main` checkout (no `CLAUDE_PLUGIN_ROOT_CORE`, no `../../core`
  sibling), every `run` case in `run-gate-tests.sh` that expects `allow`
  gets `deny` instead (`want=allow got=deny`) — a misleading FAIL, not a
  true assertion failure. This is exactly the ambiguity issue #551 exists
  to remove.
- One test group already exists that specifically wants deny-on-missing-core
  (`missingcore()`, lines 343-354) — it force-sets
  `CLAUDE_PLUGIN_ROOT_CORE=/nonexistent-core-$$` and asserts deny. This
  group is unaffected by the convention: it tests the fail-closed guard
  itself, not core-dependent gate logic, so it must keep running (and
  passing) even when core is genuinely unreachable.
- No `.env.example`, dependency manifest, or migration is implicated — the
  only write surface is the test runner script itself.

## Reference convention (external, on-the-record issue #551)
`docs/specs/test-env-resolution.md` (in the sibling `on-the-record-issue-551-
implementation` checkout) defines: resolve `$CLAUDE_PLUGIN_ROOT_CORE` (if it
contains a non-empty `hooks/lib/gate-lib.sh`) → else the first caller-supplied
sibling candidate with the same file → else SKIP: print
`SKIP: core plugin unreachable — unverifiable outside spawn env` to stderr,
exit 75 (`EX_TEMPFAIL`, distinct from this repo's own 0/1/2 gate exits). It
ships a reference Python module (`gates.test_env_resolve`) with a CLI mode
for exactly the "Bash test runner" adoption shape this repo has — invoke as
`python3 -m gates.test_env_resolve <candidates...>`, branch on exit code.

## Write set implicated
- `tests/run-gate-tests.sh` — the only file that needs to change. It must
  resolve core once, up front, before running any core-dependent case
  group; on SKIP, print the SKIP message and exit 75 for those groups
  without recording them as failures; the `missingcore()` group stays
  unconditional (it doesn't need real core).
