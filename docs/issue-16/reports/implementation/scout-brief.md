# Scout brief — issue-16

Mode: batched-sequential reads in one session (no external web search
angle applies; this is an internal spec-to-doc alignment task, not a
product surface). 1 stage.

## Field scouted
Not a product category. The "field" here is (a) the on-the-record
contract's `capacity-planning.spec.json` itself, and (b) this
rulebook's own prior alignment precedent (issue-1, issue-7, issue-10,
issue-13), which is the closest available comparable to "how strong
audits of this change-class check."

## Findings
- `roles/specs/capacity-planning.spec.json` (read from a sibling
  on-the-record worktree) names `source_standard: ITIL Capacity
  Management practice`. This rulebook's existing methodology stack
  (issue-1) cites SRE-book capacity planning + Little's Law + USL —
  compatible techniques, not competing ones; ITIL's four fields
  (resource/demand_forecast/capacity_threshold/verdict) are a thin
  contract layer that sits above the existing method-selection
  doctrine, not a replacement for it.
- Precedent pattern (issue-1 → issue-13): every prior alignment in
  this rulebook strengthened `capacity-fields-gate.sh`'s heading/term
  checks and the handbook checklist additively, never replacing prior
  required-field names. Same pattern applies here per the issue-16
  body's own instruction ("strengthening existing content, never
  deleting methodology").
- Core's `record-fields-gate.sh` already has a designed escape hatch
  for exactly this shape of change: `docs/specs/record-fields-terminal-
  states.json`, a per-kind `{kind: [terminal_states]}` override. This
  rulebook has never populated one — core's gate currently falls back
  to its own hardcoded generic terminal set for `CLAUDE_ROLE=capacity-
  planning`, which does not know about `landed`/`threshold-undeclared`/
  `resource-unreachable`.

## Gap line
Current rulebook covers: forecast method selection, threshold
decomposition (growth_rate × lead_time × safety_buffer), headroom
band + cost note — i.e. `demand_forecast` and `capacity_threshold` are
already well covered under different vocabulary ("capacity forecast",
"expansion trigger thresholds"). Missing entirely: `resource` (no
reference-resolution concept exists anywhere in this rulebook) and
`verdict` (no within-capacity/over-capacity determination step
exists — the checklist stops at stating headroom, never renders a
verdict). Missing on the loop_state axis: `threshold-undeclared` /
`resource-unreachable` / `forecasting` are not recognized as vocabulary
anywhere, and `docs/specs/record-fields-terminal-states.json` does not
exist yet to declare `landed` as this role's sole terminal state.

## Adopt / skip
- Adopt: layer `resource` and `verdict` as new checklist steps /
  gate-checked headings, additive to the existing five-step checklist.
- Adopt: populate `docs/specs/record-fields-terminal-states.json` for
  `capacity-planning` per the spec's loop_state block (this is the
  designed extension point, not a new mechanism).
- Skip: renaming `demand_forecast`/`capacity_threshold` on top of the
  existing "capacity forecast"/"expansion trigger thresholds" prose —
  the spec's `type: string` fields are satisfied by mapping, per the
  issue's own instruction to strengthen not delete.

Sources: `roles/specs/capacity-planning.spec.json` (sibling
on-the-record worktree, read locally, no URL); `docs/issue-1/...`,
`docs/issue-7/...`, `docs/issue-10/...`, `docs/issue-13/...` (this
repo); `core/hooks/record-fields-gate.sh` (sibling core worktree).
