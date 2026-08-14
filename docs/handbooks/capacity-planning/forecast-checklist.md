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

## Gate enforcement note (issue-16, leniency fix)

`capacity-fields-gate.sh`'s terminal-write trigger now matches
`loop_state: landed` (this role's actual documented terminal value) in
addition to the legacy `loop_state: terminal`/`state: done|terminal|complete`
spellings — previously a record landed with `loop_state: landed` and
missing required headings (including the Resource/Verdict pair added
this issue) silently passed every check. See
`tests/run-gate-tests.sh`'s `missing-resource-heading-loop-state-landed`
case and `docs/issue-16/reports/implementation.md`.

## Test-env resolution note (issue-19)

`tests/run-gate-tests.sh` now resolves core's `hooks/lib/gate-lib.sh`
via the canonical convention (`docs/specs/test-env-resolution.md`,
issue #551) before running any core-dependent case group: env var
`CLAUDE_PLUGIN_ROOT_CORE` → sibling candidates (`../core`, `../../core`,
`../../tokenmaxxxer-core/core`) → SKIP with exit 75 and an explicit
stderr message. Outside the spawn env this makes the run report
`SKIP` instead of misleading `FAIL`s; the `missingcore()` case group
(which force-sets an unreachable `CLAUDE_PLUGIN_ROOT_CORE` to assert
fail-closed deny) is unaffected — it runs unconditionally regardless of
this top-of-script resolution. See
`docs/issue-19/proposals/adopt-test-env-resolution.md` and
`docs/issue-19/reports/implementation.md`.

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

## Tool-landscape refinements (issue-1199)

Step 2's method claim, step 4's `safety_buffer` term, and step 5's band
each gained one further rule from a surveyed tool-landscape sweep
(adoption-evidence method): `demand-shape-and-forecast-method.md` rule
10 requires the fitted forecast's components (trend, seasonal, event)
stated separately rather than blended, sharpening what step 3's
forecast-vs-actual divergence check can attribute a mismatch to;
`expansion-trigger-threshold-sizing.md` rule 11 scopes `safety_buffer`
to the provisioning-lead-time gap when the resource has genuine elastic
on-demand capacity, instead of a static buffer sized as if all growth
had to be pre-provisioned; `cost-attribution-at-trigger.md` rule 11
requires the cost note attributed at the specific resource/workload
granularity that fired the threshold when several resources share an
expanded umbrella; `headroom-band-and-degradation-risk.md` rule 11
requires a stated reactive fallback trigger alongside any
forecast-driven band, so a forecast miss has a defined recourse before
the next forecast cycle. Full evidence trail (tools surveyed, adoption
evidence, insight mapping) lives on the `on-the-record` working tree at
`docs/issue-1199/reports/capacity-planning.md` — none of it is
reproduced here.

## Tool-landscape refinements, Claude Code plugin sweep (issue-1199, 2026-08-14 amendment)

The original sweep above surveyed general practitioner domain tools
(Karpenter, Kubecost, Prophet, Scryer), which the issue's 2026-08-14
amendment ruled out of scope: the survey target is the CLAUDE CODE
PLUGIN/SKILL ecosystem itself. A second rule landed per axis from that
narrower sweep, each with its own `tool:`/adoption-evidence/`problem:`/
`how:`/`learning ->` block inline in the playbook file (not summarized
here, per this checklist's own no-catalog convention):
`expansion-trigger-threshold-sizing.md` rule 12 (from the
`alirezarezvani/claude-skills` `capacity-planner` skill's
"treat-ramp-as-instant" anti-pattern — new capacity must ramp to full
throughput, not appear instantly at lead_time's end);
`cost-attribution-at-trigger.md` rule 12 (from `ryoppippi/ccusage` —
cost notes must derive from real per-session/per-model usage records,
not a blended-average estimate); `safety-buffer-sizing-by-criticality.md`
rule 11 (from `Maciek-roboblog/Claude-Code-Usage-Monitor` — size the
buffer's variability driver from a rolling recent-usage window, not a
flat org-wide default); `headroom-band-and-degradation-risk.md` rule 12
(from `wshobson/agents`'s `observability-monitoring` plugin — the
reactive fallback trigger needs a named owner/escalation path, not just
a threshold value). Full evidence trail (adoption-evidence citations,
Problem/How/Learning detail) lives on the `on-the-record` working tree
at `docs/issue-1199/reports/capacity-planning.md`.

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
