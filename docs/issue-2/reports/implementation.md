# Record — issue-2 (core canon reference switch)

Subject: issue-2. Phase 2 execution of the approved proposal
([core-canon-reference-switch.md](../issue-2/proposals/core-canon-reference-switch.md)).

## Why

Core issues #63/#66 landed a single canon for the warrant-hunt agent and
the three role-agnostic gates plus the `core_role_directive` boilerplate
function. Continuing to vendor local copies in this rulebook produces
drift (core issue #66's survey found 38/40-unique-hash divergence across
rulebooks) and leaves this repo's gate copies as unconditional
placeholders instead of the now-load-bearing core versions. This issue
executes the approved switch so this rulebook references core canon
instead of vendoring it, ahead of this rulebook's own "룰북 성숙화"
phase-2 issue per the ordering constraint in issue #2.

## What was done

1. Deleted `capacity-planning/agents/warrant-hunter.md` (proposal item 1).
   No replacement added — the role-agnostic hunt agent now lives at
   `warrant/agents/warrant-hunter.md` in core (core issue #63).
2. Deleted `capacity-planning/hooks/trailer-gate.sh`,
   `capacity-planning/hooks/record-fields-gate.sh`,
   `capacity-planning/hooks/handbook-trigger-gate.sh` and rewrote
   `capacity-planning/hooks/hooks.json` to drop their `PreToolUse` entries,
   leaving only the `SessionStart` entry for `directive.sh` (proposal
   item 2). Core's own `core/hooks/hooks.json` now fires all three gates
   globally, keyed off `CLAUDE_ROLE`.
3. Rewrote `capacity-planning/hooks/directive.sh` as a stub: sources
   `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with
   the role's `you_decide`/`use_when`/`produces`/`hand_off` values, folding
   `WRITE_SCOPE` into `produces` and `BOUNDARY CASE` into `hand_off` via
   `$'...\n\n...'` single-physical-line quoting, per proposal item 3. No
   role-unique content dropped.
4. `RECORD_FIELDS_TERMINAL_STATES`: no override added (proposal item 4).
   This role's own record has no `loop_state` usage diverging from core's
   default terminal set (`landed`); flagged as an open item, not silently
   assumed, per the issue's own instruction.

## What was NOT done

`capacity-planning/.claude-plugin/plugin.json` — untouched, as scoped by
the proposal ("Not touched" section): it already carries this role's
`you_decide`/`use_when`/hand-off and vendors no core canon.

## stub-check.sh conformance (proposal item 5)

Ran against a live core checkout (`/tmp/claude-1000/core-check/core`,
`core/hooks/tests/stub-check.sh`) over this repo's plugin root:

```
$ bash stub-check.sh capacity-planning
stub-check: ok — no vendored 'trailer-gate.sh' under .../capacity-planning
stub-check: ok — no vendored 'record-fields-gate.sh' under .../capacity-planning
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under .../capacity-planning
stub-check: ok — no vendored 'parse-check.sh' under .../capacity-planning
stub-check: ok — .../capacity-planning/hooks/directive.sh is a role-directive stub
```

All five checks (four absence checks + directive.sh structural check)
pass.

## Upstream basis

- Issue: #2.
- Approved proposal: [core-canon-reference-switch.md](../issue-2/proposals/core-canon-reference-switch.md).
- Survey: [survey.md](../issue-2/reports/implementation/survey.md).
- Core canon: core issue #63 (warrant-hunter promotion), core issue #66
  (role-agnostic gates + `core_role_directive` promotion).

## Open findings

- `RECORD_FIELDS_TERMINAL_STATES` value for this role remains an explicit
  open item (proposal item 4) — set only if a future record surfaces a
  non-default terminal `loop_state`.

loop_state: landed
