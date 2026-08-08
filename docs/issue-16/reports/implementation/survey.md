# Current-state survey — issue-16

## Spec (external input, read from sibling on-the-record worktree)
`roles/specs/capacity-planning.spec.json`:
- `required_fields`: `resource` (ref), `demand_forecast` (string),
  `capacity_threshold` (string), `verdict` (enum:
  within-capacity/over-capacity).
- `reference_resolution`: `resource` must resolve to an actual
  monitored resource, no orphan refs — checked by (in on-the-record,
  out of this repo's scope) `role-spec-reference-guard.sh`.
- `recomputation`: `verdict` is recomputed from current
  `demand_forecast` against `capacity_threshold`, never asserted
  standalone. Enforcement is `TBD` upstream (issue-521 follow-up) —
  nothing to wire here yet.
- `write_scope`: `docs/issue-<n>/reports/capacity-planning.md` — matches
  this rulebook's existing record path exactly.
- `loop_state`: progress = `forecasting`, `reviewing`; terminal =
  `landed`; refusal = `threshold-undeclared`; error =
  `resource-unreachable`.

## This repo's current state (write set for this alignment)

| File | Current state | Relevant to spec field |
|---|---|---|
| `docs/handbooks/capacity-planning/forecast-checklist.md` | 5 steps: demand-shape classification, forecast method pick, forecast-vs-actual compare, threshold decomposition, headroom band + cost attribution | covers `demand_forecast` (steps 1-3), `capacity_threshold` (step 4); no step for `resource` or `verdict` |
| `capacity-planning/hooks/capacity-fields-gate.sh` | Gates terminal-state records for three headings: "Capacity forecast", "Expansion trigger thresholds", "Cost note"; threshold slice requires growth_rate/lead_time/safety_buffer/percentile terms | no gate check for a resource reference or a verdict determination |
| `capacity-planning/hooks/directive.sh` | `core_role_directive` PRODUCES string: "capacity forecast ..., expansion trigger thresholds ..., cost note ..." | same three-field vocabulary; `resource` and `verdict` absent |
| `README.md` | `produces:` capacity forecast, expansion trigger thresholds, cost note | same gap |
| `docs/specs/record-fields-terminal-states.json` | does not exist | core's `record-fields-gate.sh` falls back to a generic hardcoded terminal set for this role; spec's `landed`-only terminal / `threshold-undeclared` refusal / `resource-unreachable` error vocabulary is not registered anywhere |
| `capacity-threshold-decomposition/hooks/threshold-gate.sh` | checks growth_rate × lead_time × safety_buffer + percentile term presence in "Expansion trigger thresholds" heading slice | unaffected — already satisfies `capacity_threshold` mapping |
| `capacity-headroom-costnote/hooks/headroom-gate.sh` | checks headroom band + cost attribution in a headroom/cost-note heading slice | unaffected |
| `capacity-forecast-method/hooks/forecast-method-gate.sh` | checks method+justification claim | unaffected — feeds `demand_forecast` |
| `capacity-order-enforcement/hooks/citation-gate.sh` | checks survey→scout-brief→proposal citation presence on phase-1 surfaces | unaffected |

`grep -ri "resource\|demand_forecast\|capacity_threshold\|verdict" docs/
README.md` today: `demand_forecast`/`capacity_threshold`/`verdict` as
literal spec-field tokens do not appear anywhere; `resource` appears
only in unrelated prose ("resource-forecast", "projecting resource
demand" — not as a reference-resolution concept).

## Unknowns going in (aimed the scout sweep, see scout-brief.md)
- Whether to introduce the spec's literal field names as new
  vocabulary alongside the existing prose names, or rename in place —
  resolved by the issue body's own instruction ("strengthening
  existing content, never deleting methodology") toward additive
  mapping, confirmed by scout's precedent read of issue-1→13.
- Whether `docs/specs/record-fields-terminal-states.json` is the
  correct mechanism for the loop_state vocabulary requirement, or
  whether a role-owned gate change is needed instead — resolved by
  reading `core/hooks/record-fields-gate.sh`, which built exactly this
  override file as its designed extension point.

## Write set this survey found (feeds the proposal's frozen list)
- `docs/handbooks/capacity-planning/forecast-checklist.md`
- `capacity-planning/hooks/capacity-fields-gate.sh`
- `capacity-planning/hooks/directive.sh`
- `README.md`
- `docs/specs/record-fields-terminal-states.json` (new file)
- `tests/run-gate-tests.sh` (add coverage for the new gate checks)
