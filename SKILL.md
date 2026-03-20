---
name: autoforge
description: 'AutoForge — Production-grade autonomous optimization framework for AI agents. Replaces subjective reflection with mathematically rigorous convergence loops — tracking every iteration in TSV, cross-validating with multiple models, and stopping only when pass rates confirm real improvement. Seven modes: prompt (skill/doc optimization via scenario simulation), code (sandboxed test execution with measurable criteria), audit (CLI verification against live tool behavior), project (whole-repo cross-file consistency analysis), e2e (live end-to-end testing against real tools/APIs), personal (learns from session logs to improve agent behavior). Features: multi-model validation, regression guards, confidence-weighted evals, incremental patches, findings loops, session-log analysis. Battle-tested across 50+ iterations on production skills. Use when: user says "autoforge", "forge", "auto-research", "optimize skill", "improve", "run autoforge", "optimize code", "improve script", "optimize repo", "forge project", "check project", "repo audit", "skill verbessern", "optimiere", "loop laufen lassen", "code optimieren", "script verbessern".'
---

# AutoForge — Autonomous Optimization Framework

> Stop reflecting. Start converging. Every iteration is measured, logged, and validated — not vibed.

AutoForge replaces ad-hoc "improve this" prompts with a rigorous optimization loop: define evals, run iterations, track pass rates in TSV, report live to your channel, and stop only when math says you're done. Multi-model cross-validation prevents the "same model grades its own homework" blind spot.

## Modes

| Mode | What it does | Best for |
|------|-------------|----------|
| `prompt` | Simulate 5 scenarios/iter, evaluate Yes/No | SKILL.md, prompts, doc templates |
| `code` | Sandboxed test execution, measure exit/stdout/stderr | Shell scripts, Python tools, pipelines |
| `audit` | Test CLI commands live, verify SKILL.md matches reality | CLI skill documentation |
| `project` | Scan whole repo, cross-file consistency analysis | README↔CLI drift, Dockerfile↔deps, CI gaps |
| `e2e` | Live end-to-end tests against real tools/APIs | Integration testing, API validation |
| `personal` | Analyze session logs, improve agent behavior patterns | Self-improvement from real usage data |

---

## Architecture

```
Agent (you)
├── State: results.tsv, current target file state, iteration counter
├── Iteration 1: evaluate → improve → write TSV → report
├── Iteration 2: evaluate → improve → write TSV → report
├── ...
├── Findings: accumulated findings written to findings.md
├── Regression Guard: auto-compare against previous best
└── Finish: report.sh --final --dashboard → summary.sh → channel
```

### Sub-Agent = You
"Sub-Agent" is a **conceptual role**, not a separate process. You (the top-agent) execute each iteration yourself: simulate/execute → evaluate → write TSV → call report.sh. The templates below describe what you do PER ITERATION — not what you send to another agent.

For code/e2e modes, run tests using the `exec` tool.

### Multi-Model Validation

Split optimizer and validator across different models for blind cross-validation:

| Role | Model | Task |
|------|-------|------|
| **Optimizer** | Opus / GPT-5 | Analyzes, finds issues, writes fixes |
| **Validator** | Different model (Gemini, GPT, Claude) | Checks against ground truth, provides pass rate |

**Flow:** Spawn validators as sub-agents with `sessions_spawn` and explicit `model`. Validator gets ONLY the output — not the optimizer's reasoning. This prevents "grading your own homework."

**When to use:** Deep Audits (>5 iterations expected), complex ground truth, ambiguous evals.
**When single-model suffices:** Simple CLI audits, prompt optimization, code with clear pass/fail tests.

⚠️ **Validator Invariant:** If the task prompt specifies `Validators:`, they MUST be spawned. Skipping validators mid-run makes the run INVALID.

---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `AF_CHANNEL` | `telegram` | Messaging channel for reports |
| `AF_CHAT_ID` | `-1003799867890` | Chat/group ID for report delivery |
| `AF_TOPIC_ID` | `2211` | Thread/topic ID (🔧 Skill Optimizer) |

### V2 Config Fields (in task prompt or JSON)

```json
{
  "mode": "e2e",
  "target": "./my-skill/SKILL.md",
  "validators": ["anthropic/claude-sonnet-4", "openai/gpt-4.1"],
  "convergenceThreshold": 95,
  "regressionThreshold": 5,
  "maxFindingsLoops": 3,
  "evalCategories": true,
  "incrementalPatches": true
}
```

All config fields are optional. Without them, behavior is classic single-model mode.

---

## Hard Invariants

These rules apply **always**, regardless of mode. **Violations = broken run.**

1. **TSV is mandatory.** Every iteration writes exactly one row to `results/[target]-results.tsv`.
2. **Reporting is mandatory.** Call `report.sh` immediately after every TSV row.
3. **Never send manual messages instead of report.sh.** The script produces the standardized Unicode bar format.
4. **--dry-run never overwrites the target.** Only TSV, `*-proposed.md`, and reports are written.
5. **Mode isolation is strict.** Only execute steps for the assigned mode.
6. **Iteration 1 = Baseline.** Evaluate the original version unchanged, status `baseline`.
7. **Sub-agents follow the same rules.** When spawning sub-agents, they MUST write TSV and call report.sh.
8. **Regression Guard.** After every eval, compare individual eval results against the best state. If a previously passing eval now fails → `regression`, log finding, revert.
9. **Findings accumulate.** Write issues to `results/[target]-findings.md` as they emerge.
10. **Summary at end.** After `report.sh --final`, always run `summary.sh`.

---

## TSV Format

### Header (once at loop start):
```bash
printf '%s\t%s\t%s\t%s\t%s\n' "iteration" "prompt_version_summary" "pass_rate" "change_description" "status" > results/[target]-results.tsv
```

### Row per iteration:
```bash
printf '%s\t%s\t%s\t%s\t%s\n' "1" "Baseline" "58%" "Original version" "baseline" >> results/[target]-results.tsv
```

### 5 columns (v1) or 8 columns (v2-extended), TAB-separated:

| # | Column | Type | Rules |
|---|--------|------|-------|
| 1 | `iteration` | Integer | 1, 2, 3, ... |
| 2 | `prompt_version_summary` | String | Max 50 chars, no tabs/newlines |
| 3 | `pass_rate` | String | `58%`, `92%`, `100%` — always integer |
| 4 | `change_description` | String | Max 100 chars, no tabs/newlines |
| 5 | `status` | Enum | `baseline` · `improved` · `retained` · `discard` · `regression` |
| 6 | `confidence_breakdown` | String | `S:100%/M:85%/L:95%` or `-` (v2 only) |
| 7 | `blast_radius` | String | `+12/-3` or `-` (v2 only) |
| 8 | `validators` | String | `claude:94%/gpt:97%` or `-` (v2 only) |

> **Use `printf` not `echo -e`!** `echo -e` interprets backslashes. `printf '%s'` outputs literally.

### Status values:
- `baseline` — Iteration 1 only, evaluate original unchanged
- `improved` — Pass rate higher than previous best AND no regressions
- `retained` — Equal or marginally better
- `discard` — Lower pass rate → revert to best state
- `regression` — Pass rate may be higher BUT a previously passing eval now fails → revert + log finding

---

## Eval Categories

| Category | Confidence | Weight | Description |
|----------|-----------|--------|-------------|
| `structural` | High (95%+) | 1.0 | Static analysis, format checks |
| `simulated` | Medium (70-90%) | 1.5 | Mental simulation, hypothetical |
| `live` | Highest (99%+) | 2.0 | Actually executed and measured |

**Weighted pass rate:** `Σ(passing × weight) / Σ(all × weight) × 100`

Rules: `prompt` evals = simulated, `code`/`e2e` = live, `audit` = mixed, `project` = mixed.

---

## Incremental Patches

Instead of rewriting the entire target each iteration:

1. **Identify the specific failing evals** — don't touch what's passing
2. **Make the smallest change** that fixes the failing eval(s)
3. **Verify no regressions** — re-check previously passing evals
4. If patch causes regression → revert, log finding, try different approach
5. **Never rewrite >30% of target in one iteration**

In `change_description`, be specific:
- ✅ "Added --format flag docs (line 45-52)"
- ❌ "Improved overall quality" (too vague)

---

## Findings Loop

```
optimize → test → findings → optimize → test → ...
```

1. Normal loop runs until convergence
2. Any `discard`/`regression` creates a finding in `results/[target]-findings.md`
3. `improved` iterations reference which finding(s) they resolve
4. Unresolved findings go into summary report
5. Safety: `maxFindingsLoops` (default: 3) prevents infinite loops

---

## Regression Guard

1. After baseline, store the set of **individually passing evals** as the "guard set"
2. On each iteration, check ALL evals — not just total pass rate
3. If total rate improves BUT a guard eval now fails → `regression`
4. Revert to best state, log the regression as a finding

---

## Stop Conditions

Priority — first matching wins:

1. 🛑 **Minimum iterations** — If specified, must be reached first
2. 🛑 **Max 30 iterations** — Hard safety net
3. ❌ **3× `discard` in a row** → structural problem, stop
4. ❌ **3× `regression` in a row** → fundamental issue, stop
5. ✅ **3× 100% pass rate** (after minimum) → confirmed perfect
6. ➡️ **5× `retained` in a row** → converged

**Multi-Model Convergence:** When validators configured, convergence requires ALL validators ≥ `convergenceThreshold`. Single validator below threshold blocks convergence.

**Validator Noise:** After all real fixes, if >3 discards come in a row and fail justifications don't hold up → declare convergence.

---

## Reporting

### After EVERY TSV row:
```bash
bash scripts/report.sh results/[target]-results.tsv "[Skill Name]"
```

### After loop ends:
```bash
bash scripts/report.sh results/[target]-results.tsv "[Skill Name]" --final --dashboard
```

### Generate summary:
```bash
bash scripts/summary.sh results/[target]-results.tsv --output results/[target]-summary.md
```

### Generate visualization (optional):
```bash
python3 scripts/visualize.py results/[target]-results.tsv --title "[Name]" --output results/[target]-progress.png
```

### Multi-run comparison:
```bash
python3 scripts/visualize.py results/a.tsv results/b.tsv --compare --output comparison.png
```

Report features: Unicode progress bars, status icons, stats block, trend indicators, efficiency metrics, regression warnings, improvement tiers, dashboard mode, JSON output.

---

## Spawning Sub-Agents

When spawning via `sessions_spawn`, the TSV + report.sh workflow is **NON-NEGOTIABLE**:

```
sessions_spawn task:
"AutoForge [mode]: [target]

WORKING DIRECTORY: ~/.openclaw/workspace/skills/autoforge
TSV FILE: results/[target]-results.tsv
REPORT COMMAND: bash scripts/report.sh results/[target]-results.tsv "[Name]"
FINAL REPORT: bash scripts/report.sh results/[target]-results.tsv "[Name]" --final --dashboard
SUMMARY: bash scripts/summary.sh results/[target]-results.tsv --output results/[target]-summary.md

ENVIRONMENT:
  export AF_CHANNEL=telegram
  export AF_CHAT_ID=-1003799867890
  export AF_TOPIC_ID=2211

MODE: [prompt|code|audit|project|e2e|personal]
TARGET: [path]
EVALS: [list]

V2 CONFIG (optional):
  validators: [model1, model2]
  convergenceThreshold: 95
  regressionThreshold: 5
  evalCategories: true
  incrementalPatches: true
  maxFindingsLoops: 3

STOP CONDITIONS:
- Max 30 iterations
- 3× 100% pass rate → done
- 5× retained → converged
- 3× discard/regression in a row → stop

EXECUTION RULE: After EVERY tool result, immediately make the next call.
NEVER end a turn with 'I will now...' — just DO it."
```

---

## Modes — Read ONLY Your Mode

### mode: prompt
Per iteration: Read target → simulate 5 scenarios → eval Yes/No → pass rate → TSV + report.
At end: best version → `results/[target]-proposed.md`

### mode: code
Per iteration: `SCRATCH=$(mktemp -d)` → write code → execute with `timeout 60s` → measure exit/stdout/stderr → eval → TSV + report.
At end: best code → `results/[target]-proposed.[ext]`

### mode: audit
Two variants:
- **Simple** (2 iterations): Baseline → Proposed Fix. For tools with clear `--help`.
- **Deep** (iterative + multi-model): Full convergence loop. For extensive documentation.

⚠️ DO NOT write your own code — only test CLI commands (`--help` + read-only).

Fixed evals: Completeness (≥80% commands), Correctness (≥90% syntax), No stale refs, No missing core features, Workflow quality.

### mode: project
Three phases: Scan & Plan → Cross-File Analysis → Iterative Fix Loop.
Cross-file checks: README↔CLI, Dockerfile↔deps, CI↔structure, `.env.example`↔code, imports↔deps, tests↔source, `.gitignore`↔artifacts.
Multiple files can change per iteration (incremental patches, not rewrites).

### mode: e2e
Live end-to-end tests against **real tools/APIs** (not mocked). All evals are `live` category.
Safety: NEVER destructive commands without `--dry-run`, ALWAYS timeouts, max 10 API calls/iteration.
Eval types: api_responds, cli_works, integration, latency, idempotent, rollback, side_effects.

### mode: personal
Analyze real session logs to find behavioral patterns. Data: memory files, LCM history, cron runs.
Patterns: repeated mistakes, slow responses, user corrections, missing proactivity, style mismatches, tool misuse.
**READ ONLY** — findings are proposals, never auto-apply to SOUL.md/AGENTS.md.

---

## Execution Flags

| Flag | Behavior |
|------|----------|
| `--dry-run` (default) | Only TSV + proposed files |
| `--live` | Target overwritten, auto-backup → `results/backups/` |
| `--resume` | Continue from last TSV row |

---

## Directory Structure

```
autoforge/
├── SKILL.md                     ← This file
├── scripts/
│   ├── report.sh                ← Channel reporting (dashboard, trends, JSON)
│   ├── summary.sh               ← Summary report generator
│   └── visualize.py             ← PNG charts (trends, multi-run comparison)
├── references/
│   ├── eval-examples.md         ← Pre-built evals by category
│   └── ml-mode.md               ← ML training guide
├── examples/
│   └── demo-config.json         ← Example configurations
└── results/                     ← Generated during runs
```

---

## Examples

```
# Optimize a prompt/skill
"Start autoforge mode: prompt for coding-agent SKILL.md"

# Audit a CLI skill
"Start autoforge mode: audit for notebooklm-py"

# Deep audit with multi-model validation
"Start autoforge mode: audit (deep) for subagents docs.
 Validators: gpt-5, gemini. regressionThreshold: 3%"

# Optimize code
"Start autoforge mode: code for backup.sh.
 Test: bash backup.sh personal --dry-run"

# Whole-repo analysis
"Start autoforge mode: project for ./my-app"

# E2E integration testing
"Start autoforge mode: e2e for report.sh
 Test: send to Telegram, verify delivery"

# Personal behavior analysis
"Start autoforge mode: personal
 Focus: efficiency, proactivity, tool usage"

# With full v2 config
"Start autoforge mode: e2e for himalaya skill
 validators: [claude-sonnet, gpt-4.1]
 convergenceThreshold: 95
 evalCategories: true
 maxFindingsLoops: 2"
```

---

## Tips

- Always start with `--dry-run`
- Regression Guard catches "fix one, break another" — trust it
- Findings loop = knowledge accumulates across iterations
- Incremental patches > full rewrites — always
- Multi-model for deep audits: different models cover different blind spots
- TSV + report.sh + summary.sh are NOT optional — they ARE the user interface
- `--dashboard` gives velocity/efficiency metrics
- `--json` for programmatic consumption
- At >3 discards after all fixes: check for validator noise, declare convergence if justified
- For ML training: see `references/ml-mode.md`
- For ready-to-use evals: see `references/eval-examples.md`
