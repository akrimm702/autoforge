# AutoForge

> Autonomous optimization framework for AI agents. Stop reflecting — start converging.

AutoForge replaces ad-hoc "improve this" prompts with a rigorous optimization loop: define evals, run iterations, track pass rates in TSV, report live to your channel, and stop only when math confirms convergence. Multi-model cross-validation prevents the "same model grades its own homework" blind spot.

## Modes

| Mode | What it does |
|------|-------------|
| `prompt` | Scenario simulation for skill/doc optimization |
| `code` | Sandboxed test execution with measurable criteria |
| `audit` | CLI verification against live tool behavior |
| `project` | Whole-repo cross-file consistency analysis |
| `e2e` | Live end-to-end testing against real tools/APIs |
| `personal` | Session-log analysis for agent self-improvement |

## Features

- **Multi-Model Validation** — Optimizer and Validator run on different models for blind cross-validation
- **Regression Guards** — Individual eval tracking prevents "fix one thing, break another"
- **Confidence-Weighted Evals** — Structural (95%+), Simulated (70-90%), Live (99%+) categories
- **Incremental Patches** — Minimal surgical changes, never rewrite >30% per iteration
- **Findings Loop** — Issues accumulate and feed back into subsequent iterations
- **Live Reporting** — Unicode progress bars, dashboards, trend indicators via Telegram/Discord/Slack
- **Visualization** — PNG charts with matplotlib (ASCII fallback), multi-run comparison

## Quick Start

```
"Start autoforge mode: prompt for my-skill SKILL.md
 Evals: All flags documented? Examples runnable? Error handling covered?"
```

```
"Start autoforge mode: audit for weather skill"
```

```
"Start autoforge mode: code for backup.sh
 Test: bash backup.sh --dry-run
 Evals: exit_code==0, output file created, <10s runtime"
```

## How It Works

1. **Baseline** — Evaluate target unchanged, write TSV row #1
2. **Iterate** — Improve → evaluate → TSV → report → check stop conditions
3. **Guard** — Regression guard compares every eval against best state
4. **Converge** — 3× 100% or 5× retained in a row = done
5. **Report** — `report.sh --final --dashboard` + `summary.sh`

## Reporting

Every iteration writes to `results/[target]-results.tsv` and calls `report.sh` for live progress updates. Final runs generate markdown summaries and optional PNG visualizations.

```bash
bash scripts/report.sh results/my-skill-results.tsv "My Skill" --final --dashboard
bash scripts/summary.sh results/my-skill-results.tsv --output results/my-skill-summary.md
python3 scripts/visualize.py results/my-skill-results.tsv --title "My Skill" --output results/progress.png
```

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Max 30 iterations | Hard stop |
| 3× 100% pass rate | Confirmed perfect |
| 5× retained in a row | Converged |
| 3× discard in a row | Structural problem |
| 3× regression in a row | Fundamental issue |

## Install

```bash
clawhub install autoforge
```

## Requirements

- OpenClaw with `sessions_spawn` support
- Bash for report.sh/summary.sh
- Python 3 + matplotlib (optional, for PNG charts)

## License

MIT
