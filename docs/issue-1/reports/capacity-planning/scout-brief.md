# Scout brief — capacity-planning methodology (issue-1)

Mode: parallel, 3 angles, 1 stage (sweep only) — saturated after round 1
(Google SRE book result converged with the other two angles: organic
+inorganic demand, lead time, headroom band, validated-forecast loop).
Second deepening round would not change a build decision → stopped at
judge point 1.

## Category must-bes (Kano)

- A demand forecast must separate **organic** growth (natural
  adoption/usage) from **inorganic** growth (launches, campaigns,
  business-driven step changes) — treating them as one number is a known
  failure mode (Google SRE).
- A forecast must extend **beyond the lead time** required to actually
  acquire/provision the added capacity — a forecast horizon shorter than
  procurement lead time cannot trigger timely action by construction
  (Google SRE; oneuptime headroom-planning).
- An expansion trigger must be a **threshold set from lead time and
  growth rate**, not a flat number: `warning = 100 − (growth_rate ×
  lead_time) − safety_buffer` is the field's standard shape (oneuptime
  capacity-thresholds).
- Headroom must be stated as a **band**, not a point-in-time snapshot:
  30–40% spare capacity above baseline is the recurring industry
  recommendation to absorb unpredictability (Google SRE); running at 80%
  utilization is called out as already-too-late in headroom literature.

## Performance axes the field competes on

1. **Forecast method fit to data profile** — linear regression / trend
   decomposition for steady growth vs. queueing models for
   scenario-specific, high-granularity cases vs. ML for
   seasonality-heavy or campaign-driven demand. No single method is
   claimed universal; the standard advice is method choice justified by
   the data's own shape (r9y-map, Harness SRE guide).
2. **Threshold basis (percentile vs. flat)** — mature practice states
   thresholds as an explicit percentile (e.g., "provision for p97.5 over
   the horizon") so the residual risk is a stated, quantified number, not
   an implicit assumption.
3. **Forecast validated against reality** — prior forecasts are checked
   against actuals until they consistently match; persistent divergence
   is itself flagged as a signal of an unstable model (Google SRE).

## Adopt / skip

- **Adopt**: organic/inorganic split, lead-time-aware threshold formula,
  percentile-stated headroom band, method-justified-by-data-shape framing,
  forecast-vs-actual validation note.
- **Skip**: mandating one specific forecasting algorithm (e.g., always
  ARIMA or always queueing theory) — the field's own must-be is
  justified method choice, not a fixed algorithm; forcing one algorithm
  would fight the very literature this brief is drawn from.

## Segment fit

This role is report-only (`WRITE_SCOPE: []`, contract-confirmed in
directive.sh) — a decision-support forecast/threshold/cost note, not an
implementation. The exemplars above are all decision-support artifacts
(SRE capacity plans, threshold-computation docs), which matches this
role's segment directly; no adjustment needed for a mismatched segment
(e.g., no need to import full ML-pipeline engineering practice).

## Gap line

Current state (per survey.md) has zero of the above: `PRODUCES` in
directive.sh names three bare nouns with no required internal shape.
Missing, all of: organic/inorganic split, lead-time-derived threshold
formula, percentile-stated headroom, method-justification note,
forecast-vs-actual validation trail. Nothing in the current repo already
meets any must-be above — the proposal's phase-2 norm must introduce all
of them, not just refine an existing partial version.

## Sources

- [Basic linear capacity projection — r9y-map](https://map.r9y.dev/docs/Basic_linear_capacity_projection.html)
- [Guide to capacity planning for SRE — Harness](https://www.harness.io/harness-devops-academy/capacity-planning-in-sre)
- [How to Create Trend Analysis — OneUptime](https://oneuptime.com/blog/post/2026-01-30-trend-analysis/view)
- [How to Create Capacity Thresholds — OneUptime](https://oneuptime.com/blog/post/2026-01-30-capacity-thresholds/view)
- [How to Create Headroom Planning — OneUptime](https://oneuptime.com/blog/post/2026-01-30-headroom-planning/view)
- [What is Headroom? — SRE School](https://sreschool.com/blog/headroom/)
- [Google SRE book — Introduction](https://sre.google/sre-book/introduction/)
- [Google SRE book — Software Engineering in SRE](https://sre.google/sre-book/software-engineering-in-sre/)
