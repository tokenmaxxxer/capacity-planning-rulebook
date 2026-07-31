# Scout brief — enforcement-machinery pattern (issue-7)

Mode: batched-sequential (single session, no parallel subagent dispatch
available for this in-repo sweep) — 1 stage, sweep only, saturated after
round 1 (all three in-repo exemplars converge on the same shape: a
content-checking `PreToolUse` gate additive to core's generic gate,
firing on both the role's proposal and record surfaces, fail-closed).
Field surveyed: sibling rulebook plugins in this same repo tree — the
appropriate "best of own deliverable's kind" exemplar set for a
meta/infra deliverable (enforcement machinery), since this is not a
web-researchable product category. Second round would not change a
build decision → stopped at judge point 1.

## Category must-bes (Kano)

- A methodology gate must be **additive** to the core generic fields
  gate, never a fork/replacement of it (pricing, capacity-planning's own
  existing `capacity-fields-gate.sh` both hold this).
- A methodology gate must **fire on the role's own write surface only**
  (path-matched to this role's proposal/record patterns), and must exit
  0 (no opinion) on any other path — never a blanket gate.
- A methodology gate must **fail closed**: unparseable payload, missing
  `python3`, undeterminable resulting content (an `Edit` whose
  `old_string` doesn't match), or any internal exception all deny (exit
  2) rather than silently passing.
- A methodology gate belongs at **both** the phase-1 proposal surface and
  the phase-2 record surface when the methodology has requirements at
  both phases (pricing checks both; capacity-planning today checks only
  phase-2 — this is the gap this proposal must close).
- State/order enforcement (survey → evidence → adoption, "필요 시 상태
  추적" per the issue) is checked by requiring the later artifact's
  content to actually reference the earlier ones (citation-presence
  check), not by a separate state file — none of the three exemplars use
  an external state file; ordering is enforced by requiring the citing
  document to name its predecessor.

## Performance axes the field competes on

1. **Element-check granularity** — pricing's gate checks six named
   elements independently (method, family, inputs, gate-check result,
   labeled numbers, residual) rather than one blob check; this makes the
   denial message specific to what's missing.
2. **Leniency on non-terminal writes** — capacity-planning's own existing
   record gate does not block in-progress (non-terminal `loop_state`)
   writes, only a terminal one; the same leniency principle should carry
   to a new phase-1 gate (an early proposal draft with a method still
   TBD should not be refused before it says so).
3. **Test-adjacency** — implementation-rulebook keeps a root-level
   `tests/run-gate-tests.sh` beside its gates, not just prose examples in
   a proposal; a gate proposal without its own test cases is the weaker
   pattern.

## Adopt / skip

- **Adopt**: additive+path-scoped+fail-closed gate shape; per-element
  keyword-presence checks (not one blob regex); citation-presence check
  for state/order (proposal must reference `survey.md` and
  `scout-brief.md` by path, mirroring what issue-1's proposal already
  does in prose so the gate only formalizes an existing convention);
  non-terminal-write leniency; adjacent gate tests under root `tests/`.
- **Skip**: a full external state-machine file (e.g. a `.capacity-state`
  JSON) — none of the three exemplars need one because citation-presence
  in the document itself is sufficient to enforce order, and adding a
  separate state file would be new machinery beyond what the field's own
  pattern requires.

## Gap line (survey.md cross-reference)

Field must-be "gate at both phase-1 and phase-2" is **missing** in
current state (phase-2 only exists). Field must-be "citation-presence
for order" is **missing** (issue-1's proposal already models the
citation in prose but nothing checks it). Field must-be
"additive/path-scoped/fail-closed shape" is **already met** by the
existing `capacity-fields-gate.sh`, so the new gate should extend that
same shape rather than introduce a different one. Field must-be
"adjacent gate tests" is **missing** (no root `tests/` at all).

## Segment fit

This is infra/enforcement work, not a domain forecast — the correct
comparison set is sibling rulebook plugins solving the identical
role-handoff-contract problem, not external capacity-planning SRE
literature (already scouted and adopted in issue-1). No mismatch.

Sources:
- pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh
- pricing-rulebook-issue-1-pricing/pricing/hooks/directive.sh
- implementation-rulebook-issue-61-implementation/coding/hooks/coding-progress-gate.sh
- implementation-rulebook-issue-61-implementation/tests/run-gate-tests.sh
- capacity-planning/hooks/capacity-fields-gate.sh (this repo, current state)
- docs/issue-1/proposals/capacity-planning-methodology-norm.md (this repo, adopted norm)
