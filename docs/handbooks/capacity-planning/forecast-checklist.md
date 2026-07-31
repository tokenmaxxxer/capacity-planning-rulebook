# Capacity-planning forecast checklist

Owned across the `capacity-forecast-method` (steps 1-3),
`capacity-threshold-decomposition` (step 4), and
`capacity-headroom-costnote` (step 5) plugins — see
`docs/issue-7/proposals/enforcement-machinery-deepening.md` for the
plugin composition this checklist backs.

1. Classify the workload's demand shape: steady/organic growth, a
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
4. State the expansion-trigger threshold as
   growth_rate × lead_time × safety_buffer, each term a concrete labeled
   value, sized to a stated percentile of demand (e.g. p97.5) over the
   forecast horizon — never a bare flat percentage.
5. State headroom as a band (not a single snapshot number, per the
   Universal Scalability Law's non-linear degradation near capacity),
   and attribute the incremental cost of the recommended expansion to
   the specific threshold that fires it.
