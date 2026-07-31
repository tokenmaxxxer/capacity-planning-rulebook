# Current-state survey — capacity-planning rulebook (issue-1)

Subject: issue-1. Phase 1 survey, feeds the proposal directly.

## What exists today

- `capacity-planning/hooks/directive.sh` — already a core-canon stub
  (issue-2 landed this). `PRODUCES` field: "capacity forecast, expansion
  trigger thresholds, cost note". `WRITE_SCOPE: []` (report-only role — no
  code/doc write outside the record itself). `HAND-OFF`: 성능 자체의
  병목 원인 분석은 → performance-engineering.
- `capacity-planning/hooks/hooks.json` — only `SessionStart` →
  `directive.sh` registered. The three role-agnostic gates
  (trailer-gate, record-fields-gate, handbook-trigger-gate) fire from
  `core/hooks/hooks.json` globally, keyed off `CLAUDE_ROLE`; nothing
  role-specific to add here for this issue.
- `capacity-planning/.claude-plugin/plugin.json` — description mirrors
  the directive's you_decide/use_when/hand-off; no methodology content.
- No `docs/issue-1/reports/capacity-planning.md` record file exists yet
  (phase-2 output, gated behind Approve).
- No prior proposal or report exists in this repo for this role's own
  methodology — issue-2's proposal (`docs/issue-2/proposals/
  core-canon-reference-switch.md`) is a structural/plugin-mechanics
  precedent (how a proposal cites survey.md, how it phases items, how it
  treats "not touched" explicitly) but carries zero domain content for
  capacity planning itself.
- `docs/specs/approvers.md` lists `JiwonJung94` as sole approver
  (single-account mode applies: this session's PR author and the
  approver are the same GitHub account).

## What is NOT specified anywhere in this repo (the gap this issue must close)

1. **Phase-1 proposal norm** — no rulebook, in this repo or referenced
   from core, prescribes what *methodology* a capacity-planning proposal
   should follow (e.g., how a forecast should be built, what workload
   model to assume), what sections are mandatory beyond the generic
   plugin-mechanics ones issue-2 established, or what "근거 형식"
   (evidence format) a proposal must show its numbers in.
2. **Phase-2 output norm** — the directive's `PRODUCES` field lists three
   bare nouns ("capacity forecast, expansion trigger thresholds, cost
   note") with no definition of what each must *contain* to count as
   done — no required components (e.g., does a forecast need a stated
   growth-rate assumption? a confidence range? a time horizon?), no
   required trigger-threshold shape (single number vs. lead-time-aware
   band), no required cost-note structure.
3. **Record required fields, beyond generic §20** — `record-fields-gate.sh`
   enforces the generic minimum (what/why/basis/loop_state/open-findings,
   +next-steps when non-terminal) for *every* role's record uniformly.
   It has no capacity-planning-specific field requirement (e.g., a
   forecast record without a stated confidence interval or a stated
   trigger threshold would currently pass the generic gate untouched).
4. **No plugin-side enforcement point exists yet** for whatever
   methodology/field norm this issue adopts — `directive.sh`'s `PRODUCES`
   string is free text today; there is no gate that checks a
   capacity-planning record actually contains a forecast method name,
   a threshold, and a cost note in a recognizable, checkable shape.

## Gaps that must anchor the scout sweep

Because nothing above answers "what does a *good* capacity forecast /
expansion-threshold / cost-note actually contain", the scout sweep aims
at exactly these three open questions, sourced from the field's
well-known methodology rather than invented from the issue text alone:

- Sweep angle A: canonical **capacity-planning forecasting methodology**
  (textbook/industry-standard techniques for projecting resource demand).
- Sweep angle B: canonical **expansion-trigger / threshold-setting**
  practice (how mature capacity-planning practice decides *when* to act,
  not just *how much*).
- Sweep angle C: canonical **capacity-planning deliverable structure**
  in industry practice (SRE / cloud capacity planning docs — what
  sections a real capacity plan document contains, so phase-2's
  required-components list has a citable basis instead of guesswork).

## Skip record

Not applicable — scouting is warranted (open methodology gap above) and
was run; see `scout-brief.md`.
