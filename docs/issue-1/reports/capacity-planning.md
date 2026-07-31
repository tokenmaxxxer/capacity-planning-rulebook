# Record — issue-1 (capacity-planning methodology & deliverable norm)

Subject: issue-1. Phase 2 execution of the approved proposal
([capacity-planning-methodology-norm.md](../proposals/capacity-planning-methodology-norm.md)),
approved via `APPROVE issue-1/capacity-planning` issue comment
(single-account mode, 2026-07-31).

## Why

Phase 1's survey found `directive.sh`'s `PRODUCES` line naming three bare
nouns with no methodology, and no gate enforcing the field's own
must-bes (organic/inorganic split, lead-time-derived trigger, headroom as
a band) on this role's record — so a record could pass the generic §20
gate while omitting everything the capacity-planning literature treats as
non-negotiable. This issue closes that gap by encoding the approved norm
into the directive text and a role-owned enforcement gate, so the
must-bes are structural rather than left to a writer's memory.

## What was done

1. **`directive.sh` `PRODUCES` line** expanded to name the three required
   subsections and their one-line shape, verbatim as proposed:
   `capacity forecast (organic/inorganic split, horizon > lead time,
   method+justification), expansion trigger thresholds (growth_rate ×
   lead_time × safety_buffer, percentile-stated, headroom as a band),
   cost note (cost attributed to the firing threshold)`. Same
   `core_role_directive` stub shape as before — no new plugin machinery.
2. **New role-owned gate** —
   `capacity-planning/hooks/capacity-fields-gate.sh`, registered as an
   additional `PreToolUse` entry (`Write|Edit|MultiEdit`) in
   `capacity-planning/hooks/hooks.json`, additive to (never replacing or
   forking) core's generic `record-fields-gate.sh`, which stays
   registered globally from core. Scope: fires only on writes targeting
   `docs/issue-<n>/reports/capacity-planning.md`. On a terminal write
   (`loop_state: terminal` or `state: done|terminal|complete` marker
   present in the resulting content) it checks that all three (b)
   subsections from the proposal are present by heading, and that the
   threshold subsection names `growth_rate`/`lead_time`/`safety_buffer`
   (or Korean equivalents) plus a percentile token. Non-terminal writes
   are not blocked, mirroring `record-fields-gate.sh`'s own leniency for
   in-progress records. Kill switch: `CAPACITY_FIELDS_GATE_OFF=1`,
   matching core's `<ROLE>_..._OFF` naming convention.

## What was NOT done

Per the proposal's plan items 3–4 and "Not touched" section:
`capacity-planning/.claude-plugin/plugin.json` (its `you_decide`/
`use_when`/hand-off text already covers this, the `PRODUCES` detail lives
in `directive.sh` only); core's own `record-fields-gate.sh`,
`trailer-gate.sh`, `handbook-trigger-gate.sh` (core-owned, out of this
role's write scope); `RECORD_FIELDS_TERMINAL_STATES` (no override
proposed — unchanged from issue-2's phase-1 conclusion).

This record is itself report-only (`WRITE_SCOPE: []`) and documents a
plugin-reflection change, not a live capacity decision — it carries no
capacity forecast / expansion-trigger / cost-note content of its own,
since issue-1 is a methodology task, not a capacity decision for a live
subject. The three-subsection content norm from proposal (b) governs
*future* capacity-planning records produced under the now-expanded
`PRODUCES` directive, enforced going forward by the new gate.

## Upstream basis

- Issue: #1.
- Approved proposal: [capacity-planning-methodology-norm.md](../proposals/capacity-planning-methodology-norm.md).
- Survey: [survey.md](capacity-planning/survey.md).
- Scout brief: [scout-brief.md](capacity-planning/scout-brief.md).

## Open findings

- The role-owned gate reconstructs terminal write content for `Edit`/
  `MultiEdit` by replaying `old_string`/`new_string` against the current
  on-disk file (PreToolUse fires before the edit lands); this mirrors
  the tool's own apply semantics but has not been exercised against a
  multi-hunk `MultiEdit` in production — worth a follow-up smoke test
  the next time a capacity-planning record actually goes terminal via
  `MultiEdit`.
- `RECORD_FIELDS_TERMINAL_STATES` remains an open item carried over from
  issue-2 (proposal item 4) — unchanged here, flagged again per the
  proposal's own instruction not to silently assume it.

loop_state: landed
