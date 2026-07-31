# Proposal — deepen capacity-planning's enforcement machinery to
implementation-rulebook's hook-machine level (issue-7)

Subject: issue-7. Phase 1 only: this document is the plan; no plugin
change happens until Approve. Basis:
[survey.md](../reports/capacity-planning/survey.md),
[scout-brief.md](../reports/capacity-planning/scout-brief.md).

## (a) Directive deepening — `directive.sh`, all four arguments

Keep `core_role_directive`'s four-argument shape (no core-lib change;
this role owns only its own argument content, per issue-2's division of
labor). Deepen each argument from its current one-liner/partial-prose
into phase-split, judgment-criteria-bearing, prohibition-bearing text:

1. **`you_decide`** — split into phase 1 ("어떤 forecast method이 이
   워크로드의 데이터 모양에 맞는가, 어떤 트리거 공식이 적용되는가를
   설계") and phase 2 ("설계를 실제 기록으로 반영하고 실측 대비 검증")
   so a reader knows which decision belongs to which phase, per contract
   v3 s19's own two-phase split.
2. **`use_when`** — add the judgment criterion that distinguishes this
   role from its hand-off target: trigger when the question is *whether/
   when to expand*, not *why something is currently slow* (that line
   already exists as a hand-off but `use_when` itself stays a bare
   one-liner today — this makes the boundary self-contained in the
   `use_when` line, not only discoverable via the hand-off line).
3. **`produces`** — already elaborated by issue-1; add explicit
   **prohibitions** per facet, since the current text states only what
   must be present, never what is forbidden:
   - Forecast: prohibit merging organic/inorganic into one growth
     number; prohibit a horizon shorter than the stated lead time.
   - Threshold: prohibit a bare percentage with no growth_rate/
     lead_time/safety_buffer decomposition; prohibit a flat (non-
     percentile) threshold.
   - Headroom: prohibit a single snapshot number in place of a band.
   - Method: prohibit picking one method (regression/queueing/ML)
     without stating why it fits this workload's data shape (steady vs.
     scenario-specific vs. seasonality/campaign-driven) — this is
     issue-1 (a)#2's existing prose rule, promoted into the directive
     itself so it is visible at `SessionStart`, not only in a proposal
     doc.
4. **`hand_off`** — unchanged in substance (performance-engineering
   arrow already correct); add the boundary-case judgment line already
   used by this role's directive but tighten it: stop the moment the
   question becomes "why is X slow now" rather than "will X still fit
   later."

This is prose deepening of existing `core_role_directive` arguments — no
new hook, no core-lib change, no canon script copied (only referenced,
per the constraint).

## (b) Phase-1 methodology gate — new file,
`capacity-planning/hooks/capacity-proposal-gate.sh`

Modeled on (never copying) `pricing-rulebook`'s
`methodology-gate.sh` pattern, scoped to this role's own phase-1 write
surface, additive to core's generic gates, registered as an additional
`PreToolUse` (Write|Edit|MultiEdit) entry in
`capacity-planning/hooks/hooks.json` alongside the existing
`capacity-fields-gate.sh` (which stays phase-2-only, unchanged).

Target paths (this role's own phase-1 write surfaces only — exits 0,
no opinion, on anything else):
- `docs/issue-<n>/proposals/*capacity*.md`
- `docs/issue-<n>/reports/capacity-planning/*.md` (survey.md,
  scout-brief.md themselves — see state-tracking below)

Checks, on the reconstructed resulting content (Write full-content;
Edit/MultiEdit only when the resulting text is determinable from
`old_string`/`new_string`, else **deny** — undeterminable content is
never silently passed, mirroring pricing's own rule):

1. **Method-named-or-scope-exited**: content names one of
   regression/trend, queueing/scenario modeling, ML/seasonality-aware —
   or explicitly states the method question does not yet apply (e.g. a
   survey-only, non-terminal draft). A proposal that picks a method with
   zero justification text nearby fails this check (keyword-adjacency,
   not full NLP — matching pricing's `has_any()` granularity).
2. **Traceable-numeric-form**: if the content contains digits presented
   as a growth rate, lead time, or threshold, it must also contain a
   labeling/sourcing term (e.g. "per", "source:", "assumption:",
   "survey.md", "scout-brief.md") — mirrors pricing's "labeled-numbers"
   check, adapted to issue-1 (a)#3's "traceable numeric form" rule.
3. **Citation-presence (state/order enforcement)** — this is the
   mechanism that replaces a separate state file per scout-brief's
   adopt/skip: a **proposal** document must reference both
   `survey.md` and `scout-brief.md` (by filename, case-insensitive) for
   the gate to allow a terminal-looking write (heading `## (a)` or
   `## (c)` present, signaling the proposal has reached its rationale
   section — the same non-terminal leniency principle
   `capacity-fields-gate.sh` already applies, adapted: an early proposal
   draft with no rationale section yet is not blocked). A **survey**
   document is exempt from this check (it is the root of the order, has
   no predecessor to cite). A **scout-brief** document must reference
   `survey.md` (its own required predecessor, since scout runs after
   survey per the scout-directive's SURVEY-FIRST ORDER rule already
   governing this repo's process).
4. **Fail-closed**: unparseable JSON payload, missing `python3`,
   undeterminable resulting content, or any internal exception all deny
   (exit 2), matching every existing gate in this repo and its sibling
   rulebooks.

Kill switch: `CAPACITY_PROPOSAL_GATE_OFF=1`, matching this repo's
`<ROLE>_..._OFF` naming convention.

## (c) Gate tests — new root `tests/` directory

New root-level `tests/run-gate-tests.sh` (this repo currently has no
root `tests/` at all; adds the directory), modeled on
implementation-rulebook's adjacent test-harness pattern (referenced, not
copied — the actual assertions are specific to this role's checks).
Cases, each invoking the gate script with a synthetic PreToolUse JSON
payload on stdin and asserting exit code:

- **Pass**: a terminal-looking proposal citing both survey.md and
  scout-brief.md, naming a method with adjacent justification, and
  labeling its numeric growth-rate/lead-time terms → exit 0.
- **Deny — missing citation**: same proposal with `scout-brief.md`
  reference removed → exit 2, message names the missing citation.
- **Deny — unlabeled numbers**: a proposal with a bare growth-rate digit
  and no labeling term nearby → exit 2.
- **Deny — no method and not scope-exited** → exit 2.
- **Pass — non-terminal draft**: a proposal with no `## (a)`/`## (c)`
  heading yet (still drafting) and no citations yet → exit 0 (leniency).
- **Pass — survey document itself** (exempt from citation check) → exit 0.
- **Deny — scout-brief missing survey citation** → exit 2.
- **Deny — unparseable payload / undeterminable Edit content** → exit 2
  (fail-closed).
- **No-op on out-of-scope path** (e.g. a write to
  `docs/issue-<n>/reports/capacity-planning.md`, this role's phase-2
  surface, which the new gate must not touch) → exit 0, no message.

## (d) Agents/checklist for the repeated forecasting procedure

The methodology has one genuinely repeated procedure worth a checklist:
selecting a forecast method by data shape and validating a prior
forecast against actuals before trusting a new one. Add
`docs/handbooks/capacity-planning/forecast-checklist.md` (a handbook,
per this repo's standing `docs/` bucket convention — not a new
top-level directory) with the ordered steps: (1) classify the workload's
demand shape (steady/organic, scenario-specific/inorganic, seasonality-
or campaign-driven), (2) pick method accordingly and state why, (3) if a
prior forecast for the same subject exists, check match/diverge before
producing a new number, (4) derive the threshold via the growth_rate ×
lead_time × safety_buffer formula and state the percentile, (5) state
headroom as a band. This is a checklist, not an agent — no repeated
autonomous multi-step tool-use loop was found in the methodology that
would warrant a dedicated subagent definition (the whole procedure is
performed by the human/agent already holding the capacity-planning role
directive; a checklist is the correct weight, per the issue's own "필요
시" qualifier).

## Not touched

- Core's `record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` — core-owned, unchanged.
- `capacity-fields-gate.sh` (existing phase-2 gate) — unchanged; the new
  gate in (b) is additive alongside it, not a replacement.
- `capacity-planning/.claude-plugin/plugin.json` — unchanged, per
  issue-2's existing division (directive detail lives in `directive.sh`
  only).
- No canon script from `pricing-rulebook` or `implementation-rulebook` is
  copied; only their shape/pattern is referenced, per the constraint.

## Rationale

- The current phase-2-only gate leaves the entire phase-1 methodology
  norm (issue-1 (a)) as prose the human approver must catch by reading,
  exactly the gap the issue names against implementation-rulebook's
  hook-machine bar. A phase-1 gate closes that gap using this repo's own
  already-adopted norm as its source (no new methodology invented here —
  issue-1's norm is the one being mechanized, not superseded).
- Citation-presence as the order-enforcement mechanism (rather than a
  new state file) is the scout-brief's explicit adopt/skip conclusion:
  none of the three in-repo exemplars need a separate state machine,
  and introducing one here would be machinery beyond what the field's
  converged pattern requires.
- Gate tests and a checklist are the two requirements this repo has
  never had any file for (no root `tests/`, no
  `docs/handbooks/capacity-planning/`); both are additive, filling a
  literal absence rather than replacing anything.
