# Current-state survey — capacity-planning plugin enforcement machinery (issue-7)

Subject: issue-7. Phase 1 only.

## What exists today

- `capacity-planning/hooks/directive.sh` — a `core_role_directive` call.
  Its `produces` argument already carries issue-1's adopted norm in
  parenthetical form (organic/inorganic split, horizon > lead time,
  method+justification; growth_rate × lead_time × safety_buffer,
  percentile-stated, headroom as a band; cost attributed to the firing
  threshold). This is denser than a bare one-line summary already, but
  it is still a single flat `SessionStart` print with no phase split, no
  named judgment criteria per facet, and no explicit prohibitions — it
  states *what* the record must contain, never *how to decide* the
  method, the percentile, or the buffer, and never what NOT to do.
- `capacity-planning/hooks/capacity-fields-gate.sh` — a `PreToolUse`
  gate, additive to core's generic `record-fields-gate.sh`, firing only
  on `docs/issue-*/reports/capacity-planning.md` (the **phase-2 record**),
  only on a terminal-state write. Checks: three subsection headings
  present (Capacity forecast / Expansion trigger thresholds / Cost note)
  and, inside the threshold subsection, the three named terms
  (`growth_rate`/`lead_time`/`safety_buffer`) plus a percentile token.
- No gate fires on **phase-1 writes**
  (`docs/issue-<n>/proposals/*capacity*.md`,
  `docs/issue-<n>/reports/capacity-planning/*.md`) at all — the phase-1
  proposal norm from issue-1 (a) ("cite survey+scout-brief", "state which
  method it justifies and why against the workload's data shape", "show
  evidence in traceable numeric form") is prose-only; nothing machine-
  checks a phase-1 proposal against it. A proposal could omit the
  method-justification or cite no survey/scout-brief and nothing would
  refuse the write.
- No state/order tracking exists: the methodology's own sequence
  (survey → scout/evidence → adoption → reflect) is enforced only by the
  human role-handoff contract's two-phase gate (Approve), not by any
  in-repo mechanism checking that a proposal's required predecessor
  artifacts (survey.md, scout-brief.md) actually exist before the
  proposal is allowed to reach a terminal/citing state.
- No gate tests exist anywhere in this repo (no root `tests/` directory).
- No `agents/` or checklist exists for the repeated forecasting procedure
  (method selection by data shape, threshold decomposition, forecast-vs-
  actual validation loop) — a human/agent doing capacity-planning work
  today has only the directive's prose to follow procedurally each time.

## Gaps against issue-7's ask, mapped to its four requirements

1. **Directive depth** — partial only: `produces` is elaborated, but
   `you_decide`/`use_when`/`hand_off` are still one-liners, and none of
   the four carries phase-split steps, judgment criteria, or explicit
   prohibitions per facet (forecast / threshold / cost note).
2. **Methodology gate** — exists for phase-2 record only; **absent for
   phase-1 proposal content** (no check that a proposal names its method-
   justification, shows traceable numeric evidence, or cites its
   survey/scout-brief). No state tracking for the survey→evidence→
   adoption order at all.
3. **Gate tests** — absent entirely (no root `tests/`).
4. **Agents/checklist** — absent.

## Reference points available in-repo (canon, not to be copied)

- `pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh` —
  a `PreToolUse` gate that fires on **both** phase-1 proposals
  (`docs/issue-<n>/proposals/*pricing*.md`) and the phase-2 record,
  content-checking for named required elements (method named, family
  named conditionally, inputs-needed stated, gate-check result present,
  labeled numbers, residual list) via `has_any()` keyword-presence
  checks, fail-closed on internal error and on unparseable/undeterminable
  new content.
- `implementation-rulebook-issue-61-implementation/coding/hooks/coding-progress-gate.sh`
  and its `tests/run-gate-tests.sh` — a gate + adjacent root-level test
  harness pattern for progress/state-order enforcement.
- Core's own `record-fields-gate.sh` — the generic §20 fields gate this
  role's existing `capacity-fields-gate.sh` is already additive to; same
  target-resolution and fail-closed conventions reusable for a new
  phase-1 gate.
