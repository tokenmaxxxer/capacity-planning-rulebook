# Proposal — capacity-planning methodology & deliverable norm (issue-1)

Subject: issue-1. Phase 1 only: this document is the plan; no plugin
change happens until Approve. Basis:
[survey.md](../reports/capacity-planning/survey.md),
[scout-brief.md](../reports/capacity-planning/scout-brief.md).

## (a) Phase-1 proposal norm

Every future capacity-planning proposal in this repo (this one included,
retroactively self-consistent) must:

1. Cite its survey and scout-brief (already this repo's convention per
   issue-2's proposal; kept, not reinvented).
2. State, for its recommended forecast, **which method it justifies and
   why** against the workload's own data shape — trend/regression for
   steady organic growth, queueing/scenario modeling for a specific
   business event, ML only when seasonality or campaign-driven demand is
   actually present. A proposal that picks a method without this
   justification fails the norm (this is the field's own must-be per
   scout-brief §"Performance axes", axis 1 — no universal algorithm).
3. Show its evidence in a **traceable numeric form**: any growth rate,
   lead time, or threshold cited must show its source data or
   assumption, not a bare conclusion.

## (b) Phase-2 deliverable norm — required components

Every phase-2 capacity-planning record
(`docs/issue-<n>/reports/capacity-planning.md`) must contain, inside its
existing §20 "what was done" section, three named subsections mapping
1:1 to `directive.sh`'s `PRODUCES` line:

1. **Capacity forecast**
   - Organic vs. inorganic demand stated separately (never merged into
     one growth number) — scout-brief must-be 1.
   - Forecast horizon stated explicitly, and must exceed the acquisition
     lead time named in the expansion-trigger section below — must-be 2.
   - Method named plus the one-line justification required by (a)#2.
   - If a prior forecast exists for the same subject, a forecast-vs-actual
     check against it (match / diverge, and if diverge, flagged as a
     model-instability signal, not silently updated) — scout-brief
     "Performance axes" axis 3.

2. **Expansion trigger thresholds**
   - Expressed as `warning_threshold = 100% − (growth_rate × lead_time) −
     safety_buffer`, with each of the three terms given a concrete value,
     not left as a bare percentage — must-be 3.
   - Stated as a percentile of demand (e.g., "sized to p97.5 over the
     forecast horizon"), so the residual risk is an explicit number —
     axis 2.
   - Headroom stated as a **band**, not a single snapshot number —
     must-be 4. 30–40% spare-capacity-above-baseline is the default
     reference band from scout-brief; a record may justify a different
     band but must state one.

3. **Cost note**
   - At minimum: incremental cost of the recommended expansion,
     attributed to the specific trigger threshold that fires it (so a
     later reader can see which number drove which spend).

A record missing any of the three subsections, or stating a threshold as
a bare number with no growth-rate/lead-time/safety-buffer decomposition,
does not meet this norm.

## (c) Rationale — why this is the adoption, not a competing alternative

- The role's own `WRITE_SCOPE: []` (report-only, per directive.sh) means
  its entire value is the *decision-support artifact itself* — there is
  no code output to fall back on if the record's numbers are unusable.
  A forecast/threshold/cost-note norm that forces traceable assumptions
  (organic/inorganic split, percentile, growth/lead-time/buffer
  decomposition) is what makes the artifact actually actionable by the
  human deciding whether to expand — matching the directive's `you_decide`
  line ("향후 수요 성장 대비 자원이 충분하며 언제 증설해야 하는가")
  directly: "충분한가" needs the headroom band, "언제" needs the
  lead-time-derived trigger, not a bare rule of thumb.
- The alternative — leaving `PRODUCES` as three bare nouns, unmethodology'd
  — is the status quo the survey found, and it is exactly what let a
  record pass the generic §20 gate today while omitting every must-be the
  field itself treats as non-negotiable (a forecast with no organic/
  inorganic split, a threshold with no lead-time term, a headroom
  snapshot instead of a band all currently pass silently).
- Not mandating one fixed forecasting algorithm (skip, per scout-brief)
  is itself principled, not a gap: the field's converged position across
  all three sweep angles is method-justified-by-data-shape, so hardcoding
  one algorithm would contradict the very source this proposal cites.

## (d) Plugin reflection plan (phase 2, gated on Approve)

1. **`directive.sh` `PRODUCES` line** — expand from the current bare
   `"capacity forecast, expansion trigger thresholds, cost note"` to name
   the three required subsections and their one-line shape, e.g.:
   `"capacity forecast (organic/inorganic split, horizon > lead time,
   method+justification), expansion trigger thresholds (growth_rate ×
   lead_time × safety_buffer, percentile-stated, headroom as a band),
   cost note (cost attributed to the firing threshold)"`. This stays a
   `core_role_directive` `produces` argument — no new plugin machinery,
   same stub shape issue-2 already landed.
2. **New role-owned gate**: `capacity-planning/hooks/capacity-fields-gate.sh`,
   registered as an additional `PreToolUse` entry (Write|Edit|MultiEdit)
   in `capacity-planning/hooks/hooks.json`, running *after* core's
   generic `record-fields-gate.sh` (which stays registered globally from
   core — this issue does not touch it). Scope: only fires on writes
   targeting this role's own record path
   (`docs/issue-<n>/reports/capacity-planning.md`), mirroring
   `record-fields-gate.sh`'s own target-resolution approach so the two
   gates share detection logic rather than diverging. Checks, on a
   terminal-`loop_state` write, that all three (b)-subsections are
   present by heading, and that the threshold subsection contains all
   three named terms (`growth_rate`/`lead_time`/`safety_buffer` or their
   Korean equivalents) plus a percentile token. A non-terminal
   (in-progress) write is not blocked — same leniency principle
   `record-fields-gate.sh` already applies to its own next-steps
   requirement.
   Kill switch: `CAPACITY_FIELDS_GATE_OFF=1`, matching the `<ROLE>_..._OFF`
   naming convention core's own gates use.
3. **Record required fields** — no change to `record-fields-gate.sh`
   itself (core-owned, out of this role's write scope per issue-2); the
   new gate in item 2 is additive, not a fork of the generic one.
4. **`RECORD_FIELDS_TERMINAL_STATES`** — no override proposed here either;
   unchanged from issue-2's phase-1 conclusion (open item, revisit only if
   phase-2 execution surfaces an actual divergent terminal state).

## Not touched

- `capacity-planning/.claude-plugin/plugin.json` — its description text
  already carries `you_decide`/`use_when`/hand-off; the `PRODUCES` detail
  this proposal adds lives in `directive.sh` only, per issue-2's existing
  division of labor.
- Core's own `record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` — all core-owned per issue-2; this issue adds
  a role-owned gate alongside them, never edits them.
