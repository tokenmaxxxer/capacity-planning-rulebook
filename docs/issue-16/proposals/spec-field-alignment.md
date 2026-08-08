---
status: proposed
files:
  - docs/handbooks/capacity-planning/forecast-checklist.md
  - capacity-planning/hooks/capacity-fields-gate.sh
  - capacity-planning/hooks/directive.sh
  - README.md
  - docs/specs/record-fields-terminal-states.json
  - tests/run-gate-tests.sh
---

## Request
Align this rulebook's vocabulary with `roles/specs/capacity-planning.spec.json`
(on-the-record, issue #16): layer the spec's four required fields
(`resource`, `demand_forecast`, `capacity_threshold`, `verdict`) and its
`loop_state` vocabulary (`forecasting`, `landed`, `resource-unreachable`,
`reviewing`, `threshold-undeclared`) onto the existing rulebook docs and
gates, additively — never deleting the existing methodology (forecast
method selection, threshold decomposition, headroom/cost note).

## Constraints
- Additive only: no existing checklist step, gate check, or required
  heading may be removed to make room for the new fields (issue body,
  contract v3 phase-1 discipline).
- The record's `write_scope` in the spec
  (`docs/issue-<n>/reports/capacity-planning.md`) already matches this
  rulebook's existing record path — no path change needed.
- `resource`'s `reference_resolution` rule ("resource must resolve to
  an actual monitored resource, checked by
  `on-the-record/hooks/role-spec-reference-guard.sh`") is an
  on-the-record-side hook, out of this repo's write scope; this
  rulebook only needs to make `resource` a documented/gated concept on
  its own record.
- `verdict`'s `recomputation` rule is marked `TBD` upstream
  (issue-521 follow-up) — nothing to enforce here beyond requiring the
  field to be present and one of the two enum values.
- Core's `record-fields-gate.sh` (`ROLE_TO_KIND`) does not map role
  `capacity-planning` to any kind; an unmapped role falls back to a
  self-declared `kind:` frontmatter field, consulted only if that
  value is one of contract §2's kind names.

## Rationale
Two ways to make the rulebook's terminal-`loop_state` set equal the
spec's `{landed}`:

1. **Add `capacity-planning` as a new key inside
   `docs/specs/record-fields-terminal-states.json`.** Rejected: core's
   `record-fields-gate.sh` validates every key in that file against
   `KIND_TERMINAL_DEFAULTS`, which is a fixed list of contract §2 kind
   names (`coding-record`, `qa-record`, ...) — `capacity-planning` is
   a role name, not a kind name, and is not in that list. Adding it
   would make the gate fail loudly on every write (`"names
   unrecognized kind"`), which is worse than doing nothing.
2. **Have capacity-planning's own phase-2 records self-declare
   `kind: coding-record` in frontmatter.** Chosen: core's fallback
   path explicitly consults a record's own `kind:` field when the
   role isn't in `ROLE_TO_KIND`, and `KIND_TERMINAL_DEFAULTS["coding-
   record"]` is already exactly `{"landed"}` — matching the spec's
   terminal set with zero new files or core-side changes. This also
   sidesteps needing any change to
   `docs/specs/record-fields-terminal-states.json` for the terminal-
   state axis specifically; that file is proposed here only to record
   the choice explicitly (see What will be done) so a future reader
   does not have to re-derive it from core's source.

For the `resource`/`verdict` fields, two ways to surface them:

1. **Fold them into the existing three headings** ("Capacity
   forecast", "Expansion trigger thresholds", "Cost note") as extra
   required sentences inside those sections. Rejected: `resource`
   (which resource this record is about) and `verdict` (the
   within-capacity/over-capacity determination) are not naturally
   subordinate to any of the three existing headings — burying them
   inside an unrelated heading makes the gate's per-heading slice
   check miss them and makes the record harder to read.
2. **Add two new required headings/steps** ("Resource" and
   "Verdict"), gated the same way the existing three are (heading
   presence + content check), and two new checklist steps. Chosen:
   consistent with the existing per-field-heading gate pattern in
   `capacity-fields-gate.sh`, additive, and keeps each spec field
   independently checkable.

## What will be done
- `docs/handbooks/capacity-planning/forecast-checklist.md`: add step 0
  ("state the `resource` this record is about — a concrete, monitored
  reference, never a vague/orphan name") ahead of the existing steps,
  and step 6 ("render a `verdict`: within-capacity or over-capacity,
  recomputed from the stated `demand_forecast` against the stated
  `capacity_threshold` — never asserted standalone"). Existing steps
  1-5 keep their numbering intent (demand_forecast covered by
  1-3, capacity_threshold by 4) with a one-line cross-reference to the
  spec field names so `grep -ri` finds them.
- `capacity-planning/hooks/capacity-fields-gate.sh`: add two more
  required-heading checks ("Resource", "Verdict") to the existing
  three, following the same pattern (grep for the heading, and for
  Verdict, also check its heading slice contains one of
  `within-capacity`/`over-capacity`).
- `capacity-planning/hooks/directive.sh`: extend the `PRODUCES` string
  with `resource (the monitored reference this record is about)` and
  `verdict (within-capacity/over-capacity, recomputed from
  demand_forecast vs capacity_threshold)`.
- `README.md`: extend the `produces:` line the same way, and add a
  short subsection documenting the spec alignment (field mapping table
  + the `kind: coding-record` frontmatter requirement for terminal-
  state matching), referencing this proposal and
  `roles/specs/capacity-planning.spec.json`.
- `docs/specs/record-fields-terminal-states.json`: create it recording
  the explicit choice made in Rationale — capacity-planning records
  self-declare `kind: coding-record`, and core's own default for that
  kind (`{"landed"}`) is left untouched (i.e. this file, if created,
  contains no `capacity-planning` key and no override of `coding-
  record`'s default; it exists to document non-nil terminal-state
  handling other roles may already rely on — this repo currently has
  none of its own, so the file is written with the `coding-record`
  entry present but equal to core's own default, to make the mapping
  legible on this repo's side rather than only inside core's source).
  If phase-2 finds writing a same-as-default entry adds no value over
  documenting the choice in README.md alone, the file is dropped from
  the write set and the choice is documented in README.md only — this
  will be stated in the phase-2 record either way.
- `tests/run-gate-tests.sh`: add allow/deny cases for the two new
  `capacity-fields-gate.sh` heading checks.
- Document, in the same README subsection, that `forecasting` and
  `reviewing` (progress) and `threshold-undeclared` (refusal) and
  `resource-unreachable` (error) are this role's recognized non-
  terminal `loop_state` values — no gate change needed for these
  since core's `record-fields-gate.sh` only special-cases the terminal
  set; this is documentation-only vocabulary alignment for the
  progress/refusal/error states.

## Out of scope
- `on-the-record/hooks/role-spec-reference-guard.sh` (resource
  reference-resolution enforcement) — lives outside this repo.
- `verdict` recomputation enforcement — upstream `TBD` (issue-521
  follow-up); nothing to build here.
- Any change to the four methodology plugin gates
  (`forecast-method-gate.sh`, `threshold-gate.sh`, `headroom-gate.sh`,
  `citation-gate.sh`) — their existing checks already satisfy
  `demand_forecast`/`capacity_threshold` coverage and are untouched
  per the additive constraint.
- Renaming "capacity forecast" / "expansion trigger thresholds" / "cost
  note" prose headings to the spec's literal field names — mapped, not
  renamed (Rationale).

## How you'll know it worked
- `grep -ri "resource\|demand_forecast\|capacity_threshold\|verdict" docs/ README.md`
  matches all four spec field names (as literal tokens, not only as
  concept prose) after phase 2.
- `grep -ri "forecasting\|landed\|resource-unreachable\|reviewing\|threshold-undeclared" README.md`
  matches all five spec loop_state values, with no other loop_state
  value documented for this role.
- `tests/run-gate-tests.sh` passes, including the new
  `capacity-fields-gate.sh` cases for Resource/Verdict headings.
- A terminal-state record with `kind: coding-record` and
  `loop_state: landed` is accepted by core's `record-fields-gate.sh`
  fallback path (traced through its source in this proposal's
  Rationale; re-confirmed against actual gate behavior in phase 2).
