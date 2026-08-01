# Survey — current-state audit for issue-10 (gate A+ remediation)

Subject: issue-10. Current-state survey of every hook/test in this repo,
against the 2026-08-01 code-audit findings in the issue body and against
`docs/handbooks/gate-house-standard.md` (core issue #72, landed —
`core/hooks/lib/gate-lib.sh` PR #74 merged 2026-08-01T06:55:01Z).

## Inventory

Five gate scripts, one test suite, one README:

- `capacity-planning/hooks/capacity-fields-gate.sh` (108 lines) — phase-2
  record required-field gate.
- `capacity-forecast-method/hooks/forecast-method-gate.sh` (115 lines) —
  phase-1 proposal forecast-method-selection gate.
- `capacity-threshold-decomposition/hooks/threshold-gate.sh` (126 lines) —
  proposal + record threshold-decomposition gate.
- `capacity-headroom-costnote/hooks/headroom-gate.sh` (109 lines) — record
  headroom/cost gate.
- `capacity-order-enforcement/hooks/citation-gate.sh` (107 lines) —
  proposal + scout-brief citation-chain gate.
- `tests/run-gate-tests.sh` (97 lines) — the only test file in the repo.
- `README.md` — Layout section.

## Finding 1 — fail-closed is dead code; malformed JSON is allowed

Every gate's `file_path` extraction is the same shape:

```
file_path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
...
' 2>/dev/null)" || { echo "...: unparseable payload" >&2; exit 2; }
```

`sys.exit(0)` on a `json.load` failure makes the inner python process exit
0. The bash `||` after the command substitution only fires on a **non-zero**
exit from that substitution — so a malformed payload never reaches the
`|| { ...; exit 2; }` branch at all; it is dead code. The extraction prints
nothing, `file_path=""`, none of the `case` patterns match, and every gate
falls through to `*) exit 0` (allow). Confirmed by direct read for all
five gates: `capacity-fields-gate.sh:9-19`,
`forecast-method-gate.sh:12-20`, `threshold-gate.sh:14-22`,
`headroom-gate.sh:13-21`, `citation-gate.sh:13-21` — identical idiom, same
bug, no exceptions. This is exactly the issue body's "fail-closed가
도달 불능 데드 코드(실측 fail-open, malformed JSON=허용)" finding, verified
line-by-line rather than assumed from the issue text.

The `set -euo pipefail` at the top of each script does not save this: the
`python3 ... || true`-shaped construct is designed to swallow the
python-side exception before bash's `set -e` ever sees a non-zero code.

## Finding 2 — `./`-prefix / absolute-path bypass is plausible, unverified in this repo's own fixtures

All five gates match `file_path` with a bash `case` glob pair,
e.g. `*/docs/issue-*/proposals/*.md|docs/issue-*/proposals/*.md`. This
particular two-branch form does cover a same-directory relative path and a
`something/docs/...` shape (which a `./docs/...`-prefixed path also
satisfies, since `./` supplies the required `/` before `docs`), but it is
five independent hand-rolled copies of the same glob-matching idea, with no
shared normalization and no test coverage proving the absolute-path and
`./`-prefixed cases actually match (Finding 5). This is the class of bug
`gate-lib.py`'s `gate_normalize_path` exists to close for good, per
`docs/handbooks/gate-house-standard.md` items 3/5: "절대경로 정규화" and
"Absolute `file_path` matching the same scope a relative-path fixture
already matches, plus a `./`-prefixed variant" as a mandatory test case
group.

## Finding 3 — Edit/MultiEdit reconstruction ignores `replace_all` in one gate, is otherwise ad hoc

`capacity-fields-gate.sh:47-64` (Edit/MultiEdit reconstruction) does honor
`replace_all` per-edit already, so it is not itself broken on this axis.
But it is a sixth independent hand-rolled reimplementation of exactly what
`gate_lib.gate_reconstruct_write` (core issue-72) now provides canonically
— the other four gates (`forecast-method-gate.sh:41-66`,
`threshold-gate.sh:46-71`, `headroom-gate.sh:42-67`,
`citation-gate.sh:45-70`) reconstruct Write/Edit/MultiEdit the same way,
also honoring `replace_all` correctly, but as five more independent
copies. None reconstruct `NotebookEdit` — a `NotebookEdit` call falls
into the `else: print(read_existing())` branch in every gate, silently
checking the pre-edit content instead of the edit's actual result. This
matches the issue's "Edit/MultiEdit/replace_all 완전 재구성" requirement:
the individual replace_all bug is largely already fixed per-gate, but the
NotebookEdit gap and the five-way duplication are exactly what
`gate_reconstruct_write` (`docs/handbooks/gate-house-standard.md`, "What
gate-lib.sh/gate-lib.py provide") exists to close in one place.

## Finding 4 — semantic checks are whole-document substring greps, not section/adjacency checks

- `capacity-fields-gate.sh:88-97`: once the "Expansion trigger thresholds"
  heading is confirmed present, the `growth_rate`/`lead_time`/
  `safety_buffer`/percentile checks (lines 89-96) grep the **entire**
  `$content`, not the text under that heading. A document that mentions
  `growth_rate` once in an unrelated paragraph and never actually
  decomposes the threshold under its own heading still passes.
- `threshold-gate.sh:104-107` has the identical whole-document-grep
  pattern for the same four terms.
- `citation-gate.sh:83,96-97` greps the whole document for
  `survey\.md`/`scout-brief\.md` with no adjacency to a References/Basis
  section — a stray mention anywhere (e.g. inside a "what we are NOT
  doing" aside) satisfies the citation check.
- `headroom-gate.sh:85-96` is the one partial exception already in this
  repo: its band-not-snapshot and cost-attribution checks use a bounded
  `{0,120}`-character adjacency window between the two required terms
  (`(threshold|growth_rate|...).{0,120}(cost|비용)|...`), not a bare
  whole-document substring test. It is evidence a section/adjacency
  approach is already precedented in this codebase, not a green-field
  invention.
- `forecast-method-gate.sh:99-106`'s "Check 2" length gate
  (`nonspace_len -lt 200`) is a document-length proxy for "not a bare
  keyword," not a structural check — it does not confirm the ≥40-char
  justification the comment claims actually follows the method mention;
  a long document with a keyword and unrelated 200+ chars elsewhere still
  passes.

This is the issue body's "문서 전역 grep이 proposal의 인접성 의미론과
모순" finding, confirmed per-gate with line numbers; `headroom-gate.sh`'s
existing adjacency-window technique is the pattern to generalize, not a
new one to invent.

## Finding 5 — test coverage gap

`tests/run-gate-tests.sh` covers `forecast-method-gate.sh`,
`threshold-gate.sh`, `headroom-gate.sh`, and `citation-gate.sh` — 4 of the
5 gates. `capacity-fields-gate.sh` has **zero** test cases anywhere in the
repo. Across all 24 existing `run` cases, none exercise: `Edit` with
`replace_all: true`, `MultiEdit` with mixed `replace_all` edits, malformed
JSON (truncated/non-object/empty), a kill-switch set to an unrecognized
value, an absolute `file_path`, a `./`-prefixed `file_path`, or a
`Bash`-tool file write. This is a strict subset of core's own
`gate-house-standard.md` six-case mandatory group (items 1-6) — none of
the six are present today.

## Finding 6 — README ghost files

`README.md:25-27` (Layout section) lists
`capacity-planning/hooks/record-fields-gate.sh`,
`capacity-planning/hooks/trailer-gate.sh`, and
`capacity-planning/hooks/handbook-trigger-gate.sh` as files in this repo.
`find capacity-planning -type f` shows none of the three exist —
issue-2's approved switch (`docs/issue-2/proposals/core-canon-reference-switch.md`,
merged) deleted all three vendored copies in favor of core's own
`core/hooks/hooks.json` firing them globally keyed off `CLAUDE_ROLE`.
README.md was never updated after that switch landed. This is the issue
body's "README를 실물과 정합화(유령 파일 제거...)" finding.

## Upstream basis confirmed available for phase-2 adoption

`core/hooks/lib/gate-lib.sh` (90 lines) and `core/hooks/lib/gate-lib.py`
(152 lines), landed in `tokenmaxxxer/tokenmaxxxer-core` PR #74
(2026-08-01), provide exactly the five primitives this repo's gates need
and currently hand-roll: `gate_trap_fail_closed`, `gate_kill_switch_active`
(fixed unrecognized-value-stays-active convention), `gate_deny`/
`gate_allow` (stderr-only), `gate_parse_json_or_deny` +
`gate_normalize_path` (Python), and `gate_reconstruct_write` (Python,
covers `NotebookEdit`). `core/hooks/tests/run-gate-lib-tests.sh` (217
lines) is the six-case standard harness this repo's own test suite must
gain a parallel of. `core/hooks/tests/compliance-check.sh` is the
mechanical detector this repo should run clean before closing issue-10.
Per `docs/handbooks/gate-house-standard.md`'s "reference only, never copy"
rule (`canon-scripts.md`), phase 2 sources/imports these, it does not
vendor a local copy.
