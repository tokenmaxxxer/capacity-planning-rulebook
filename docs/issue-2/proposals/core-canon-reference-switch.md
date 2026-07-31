# Proposal — switch to core canon references (issue-2)

Subject: issue-2. Phase 1 only: this document is the plan; no execution
happens until Approve. Basis: [survey.md](../reports/implementation/survey.md).

## Item 1 — remove the vendored warrant-hunter, reference core canon

- Delete `capacity-planning/agents/warrant-hunter.md`. It is not registered
  in `hooks.json`; deleting the file is the whole action.
- No replacement file is added to this repo. The role-agnostic hunt agent
  now lives at `warrant/agents/warrant-hunter.md` in core (core issue #63)
  and is available through the `warrant` plugin, independent of this
  rulebook's own plugin tree.
- Role-unique part preserved: this role's own hunt boundary — "향후 수요
  성장 대비 자원이 충분하며 언제 증설해야 하는가" / hand-off to
  performance-engineering — is not a warrant-hunter concern to begin with;
  it already lives in `directive.sh`'s `hand_off` text and in
  `.claude-plugin/plugin.json`'s description, both of which item 3 keeps.

## Item 2 — remove the three vendored role-agnostic gates and their registration

Delete `capacity-planning/hooks/trailer-gate.sh`,
`capacity-planning/hooks/record-fields-gate.sh`,
`capacity-planning/hooks/handbook-trigger-gate.sh`.

Rewrite `capacity-planning/hooks/hooks.json` to drop their `PreToolUse`
entries — core's own `core/hooks/hooks.json` fires all three globally,
keyed off `CLAUDE_ROLE`, for every plugin install (verified: core's file
registers `trailer-gate.sh` / `record-fields-gate.sh` /
`handbook-trigger-gate.sh` on matcher `.*`). Only the `SessionStart` entry
for this role's own `directive.sh` remains role-owned:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" }
        ]
      }
    ]
  }
}
```

Net effect on gate *behavior*, not just file count: `record-fields-gate.sh`
and `handbook-trigger-gate.sh` were both explicit placeholders in this repo
(unconditional pass-through; header comments say so). Switching to core's
canon versions makes both load-bearing for the first time — this is a
real tightening, not a no-op, and belongs in the record's "what was done"
once phase 2 executes it.

## Item 3 — rewrite directive.sh as a stub

Replace `capacity-planning/hooks/directive.sh` with:

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 향후 수요 성장 대비 자원이 충분하며 언제 증설해야 하는가" "USE WHEN: 용량 예측/증설 시점 결정이 걸릴 때" $'PRODUCES (required record fields): capacity forecast, expansion trigger thresholds, cost note\n\nWRITE_SCOPE: [] (report-only role \xe2\x80\x94 no code/doc write outside the record itself)' $'HAND-OFF: \xec\x84\xb1\xeb\x8a\xa5 \xec\x9e\x90\xec\xb2\xb4\xec\x9d\x98 \xeb\xb3\x91\xeb\xaa\xa9 \xec\x9b\x90\xec\x9d\xb8 \xeb\xb6\x84\xec\x84\x9d\xec\x9d\x80 \xe2\x86\x92 performance-engineering\n\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above, stop and hand off per the arrow \xe2\x80\x94 do not silently absorb another role\x27s scope. Record the hand-off point in this role\x27s record before opening the next role\x27s session.'
```

(The `\x..` escapes above are this document rendering the UTF-8/apostrophe
bytes literally inside `$'...'` quoting — the actual file will carry plain
Korean text and a plain `'`, written directly with the editor, not typed as
escapes.)

- Content dropped versus today: none. `you_decide`/`use_when` map straight
  across. `WRITE_SCOPE` and `BOUNDARY CASE`, which `core_role_directive`
  has no parameter for, are folded into the `produces` and `hand_off`
  strings respectively via `$'...\n\n...'` (a literal newline inside a
  single-quoted, single physical line).
- Verified directly against `core/hooks/tests/stub-check.sh`: a scratch
  file using this exact `$'...\n...'`-folding, single-physical-line form
  passes the check (`... is a role-directive stub`); the naive
  backslash-continued multi-argument form (one arg per line, as core's own
  header docstring shows as example usage) does **not** pass — each
  continuation line trips the "has non-stub line(s)" failure, because the
  checker is line-based, not call-based. This proposal's form is the one
  that actually clears the checker core issue-66 shipped, not the
  docstring's illustrative shape.
- The `RECORD:` line core_role_directive appends unconditionally already
  matches this role's own path (`docs/issue-<n>/reports/capacity-planning.md`
  — the function interpolates `${role}` from `CLAUDE_ROLE`), so nothing is
  lost there either.
- Kill switch changes name only in effect, not behavior:
  `CAPACITY_PLANNING_CYCLE_OFF` today is hand-checked; the stub relies on
  `core_role_directive`'s own `<ROLE>_CYCLE_OFF` derivation
  (`tr '[:lower:]-' '[:upper:]_'` on `CLAUDE_ROLE=capacity-planning`),
  which resolves to the identical env var name
  `CAPACITY_PLANNING_CYCLE_OFF`. No downstream reference to this variable
  exists elsewhere in this repo to update.

## Item 4 — RECORD_FIELDS_TERMINAL_STATES

No override proposed. This repo has no existing record
(`docs/issue-2/reports/implementation.md` does not exist pre-Approve) whose
`loop_state` usage diverges from core's default terminal set (`landed`),
and the role is report-only (`WRITE_SCOPE: []`), which does not by itself
imply extra non-default terminal states. If phase-2 execution surfaces an
actual capacity-planning-specific terminal `loop_state` (e.g. a
report-only equivalent of `scope-proposed`), set
`RECORD_FIELDS_TERMINAL_STATES` in this plugin's own `hooks.json` env at
that point — core's `record-fields-gate.sh` reads it per-invocation, so
this is a config addition, never a file fork. Flagging as an explicit
open item per the issue's own instruction ("역할별 실차이가 있으면
... 명시적 보존"), not silently assumed either way.

## Item 5 — stub-check.sh conformance

Once items 1–3 land (phase 2), run:

```
bash <core-checkout>/core/hooks/tests/stub-check.sh capacity-planning
```

against this rulebook's plugin root and record the pass/fail output
verbatim in `docs/issue-2/reports/implementation.md`. Pre-emptively
verified in this phase-1 pass, against a scratch copy of the exact
`directive.sh` content item 3 proposes (not against this repo's live
tree, since phase 1 makes no code changes): passes both the absence
checks (no vendored gate copies once item 2 lands) and the structural
directive.sh check.

## Ordering constraint carried over from the issue

This switch must land before this rulebook's own "룰북 성숙화" phase-2
issue. Not actionable inside issue-2's scope beyond noting it; the
approver should sequence accordingly.

## Not touched

`capacity-planning/.claude-plugin/plugin.json` — its description already
states this role's `you_decide`/`use_when`/hand-off; nothing in it
vendors core canon, so no change follows from this issue's five items.
