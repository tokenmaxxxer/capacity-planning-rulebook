# Record — issue-7 (capacity-planning enforcement-machinery deepening, plugin set)

Subject: issue-7. Phase 2 execution of the approved proposal
([enforcement-machinery-deepening.md](../proposals/enforcement-machinery-deepening.md)),
approved via `APPROVE issue-7/capacity-planning` issue comment
(single-account mode, 2026-08-01).

## Why

Issue-1 encoded the adopted capacity-planning methodology (forecast
method, threshold decomposition, headroom/cost) as a directive
`PRODUCES` line plus one bare-field-presence gate
(`capacity-fields-gate.sh`). It did not mechanically verify that a
proposal's forecast-method claim is actually tied to a data-shape
classification, did not check phase-1 threshold traceability at all, and
had no independent kill switch per methodology. The approver rejected a
single deepened gate/directive as the wrong shape for this and required
a **plugin set**: each adopted methodology as its own self-contained,
marketplace-registered plugin, mirroring core's `freelunch`/`scout`
pattern — see the proposal's restructuring note.

## What was done

Four new sibling plugins, each `.claude-plugin/plugin.json` +
`hooks/hooks.json` (SessionStart directive + PreToolUse gate) +
`hooks/directive.sh` (print-only framing, not a second
`core_role_directive` stub) + its own gate script, registered in
`.claude-plugin/marketplace.json` alongside the unchanged
`capacity-planning` entry:

1. **`capacity-forecast-method`** — `hooks/forecast-method-gate.sh`.
   Fires on `docs/issue-*/proposals/*.md`. On a terminal-looking write,
   fail-closed unless: (a) a recognized technique keyword
   (`regression`/`trend`/`holt-winters`/`arima`) or a literal
   `대안:`/`alternative:` marker is present; (b) substantive
   justification prose exists (>= 200 non-whitespace chars in the
   document, not a bare keyword); (c) the claim co-occurs with a
   data-shape term (`organic`/`inorganic`/`seasonal`/`campaign`/Korean
   equivalents). An explicit "forecast-method 해당 없음/not applicable"
   marker exempts a proposal per the norm's own carve-out. Kill switch
   `CAPACITY_FORECAST_METHOD_GATE_OFF=1`.
2. **`capacity-threshold-decomposition`** — `hooks/threshold-gate.sh`.
   Fires on both the proposal and record (`docs/issue-*/reports/
   capacity-planning.md`) surfaces, only once the document actually
   discusses growth-rate/lead-time/threshold figures. Requires
   `growth_rate`/`lead_time`/`safety_buffer` terms plus a percentile
   token, and rejects a bare flat-percentage figure with no percentile
   qualifier. Kill switch `CAPACITY_THRESHOLD_GATE_OFF=1`.
3. **`capacity-headroom-costnote`** — `hooks/headroom-gate.sh`.
   Fires on the record surface only, on a terminal write. Requires
   headroom to be a range/band token (not a lone snapshot number) and
   the cost note to co-occur with a named threshold term, additive to
   `capacity-fields-gate.sh`. Kill switch `CAPACITY_HEADROOM_GATE_OFF=1`.
4. **`capacity-order-enforcement`** — `hooks/citation-gate.sh`. Fires on
   the proposal surface and on `scout-brief.md`; requires a
   terminal-looking proposal to cite `survey.md` and `scout-brief.md` by
   filename, and a terminal-looking `scout-brief.md` to cite `survey.md`;
   `survey.md` itself is exempt. Kill switch
   `CAPACITY_ORDER_ENFORCEMENT_GATE_OFF=1`.

All four gates: fail-closed on unparseable payload or an unreconstructable
`Edit`/`MultiEdit` (an `old_string` that doesn't match current content),
lenient on non-terminal (in-progress) drafts, and no-op (exit 0) on any
path outside their own surface.

Supporting artifacts:

- `docs/handbooks/capacity-planning/forecast-checklist.md` — the
  five-step checklist text from the proposal, written verbatim (steps
  1–3 `capacity-forecast-method`, step 4 `capacity-threshold-
  decomposition`, step 5 `capacity-headroom-costnote`).
- `tests/run-gate-tests.sh` — 22 cases across the four gates (allow/deny
  pairs per check: keyword-without-justification, justification-without-
  shape-link, method-named-with-shape-link, no-threshold-mentioned,
  flat-percentage-fail, missing-percentile, labeled-with-percentile,
  snapshot-headroom-fail, cost-not-attributed, band-and-attributed-cost,
  proposal/scout-brief citation present/missing, survey exemption,
  foreign-path no-op, non-terminal-draft leniency). All 22 pass.
- `.claude-plugin/marketplace.json` — four new plugin entries.
- `README.md` — new "Methodology plugin set" section.

## What was NOT done

- No canon script copied from `pricing-rulebook`, `implementation-
  rulebook`, `security-threat-model-rulebook`, or `freelunch` — only
  shape/pattern referenced, per the proposal's constraint.
- Core's `record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` — unchanged, core-owned.
- `capacity-fields-gate.sh` (existing phase-2 gate) — unchanged; the new
  plugins' phase-2 gates are additive alongside it, not a replacement.
- `capacity-planning/.claude-plugin/plugin.json` and its
  `marketplace.json` entry — unchanged.
- Agents/checklist beyond the one handbook file: the proposal's "if the
  methodology requires a repeated procedure" clause is satisfied by the
  forecast-checklist handbook; no new agent was warranted since none of
  the four methodologies needs a multi-turn hunt loop beyond the gate
  checks themselves.

## Upstream basis

- Issue: #7.
- Approved proposal:
  [enforcement-machinery-deepening.md](../proposals/enforcement-machinery-deepening.md).
- Survey: [survey.md](capacity-planning/survey.md).
- Scout brief: [scout-brief.md](capacity-planning/scout-brief.md).
- Adopted norm (issue-1):
  [capacity-planning-methodology-norm.md](../../issue-1/proposals/capacity-planning-methodology-norm.md).

## Open findings

- The forecast-method gate's "substantive justification" check is a
  document-wide non-whitespace length threshold (>= 200 chars), not a
  proximity check tied to the method mention specifically — a long
  document with an unrelated 200+ char rationale elsewhere and a bare
  method keyword would currently pass. Acceptable for a heuristic
  backstop per the proposal's own framing ("not a substitute for
  review"), but worth tightening to a windowed check if this proves too
  permissive in practice.
- The threshold and headroom band checks use generic numeric-range/
  percentile regexes rather than parsing the actual proposed field
  grammar; a determined bad-faith writer could satisfy the regex without
  satisfying the methodology's intent. Same caveat as issue-1's original
  gate — mechanical checks are a floor, not a ceiling.

## Next steps

Resolution path for the open findings above: both are heuristic-quality
gaps, not correctness bugs, so the resolution path is observation-driven
rather than a pre-emptive rewrite —

- If the forecast-method gate's document-wide justification-length
  heuristic proves too permissive in a real proposal (a long unrelated
  rationale elsewhere padding past the threshold), tighten
  `capacity-forecast-method/hooks/forecast-method-gate.sh`'s check 2 to
  a windowed proximity check around the method mention instead of a
  whole-document length count — file as a follow-up issue against this
  rulebook when observed.
- If the threshold/headroom regexes are found to pass a bad-faith
  writer who satisfies the pattern without satisfying the methodology's
  intent, escalate the same way: a follow-up issue with the concrete
  case, not a speculative rewrite now.

This record is itself report-only (`WRITE_SCOPE: []`) and documents a
plugin-reflection change, not a live capacity decision — like issue-1's
own record, it carries no capacity-forecast/expansion-trigger/cost-note
content of its own, so `loop_state: landed` (not `terminal`) is the
correct closing state and `capacity-fields-gate.sh`'s three-subsection
content check does not apply to it.

loop_state: landed
