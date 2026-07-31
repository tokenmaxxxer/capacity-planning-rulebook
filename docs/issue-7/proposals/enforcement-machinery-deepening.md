# Proposal — enforcement machinery as a plugin set (issue-7)

Subject: issue-7. Phase 1 only: this document is the plan; no plugin
change happens until Approve. Basis:
[survey.md](../reports/capacity-planning/survey.md),
[scout-brief.md](../reports/capacity-planning/scout-brief.md).

## Restructuring note

**Second-round update:** a subsequent domain review returned a WEAK
verdict, requiring named canon attribution for the three methodologies,
literal checklist prose (not a future-file reference), and a
forecast-method gate stronger than bare keyword presence. The sections
below (Canon attribution; Checklist draft text; the revised plugin-list
row 1 and phase-1 norm bullet) are additive responses to that feedback;
nothing in the plugin-set shape established by the first restructuring
round is reverted.

An approver rejected a single deepened gate/directive as the shape of
this deliverable. Required shape, verbatim from the approver's issue-7
comment:

> 단일 게이트/디렉티브 심화가 아니라 플러그인 세트로 체계화한다:
> - 채택 방법론 각각을 독립 플러그인으로 (core의 freelunch/scout처럼 —
>   룰북당 여러 개, freelunch 수준의 완성도).
> - 기획서(phase 1) 규범과 산출물(phase 2) 규범도 각각을 플러그인
>   조합으로 풀어낸다 — 어떤 플러그인들이 조합되어 그 규범이 성립하는지가
>   설계의 본체.
> - 각 플러그인 = 자기 완결(디렉티브/게이트/에이전트/테스트 포함
>   가능), marketplace.json 등록, 명확한 단일 방법론 담당.
> - proposal에는 플러그인 목록(이름·담당 방법론·구성요소·조합 관계)이
>   필수.

This supersedes the prior draft of this proposal in full. The unit of
delivery is no longer "one gate script plus one directive edit" — it is
a **set of independent, self-contained plugins**, one per adopted
methodology, each registered in this repo's `.claude-plugin/marketplace.json`
alongside the existing `capacity-planning` plugin entry. The
survey/scout-brief's factual findings (what exists, what's missing,
which sibling exemplars were scouted) are unchanged and still the
evidence base; only the shape of what phase-2 will build is
restructured here.

## Methodologies to decompose into plugins

From `docs/issue-1/proposals/capacity-planning-methodology-norm.md` (the
already-adopted norm this rulebook exists to enforce), three genuinely
distinct methodologies are in scope, each independently choosable and
independently checkable — this is what makes a one-plugin-per-methodology
split correct rather than arbitrary slicing:

1. **Forecast-method selection** — classify workload demand shape
   (steady/organic vs. scenario-specific/inorganic vs. seasonality- or
   campaign-driven) and pick, per that shape: linear/exponential
   regression trend fit (steady organic growth), Holt-Winters
   exponential smoothing or ARIMA (seasonality- or campaign-driven
   demand), or scenario/queueing modeling (a specific inorganic event) —
   or an explicitly justified alternative — with justification tied to
   the data shape. See "Canon attribution" below for the named source
   this is drawn from.
2. **Threshold decomposition** — expansion trigger stated as
   `growth_rate × lead_time × safety_buffer`, percentile-stated, never a
   bare flat percentage. See "Canon attribution" below for why this
   formula is principled rather than arbitrary.
3. **Headroom/cost attribution** — headroom stated as a band (not a
   snapshot number), cost attributed to the threshold that fires it. See
   "Canon attribution" below for the named source behind band-not-
   snapshot.

## Canon attribution

The three methodologies above are not generic "industry best practice"
— each traces to a named, real source, and the checklist/gate design
downstream of this proposal names these sources directly instead of
using vague category labels:

- **Forecast-method selection** attributes to *Site Reliability
  Engineering* (O'Reilly, ed. Betsy Beyer, Chris Jones, Jennifer Petoff,
  Niall Richard Murphy), the "Capacity Planning" chapter. That chapter's
  organic-vs-inorganic growth framing is exactly what this proposal's
  `capacity-forecast-method` plugin already encodes: organic growth is
  the demand-shape case that calls for a trend-fit method, and
  inorganic/scenario-driven growth is the case that calls for
  scenario/queueing modeling instead. The "regression/trend,
  queueing/scenario modeling, ML/seasonality-aware" category labels in
  the original draft of this proposal are, per this attribution, real
  named techniques: **linear/exponential regression trend fitting** for
  steady organic growth, and **Holt-Winters exponential smoothing**
  (triple exponential smoothing, handling trend and seasonality
  together) and/or **ARIMA** (AutoRegressive Integrated Moving Average,
  the Box-Jenkins family) for seasonality- or campaign-driven demand.
  This remains a "name it or justify a documented alternative"
  requirement — the SRE chapter's own principle that method selection
  must be justified by the shape of the demand data survives unchanged;
  only the placeholder category labels are replaced with real technique
  names.
- **Threshold decomposition / headroom methodology** attributes to
  queueing theory, specifically **Little's Law** (L = λW: queue length
  equals arrival rate times wait time — Little, 1961) and the
  **Universal Scalability Law** (USL — Neil J. Gunther's model of
  throughput as a function of contention and coherency cost as
  concurrency scales). Little's Law is the reason `lead_time` and
  `growth_rate` combine multiplicatively into a sizing figure rather
  than being tracked independently: `lead_time` is the "wait" term (how
  long expansion takes to land) and `growth_rate` is the "arrival rate"
  term (how fast demand is arriving against current capacity) — their
  product, scaled by a `safety_buffer` percentile, is what determines
  how much queue (unserved demand) accumulates before expansion
  completes, which is exactly the sizing question the expansion-trigger
  threshold answers. USL is the reason headroom must be expressed as a
  band and not a snapshot number: USL models scaling as degrading
  non-linearly (via contention and coherency cost) as a system
  approaches its capacity limit, so a single point-in-time headroom
  number cannot represent how quickly that margin degrades under
  load — only a band communicates the "how much room, and how fast does
  that room shrink as we approach the edge" information USL says is the
  actual risk. Together these two named theories are why
  `growth_rate × lead_time × safety_buffer` and the band-not-snapshot
  headroom requirement are principled formulas grounded in queueing
  theory, not arbitrary conventions invented for this rulebook.

Each gets its own plugin below. A fourth plugin, **order-enforcement**,
is not a methodology from issue-1 but a cross-cutting mechanism
(citation-presence for survey → scout-brief → proposal → record
sequencing) that scout-brief's adopt/skip section identifies as
required infrastructure shared by the other three — it is broken out as
its own plugin rather than folded into one of the three because it
fires on document *order*, not on any one methodology's content, and
every methodology plugin's phase-1 check depends on it having run.

## Plugin list

Each plugin lives at `<plugin-name>/` (sibling to the existing
`capacity-planning/` plugin directory), with its own
`.claude-plugin/plugin.json`, and is registered as its own entry in the
root `.claude-plugin/marketplace.json` `plugins` array — modeled on how
`freelunch` (`~/freelunch/freelunch`: `.claude-plugin/plugin.json`,
`agents/freelunch-worker.md`, `hooks/hooks.json` + `hooks/*.sh`,
`workflows/*.js`) is one self-contained, marketplace-registered unit
per capability rather than a shared blob. No plugin file is written in
this phase — this is the registry the phase-2 execution will fill in.

| # | Plugin name | Methodology owned | Components | Composes into |
|---|---|---|---|---|
| 1 | `capacity-forecast-method` | Forecast-method selection (data-shape → named technique + justification, per SRE book "Capacity Planning" chapter) | `hooks/forecast-method-gate.sh` (PreToolUse, phase-1 proposal surface: verifies the named method matches an allow-list of recognized technique-name keywords — `regression`, `trend`, `holt-winters`/`holt winters`, `arima` — or the literal `대안:`/`alternative:` marker followed by free-text justification; requires a minimum-length justification (>= N characters of prose, not just the bare keyword) following the method name; cross-checks that the justification co-occurs with a data-shape classification term (`organic`/`inorganic`/`seasonal`/`campaign`/조직적/비조직적/계절), so a method claim cannot stand unlinked from a classified shape; fail-closed if any of the three checks fails); `hooks/directive.sh` fragment deepening `you_decide`/`use_when` phase-1 half with the data-shape judgment criterion; `docs/handbooks/capacity-planning/forecast-checklist.md` (steps 1–3 of the checklist below: classify shape, pick named method, check prior-forecast divergence); `tests/run-gate-tests.sh` cases for method-named-with-shape-link / scope-exited / no-method-fail / keyword-without-justification-fail / justification-without-shape-link-fail | Phase-1 proposal norm |
| 2 | `capacity-threshold-decomposition` | Threshold decomposition (`growth_rate × lead_time × safety_buffer`, percentile) | `hooks/threshold-gate.sh` (PreToolUse, fires on **both** phase-1 proposal and phase-2 record surfaces: traceable-numeric-form check — any growth-rate/lead-time/threshold digit must carry a labeling/sourcing term; flat-percentage prohibition); `hooks/directive.sh` fragment deepening the `produces` threshold facet with its explicit prohibition (no bare percentage, no non-percentile threshold); checklist step 4; gate tests for labeled/unlabeled numbers and flat-percentage rejection | Phase-1 proposal norm AND phase-2 deliverable norm |
| 3 | `capacity-headroom-costnote` | Headroom-as-band + cost attribution | `hooks/headroom-gate.sh` (PreToolUse, phase-2 record surface only, additive to core's `record-fields-gate.sh` and to this role's existing `capacity-fields-gate.sh`: band-not-snapshot check on the headroom subsection, cost-attributed-to-threshold presence check); `hooks/directive.sh` fragment deepening the `produces` headroom/cost facets with their prohibitions; checklist step 5; gate tests for band-present/snapshot-rejected and cost-note-present/absent | Phase-2 deliverable norm |
| 4 | `capacity-order-enforcement` | Citation-presence / document-sequencing (survey → scout-brief → proposal → record), the mechanism scout-brief's adopt/skip section names in place of a separate state file | `hooks/citation-gate.sh` (PreToolUse, phase-1 proposal and phase-1 report surfaces: proposal must cite `survey.md` and `scout-brief.md` by filename once a terminal-looking section heading is present, non-terminal drafts exempt; scout-brief must cite `survey.md`; survey itself exempt — root of the order); shared `tests/run-gate-tests.sh` cases for citation present/missing per document type, and for the non-terminal-draft leniency case | Phase-1 proposal norm (citation half) — a precondition every other phase-1 check in plugins 1–2 depends on before its own content checks run |

Each plugin's `.claude-plugin/plugin.json` states its single owned
methodology in its `description` field (mirroring how the existing
`capacity-planning` plugin entry in `marketplace.json` states its single
role in one line) — no plugin's description spans more than one
methodology.

## Norm composition (the actual design)

### Phase-1 (기획서/proposal) norm

A proposal document is compliant when **all three** of the following
plugins' phase-1 checks pass on it — none of the three is sufficient
alone, and none is redundant with another:

- `capacity-order-enforcement` — the proposal cites its required
  predecessors (survey.md, scout-brief.md) once it reaches a
  terminal-looking section. This runs conceptually first: it establishes
  that the proposal is grounded in the correct evidence chain before
  content checks are meaningful.
- `capacity-forecast-method` — the proposal names a forecast method
  from the recognized set (linear/exponential regression trend fit,
  Holt-Winters exponential smoothing, ARIMA, scenario/queueing
  modeling) — or an explicitly justified alternative — (or explicitly
  states the method question doesn't yet apply) with a non-trivial
  justification tied to the workload's data-shape classification, per
  the gate's three-part check described in the plugin list table above.
- `capacity-threshold-decomposition` (phase-1 half) — any numeric
  growth-rate/lead-time/threshold figure in the proposal is traceable
  (labeled/sourced), even though the full band/percentile structure
  isn't required to be final at proposal stage.

`capacity-headroom-costnote` does **not** participate in the phase-1
norm — headroom-as-band and cost-attribution are phase-2-only
obligations per issue-1's own two-phase split, so that plugin's gate is
scoped to the record surface only.

### Phase-2 (산출물/deliverable) norm

A deliverable record (`docs/issue-<n>/reports/capacity-planning.md`) is
compliant when **all three** of the following plugins' phase-2 checks
pass:

- `capacity-threshold-decomposition` (phase-2 half) — the threshold
  subsection contains `growth_rate`/`lead_time`/`safety_buffer` plus a
  percentile token, no bare flat percentage.
- `capacity-headroom-costnote` — headroom expressed as a band, cost
  attributed to the firing threshold.
- (implicitly, core's own generic `record-fields-gate.sh` and this
  role's existing `capacity-fields-gate.sh`, both unchanged and outside
  this proposal's scope, continue to check the three-subsection
  structural shape those two plugins' gates are additive to.)

`capacity-forecast-method`'s gate does not fire on the phase-2 record
surface — method selection is a phase-1 decision; phase-2 checks that
the decision was *recorded* (via the threshold plugin's numeric-form
check on the same figures), not that a fresh method choice is
re-justified. `capacity-order-enforcement` does not fire on the
phase-2 record either — order/citation is a phase-1-only concern per
scout-brief (the record is the terminal artifact, nothing comes after
it to require it cite its own predecessor beyond what phase-1 already
enforced upstream).

This composition — which plugins combine, and which phase(s) each
contributes to — is the design; the plugin list table's rightmost
column is the same information indexed by plugin instead of by norm.

## Checklist draft text (docs/handbooks/capacity-planning/forecast-checklist.md, phase-2 execution will write this verbatim)

This proposal previously gestured at the checklist ("steps 1–3: classify
shape, pick method, check prior-forecast divergence"; "checklist step
4"; "checklist step 5") without stating the actual wording. The literal
draft text below is what phase-2 execution will write verbatim into
`docs/handbooks/capacity-planning/forecast-checklist.md`; it is not a
placeholder and may only be refined in wording, not left unwritten:

```
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
   Universal Scalability Law's non-linear degradation near capacity —
   see Canon attribution), and attribute the incremental cost of the
   recommended expansion to the specific threshold that fires it.
```

Steps 1–2 are owned by `capacity-forecast-method`, step 3 is the
prior-forecast-divergence check also owned by `capacity-forecast-method`,
step 4 is owned by `capacity-threshold-decomposition`, and step 5 is
owned by `capacity-headroom-costnote` — matching the plugin-list table's
"Methodology owned" column above.

## marketplace.json registration (described, not executed)

Phase-2 execution will add four new entries to the existing `plugins`
array in `.claude-plugin/marketplace.json`, one per plugin above, each
with `name`, `source` (`./capacity-forecast-method`,
`./capacity-threshold-decomposition`, `./capacity-headroom-costnote`,
`./capacity-order-enforcement`), and a `description` naming that
plugin's single owned methodology — following the exact shape of the
existing `capacity-planning` entry. The `capacity-planning` plugin
entry itself is unchanged; these are additive siblings, not a
replacement or a restructuring of it. No `marketplace.json` edit and no
plugin scaffolding happens in this phase-1 document.

## Not touched (unchanged from current state)

- Core's `record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` — core-owned, unchanged.
- `capacity-fields-gate.sh` (existing phase-2 gate) — unchanged; the
  new plugins' phase-2 gates are additive alongside it.
- `capacity-planning/.claude-plugin/plugin.json` and its `marketplace.json`
  entry — unchanged.
- No canon script from `pricing-rulebook`, `implementation-rulebook`, or
  `freelunch` is copied; only shape/pattern is referenced, per the
  constraint already in force from the prior draft.

## Rationale

- The approver's instruction reframes the deliverable from "deepen one
  gate/directive" to "systematize as a plugin set," matching how core
  itself is organized (`freelunch`, `scout`, one plugin per capability,
  each self-contained and separately registered) rather than a
  monolithic rulebook plugin acquiring more internal machinery.
  Per-methodology plugins make each check independently auditable,
  independently toggleable (each plugin can carry its own kill switch),
  and independently testable, instead of bundling three unrelated
  content checks into one gate script as the prior draft's (b) did.
- The phase-1/phase-2 norm split was already established by issue-1;
  what changes here is that each norm is now defined as an explicit
  *composition* of plugins rather than as prose describing one gate's
  internal logic. This makes it possible to state, e.g., "phase-1 norm =
  order-enforcement + forecast-method + threshold(phase-1 half)" as a
  literal, checkable set membership rather than a paragraph.
  Order-enforcement is its own plugin (not folded into forecast-method
  or threshold-decomposition) because it is the one check every other
  phase-1 plugin's content check logically depends on running after —
  citation-presence is a precondition, not a fourth parallel content
  check of the same kind as the other two.
- Threshold-decomposition spans both norms (unlike forecast-method and
  headroom-costnote, which are phase-1-only and phase-2-only
  respectively) because issue-1's adopted norm itself requires
  traceable numeric form at proposal time and full decomposed structure
  at record time for the *same* growth_rate/lead_time/safety_buffer
  figures — one plugin owning both halves keeps the single methodology
  in one place rather than splitting it across two plugins that would
  otherwise duplicate the same digit-checking logic.
- marketplace.json registration is described at the proposal level only,
  per phase-1/phase-2 gating already in force in this repo (execution
  work, including writing any plugin file or editing marketplace.json,
  is phase-2 and gated on Approve).
