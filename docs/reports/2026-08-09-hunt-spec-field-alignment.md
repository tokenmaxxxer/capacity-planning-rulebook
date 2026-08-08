---
proposal: docs/issue-16/proposals/spec-field-alignment.md
---

# Hunt record — spec-field-alignment

## after-proposal — stance 0: assume the gate/mechanism just touched is bypassable — find the bypass.

Verdict: NO FINDING
Seed: docs/issue-16/proposals/spec-field-alignment.md, docs/issue-16/reports/implementation/survey.md, docs/issue-16/reports/implementation/scout-brief.md (docs-only diff, phase-1 proposal)
cap_seconds: 60
tier: default
diff_stat_lines: docs-only, not measured (cap reached before full diff stat)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:01:00Z

Checked whether this rulebook's own gates (capacity-threshold-decomposition/hooks/threshold-gate.sh and siblings) read a frontmatter `kind:` field that a self-declared `kind: coding-record` on a capacity-planning record could collide with. threshold-gate.sh's `kind` variable is derived from file *path* (proposals/ vs reports/), not frontmatter, and takes values "proposal"/"record" only — never "coding-record". No collision found in this repo's own gate set within the time budget. Could not reach core/hooks/record-fields-gate.sh (outside this repo checkout) to verify the core-side claim before the cap expired; treating that as out of scope for a docs-only 60s dispatch.

## before-landing — stance: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — core's record-fields-gate.sh (role-agnostic, kind-based terminal-state resolution) and this rulebook's own capacity-fields-gate.sh (hardcoded literal-string terminal detection) disagree on what "terminal" means for a capacity-planning record, so the new Resource/Verdict field checks added in this diff never fire on an actually-landed record.
Kind: composition
Seed: `git diff 8305652 436dc05` — capacity-planning/hooks/capacity-fields-gate.sh (new Resource/Verdict subsection checks), capacity-planning/hooks/directive.sh (resource/verdict added to PRODUCES), README.md (states landed is the sole terminal state and cites core's KIND_TERMINAL_DEFAULTS for coding-record being exactly landed)
cap_seconds: 120
tier: default
diff_stat_lines: ~90 (5 files)
started_at: 2026-08-09T06:07:48+09:00
ended_at: 2026-08-09T06:35:00+09:00

### Reproduce
Core's `record-fields-gate.sh` (invoked globally on every Write/Edit via core's own `hooks.json` matcher `.*`, unconditionally alongside this role's `capacity-fields-gate.sh`) resolves the record's terminal `loop_state` via its per-kind terminal-defaults table, whose entry for kind `coding-record` is exactly the single value `landed` (role `capacity-planning` is unmapped in core's role-to-kind table, so it falls back to the record's own `kind: coding-record` frontmatter, exactly as this diff's README addition documents). So `loop_state: landed` is the one and only value that makes a capacity-planning record terminal in this system.

But `capacity-planning/hooks/capacity-fields-gate.sh` (this diff's new Resource/Verdict checks) — and its siblings `capacity-threshold-decomposition/hooks/threshold-gate.sh` and `capacity-headroom-costnote/hooks/headroom-gate.sh` — gate their own field-completeness enforcement behind a *different*, hardcoded terminal test: `grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'`. This literal-string test never matches `loop_state: landed`.

```
CLAUDE_PROJECT_DIR=/home/jwjung/.tokenmaxxxer/work/capacity-planning-rulebook-issue-16-implementation \
bash /home/jwjung/.tokenmaxxxer/work/capacity-planning-rulebook-issue-16-implementation/capacity-planning/hooks/capacity-fields-gate.sh <<'JSON'
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "docs/issue-16/reports/capacity-planning.md",
    "content": "---\nkind: coding-record\nloop_state: landed\n---\n\n## Capacity forecast\nsteady growth\n\n## Cost note\nsome cost\n"
  }
}
JSON
echo EXIT:$?
```

Contrast: the identical payload with `loop_state: terminal` (a value this role's actual vocabulary never uses) correctly denies with all three missing headings listed, proving the field-check logic itself is correct but gated on the wrong literal.

### Observed
`EXIT:0` (silent allow) for the `loop_state: landed` record, which is missing the "Resource" and "Verdict" subsection headings this exact diff just added as required fields, and is also missing "Expansion trigger thresholds" entirely. The gate produces no output and no denial — indistinguishable from a fully-compliant record.

Swapping only `loop_state: landed` to `loop_state: terminal` in the same payload (otherwise identical, still missing the same three headings) instead yields:
```
capacity-fields-gate: refused — terminal capacity-planning record fails issue-1 norm: - Resource subsection heading missing
- Expansion trigger thresholds subsection heading missing
- Verdict subsection heading missing
EXIT:2
```
confirming the check logic is present and correct, but reachable only when `loop_state` literally equals the word "terminal" — a value this role's own vocabulary (per this diff's README) never produces.

### Expected
A `loop_state: landed` capacity-planning record — the only shape core's record-fields-gate.sh recognizes as terminal for this role/kind — should also be checked by capacity-fields-gate.sh (and threshold-gate.sh/headroom-gate.sh) for the Resource/Verdict/threshold/headroom fields this diff and its siblings require, not silently pass unreviewed. The two gates' terminal-state vocabularies must agree, or the newly added Resource/Verdict enforcement is unreachable on any record that actually reaches the terminal state this rulebook's own README says is the only one that exists.
