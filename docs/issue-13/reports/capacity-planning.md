# Record — issue-13 (gate A+ final closeout: 2026-08-01 재감사 잔여 결함, grade B)

Subject: issue-13. Phase 2 execution of the approved proposal
([gate-a-plus-final-closeout.md](../proposals/gate-a-plus-final-closeout.md)),
approved via `APPROVE issue-13/capacity-planning` issue comment
(single-account mode, `docs/specs/approvers.md`-listed account
`JiwonJung94`). Basis: survey.md and scout-brief.md under
`docs/issue-13/reports/capacity-planning/`.

## Why

The 2026-08-01 재감사(등급 B) named six concrete residual defects plus a
README/manifest cleanliness requirement, on top of two already-landed
precondition fixes (core issue-75's mandatory source guard + missing-core
test group; on-the-record issue-182's `CLAUDE_PLUGIN_ROOT_CORE` injection
at role-session spawn). This record executes the proposal's fix plan
against those defects.

## What was done

**Item 1 — source guard, all 5 gates + `capacity-planning/directive.sh`.**
Every `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"` (and the
`role-directive.sh` source in `capacity-planning/hooks/directive.sh`) now
carries core-75's mandatory `||` guard verbatim, substituting each script's
own filename: `. "$path" || { echo "<name>.sh: cannot source <lib>.sh" >&2; exit 2; }`.
An unreachable-core source now fails closed (exit 2) instead of leaving
`gate_kill_switch_active` undefined and every `... || { exit 0; }` call site
reading the resulting "command not found" (127) as the kill switch being
off.

**Item 2 — subshell rc mischeck, 4 call sites, `= 2`/`-eq 2` → `!= 0`/`-ne 0`.**
Fixed in `capacity-fields-gate.sh` (both call sites),
`forecast-method-gate.sh`, `citation-gate.sh`, and `headroom-gate.sh`'s
first (JSON-parse-stage) check. Any nonzero exit from the embedded Python —
not only `deny()`'s `sys.exit(2)` — now denies instead of silently falling
through to an empty-scope allow.

**Item 3 — symlink-safe root, all 5 gates.** Each gate's Python payload now
computes `root = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))`
before calling `gate_lib.gate_normalize_path(root, fp)`, per
`gate_normalize_path`'s own documented contract (pure string algebra, no
filesystem touch — callers needing symlink-safe resolution must realpath
their own root first). `gate_normalize_path` itself is untouched
(core-owned, out of this rulebook's `write_scope: []`).

**Item 4 — percentile regex word boundary, `threshold-gate.sh`, 2 sites.**
`grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위'` → requires a
non-alphanumeric-or-start-of-string boundary before the `p`:
`(^|[^[:alnum:]])p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위`, at both the
percentile-presence check and the shared flat-percentage-prohibition check.
`cap95`/`step2`/`http2`-style incidental `p`+digit substrings no longer
satisfy a real percentile requirement.

**Item 5 — headroom gate: scope to a slice, not the whole document.**
`headroom-gate.sh` now extracts a headroom heading's slice (search for
`^#+[^\n]*(headroom|여유 용량|헤드룸)[^\n]*\n(.*?)(?=\n#+\s|\Z)`, case-insensitive)
and a separate cost-note heading's slice, before running the
band-not-snapshot and cost-attribution checks against each slice instead of
the whole reconstructed `$content` — same fallback-to-whole-content
discipline `threshold-gate.sh` already uses when no matching heading
exists.

**Item 6 — standalone `Edit`-tool test coverage, all 5 gates.**
`tests/run-gate-tests.sh` gained a "standalone Edit-tool reconstruction"
mandatory case group: one allow + one deny `"tool_name":"Edit"` case per
gate (10 new cases), closing the gap between the advertised
`Write|Edit|MultiEdit` hooks.json matcher and what the suite previously
exercised (only `Write` and one shared `MultiEdit` fixture).

**Item 7 — README ghost-path removal + full link-walk verification.**
Removed the `capacity-planning/agents/warrant-hunter.md` line from
`README.md`'s "Layout" section (confirmed nonexistent — no `agents/`
directory exists in this repo). Re-walked every relative path
`README.md` and `.claude-plugin/marketplace.json`/each plugin's
`.claude-plugin/plugin.json` cite: all resolve locally except
`docs/handbooks/gate-house-standard.md`, which is a documented cross-repo
canon reference (core's own handbook, never vendored — same convention
`docs/issue-2/reports/implementation.md` already establishes for
`trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`), not
a ghost path. No stale role name found (`capacity-planning`,
`performance-engineering` both current per on-the-record's `roles/`
registry, confirmed at survey time).

## Requirement 2 — hooks.json matcher vs. code coverage parity

Confirmed already parity-correct in code: all five `hooks.json` files
advertise `"Write|Edit|MultiEdit"`, and every gate's Python payload calls
`gate_lib.gate_reconstruct_write`, which handles all three tool shapes.
The gap was test coverage only (item 6 above), not a code-reachability
gap — no source change was needed for this requirement.

## Requirement 3 — missing-core case + compliance-check green

Added a "missing-core denies" mandatory case group to
`tests/run-gate-tests.sh` (5 new cases: one per gate, `CLAUDE_PLUGIN_ROOT_CORE`
pointed at a nonexistent path, asserting deny/exit-2) — the same shape
core-75's `run-gate-lib-tests.sh` made mandatory. Full suite result:

```
$ bash tests/run-gate-tests.sh
...
pass=68 fail=0
```

`compliance-check.sh` (core canon, referenced not vendored) against this
rulebook's `hooks/` tree:

```
$ bash <core>/core/hooks/tests/compliance-check.sh .
compliance-check: ok — ./capacity-order-enforcement/hooks/citation-gate.sh
compliance-check: ok — ./capacity-threshold-decomposition/hooks/threshold-gate.sh
compliance-check: ok — ./capacity-headroom-costnote/hooks/headroom-gate.sh
compliance-check: ok — ./capacity-forecast-method/hooks/forecast-method-gate.sh
compliance-check: ok — ./capacity-planning/hooks/capacity-fields-gate.sh
```

All 5 gates: ok, no reasons. Both before-state gaps compliance-check
checks for (unguarded source, hand-rolled kill switch) are closed by item 1
and the pre-existing gate-lib adoption from issue-10.

## Requirement 4 — README/manifest ghost path / stale role name = 0

One confirmed ghost path (`warrant-hunter.md`) removed (item 7). Full
link-walk this record performed found no second ghost path and no stale
role name — `docs/handbooks/gate-house-standard.md` is a legitimate
cross-repo canon reference, not a ghost path (see item 7 rationale).

## Doc-placement ladder

- [x] Gate scripts (`capacity-planning/hooks/capacity-fields-gate.sh`,
  `capacity-planning/hooks/directive.sh`,
  `capacity-order-enforcement/hooks/citation-gate.sh`,
  `capacity-threshold-decomposition/hooks/threshold-gate.sh`,
  `capacity-headroom-costnote/hooks/headroom-gate.sh`,
  `capacity-forecast-method/hooks/forecast-method-gate.sh`) — edited in
  place, existing hook files under each plugin's `hooks/`.
- [x] `tests/run-gate-tests.sh` — edited in place, existing test harness.
- [x] `README.md` — edited in place, ghost-path line removed.
- [x] `docs/issue-13/reports/capacity-planning.md` — this record, the
  role's own phase-2 deliverable home.

## What did not work

None. All seven fix-plan items and both explicit requirements (matcher/code
parity confirmation, missing-core + compliance-check green) landed on the
first pass; the full local suite (68/68, including the new Edit-coverage
and missing-core mandatory groups) and `compliance-check.sh` against all
five gates passed clean without a corrective iteration.

## Next steps

None. No hand-off: every item in this issue's scope was gate/test/doc
remediation work this role's phase-2 record surface already covers
(fix-plan execution against an approved proposal), not a resource-forecast/
expansion-timing decision that would belong to another role.

## Open findings

None outstanding.

loop_state: landed
