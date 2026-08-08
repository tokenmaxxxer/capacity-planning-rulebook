# Capacity-planning forecast checklist

Owned across the `capacity-forecast-method` (steps 1-3),
`capacity-threshold-decomposition` (step 4), and
`capacity-headroom-costnote` (step 5) plugins — see
`docs/issue-7/proposals/enforcement-machinery-deepening.md` for the
plugin composition this checklist backs.

0. State the `resource` this record is about: a concrete, monitored
   reference (a specific service/cluster/queue/pool, not a vague or
   orphan name) — the record's forecast, threshold, and verdict below
   are all about this one resource.
1. Classify the workload's demand shape (`demand_forecast`, steps 1-3):
   steady/organic growth, a
   specific scenario/inorganic event, or seasonality/campaign-driven —
   state which, with the evidence (a time series, an event calendar, a
   campaign schedule) that supports the classification.
2. Pick the forecast method matching that shape: linear/exponential
   regression trend fit for steady organic growth; Holt-Winters
   exponential smoothing or ARIMA for seasonality/campaign-driven
   demand; scenario/queueing modeling for a specific inorganic event.
   Name which was picked and why, tied to step 1's classification.
3. If a prior forecast exists for the same subject, compare
   forecast-vs-actual: state match or diverge; a divergence is a
   model-instability signal to flag, not to silently overwrite.
4. State the expansion-trigger threshold (`capacity_threshold`) as
   growth_rate × lead_time × safety_buffer, each term a concrete labeled
   value, sized to a stated percentile of demand (e.g. p97.5) over the
   forecast horizon — never a bare flat percentage.
5. State headroom as a band (not a single snapshot number, per the
   Universal Scalability Law's non-linear degradation near capacity),
   and attribute the incremental cost of the recommended expansion to
   the specific threshold that fires it.
6. Render a `verdict`: within-capacity or over-capacity, recomputed
   from the stated `demand_forecast` (steps 1-3) against the stated
   `capacity_threshold` (step 4) — never asserted standalone without
   that recomputation.

## Gate enforcement note (issue-10)

Steps 1-2's method/shape claim (`forecast-method-gate.sh`) and step 4's
term decomposition (`threshold-gate.sh`) are checked with a bounded
adjacency/heading-slice window around the relevant claim, not a
whole-document substring search — a term mentioned elsewhere in the
document, unconnected to the actual claim, no longer satisfies the check.
See `docs/handbooks/gate-house-standard.md` and
`docs/issue-10/reports/capacity-planning.md` for the migration this
enforcement now runs on (`gate-lib.sh`/`gate-lib.py`, referenced not
copied).

## Gate A+ final closeout note (issue-13)

Step 4's percentile check now requires a non-alphanumeric boundary before
the `p` in a `pNN`-shaped token (`p97.5`, `p99`, ...) — an incidental
`p`+digit substring inside an unrelated word (`cap95`, `step2`) no longer
satisfies the requirement. Step 5's band/cost checks (`headroom-gate.sh`)
are now scoped to the record's own headroom/cost-note heading slice, not
grepped against the whole document. All five gates (this checklist's three
plus `capacity-fields-gate.sh` and `citation-gate.sh`) now fail closed on
an unreachable `gate-lib.sh`/`gate-lib.py` (mandatory `||` source guard)
and on a symlinked project root (root is `realpath`'d before scope
matching). See `docs/issue-13/reports/capacity-planning.md` for the full
fix-plan record and test evidence.
