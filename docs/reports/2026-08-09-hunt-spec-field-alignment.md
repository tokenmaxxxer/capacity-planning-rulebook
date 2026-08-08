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
