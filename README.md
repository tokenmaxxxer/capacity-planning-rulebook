# capacity-planning-rulebook

Rulebook for the `capacity-planning` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 향후 수요 성장 대비 자원이 충분하며 언제 증설해야 하는가
- **use_when**: 용량 예측/증설 시점 결정이 걸릴 때
- **produces**: resource, capacity forecast, expansion trigger thresholds, cost note, verdict
- **write_scope**: []
- **hand-off**: 성능 자체의 병목 원인 분석은 → performance-engineering

## Install

```
claude plugin marketplace add tokenmaxxxer/capacity-planning-rulebook
claude plugin install capacity-planning
```

## Layout

- `capacity-planning/.claude-plugin/plugin.json` — plugin manifest
- `capacity-planning/hooks/hooks.json` — SessionStart + PreToolUse wiring
- `capacity-planning/hooks/directive.sh` — SessionStart role directive
- `capacity-planning/hooks/capacity-fields-gate.sh` — this role's phase-2
  record required-field gate (kill switch `CAPACITY_FIELDS_GATE_OFF=1`)
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

Generic `Subject: issue-<n>` trailer enforcement, per-record required-field
enforcement (core's own field set), and handbook-sync enforcement come from
core's `core/hooks/hooks.json` firing globally, keyed off
`CLAUDE_ROLE=capacity-planning` — this rulebook never vendors a copy of
`trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`
(`docs/issue-2/reports/implementation.md`). `capacity-fields-gate.sh` above
is additive to core's `record-fields-gate.sh`, not a replacement for it.

### Methodology plugin set (issue-7)

The domain methodologies adopted in issue-1
(`docs/issue-1/proposals/capacity-planning-methodology-norm.md`) are each
enforced by their own self-contained, marketplace-registered plugin —
modeled on how core's own `freelunch`/`scout` plugins are one capability
per plugin rather than a shared blob. Design/composition rationale:
`docs/issue-7/proposals/enforcement-machinery-deepening.md`.

- `capacity-forecast-method` — forecast-method selection (SRE book
  "Capacity Planning" chapter organic/inorganic framing). Phase-1
  proposal surface only.
  `hooks/forecast-method-gate.sh` (kill switch
  `CAPACITY_FORECAST_METHOD_GATE_OFF=1`).
- `capacity-threshold-decomposition` — `growth_rate × lead_time ×
  safety_buffer` threshold decomposition (Little's Law). Fires on both
  the phase-1 proposal and phase-2 record surfaces.
  `hooks/threshold-gate.sh` (kill switch
  `CAPACITY_THRESHOLD_GATE_OFF=1`).
- `capacity-headroom-costnote` — headroom-as-band + cost attribution
  (Universal Scalability Law). Phase-2 record surface only.
  `hooks/headroom-gate.sh` (kill switch
  `CAPACITY_HEADROOM_GATE_OFF=1`).
- `capacity-order-enforcement` — survey → scout-brief → proposal
  citation-presence precondition. Phase-1 proposal and report surfaces
  only. `hooks/citation-gate.sh` (kill switch
  `CAPACITY_ORDER_ENFORCEMENT_GATE_OFF=1`).

Each plugin is additive to (never a fork/replacement of) core's generic
gates and this role's existing `capacity-fields-gate.sh`; each is
registered as its own entry in `.claude-plugin/marketplace.json`.
Handbook: `docs/handbooks/capacity-planning/forecast-checklist.md`.
Gate tests: `tests/run-gate-tests.sh`.

### Gate-house standard (issue-10)

All five of this rulebook's own gates (`capacity-fields-gate.sh` and the
four plugin gates above) reference-adopt core's shared gate library —
`core/hooks/lib/gate-lib.sh` / `gate-lib.py`, resolved via
`CLAUDE_PLUGIN_ROOT_CORE` at runtime — instead of hand-rolling their own
kill-switch/path-normalize/reconstruct/deny logic. See
`docs/handbooks/gate-house-standard.md` for what the library provides and
`docs/issue-10/reports/capacity-planning.md` for this rulebook's own
migration evidence (before/after `compliance-check.sh` output, full test
suite). Every kill switch listed above follows the fixed convention: only
a recognized on-spelling (`1`/`true`/`yes`/`on`, case-insensitive)
disables the gate — an unset, empty, recognized-off, or any unrecognized
value all leave the gate active.

### Marketplace spec alignment (issue-16)

This rulebook's vocabulary is layered onto the realized marketplace spec
`roles/specs/capacity-planning.spec.json` (on-the-record). Field mapping:

| Spec required field | Rulebook home |
| --- | --- |
| `resource` | Checklist step 0; record heading "Resource"; gated by `capacity-fields-gate.sh`. |
| `demand_forecast` | Checklist steps 1-3 ("Capacity forecast" heading); gated by `capacity-fields-gate.sh` + `forecast-method-gate.sh`. |
| `capacity_threshold` | Checklist step 4 ("Expansion trigger thresholds" heading); gated by `capacity-fields-gate.sh` + `threshold-gate.sh`. |
| `verdict` | Checklist step 6; record heading "Verdict" (within-capacity/over-capacity, recomputed from `demand_forecast` vs `capacity_threshold`); gated by `capacity-fields-gate.sh`. Recomputation enforcement is upstream `TBD` (issue-521 follow-up) — this rulebook only requires the field present with a valid value. |

`resource`'s `reference_resolution` rule (must resolve to an actual
monitored resource) is enforced on the on-the-record side
(`on-the-record/hooks/role-spec-reference-guard.sh`), outside this
repo's write scope; this rulebook only makes `resource` a
documented/gated concept on its own record.

Spec `loop_state` vocabulary mapping: `forecasting` and `reviewing` are
this role's in-progress states, `threshold-undeclared` its refusal
state, and `resource-unreachable` its error state — none of these are
special-cased by core's `record-fields-gate.sh` (which only enforces the
terminal set), so no gate change is needed for them. `landed` is the
sole terminal state. Core's `record-fields-gate.sh` `ROLE_TO_KIND` does
not map role `capacity-planning` to any kind, so this role's phase-2
records self-declare `kind: coding-record` in frontmatter — core's own
`KIND_TERMINAL_DEFAULTS["coding-record"]` is already exactly `{"landed"}`,
matching the spec's terminal set with no new gate logic. See
`docs/issue-16/proposals/spec-field-alignment.md` for the full rationale
and rejected alternatives.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
