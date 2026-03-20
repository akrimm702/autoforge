<div align="center">

# 🔨 AutoForge

### *Stop vibing. Start converging.*

**Production-grade autonomous optimization for AI agent skills, code, docs & entire repos.**

Mathematical convergence · Multi-model cross-validation · Regression guards · Live Unicode reporting

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-skill-brightgreen.svg)](https://openclaw.ai)
[![ClawHub](https://img.shields.io/badge/ClawHub-autoforge-8B5CF6.svg)](https://clawhub.com/skills/autoforge)

</div>

---

Most "self-improving agent" approaches boil down to *"reflect on your output."*
That's a vibe check, not optimization. AutoForge is different.

|  | Typical "Reflect" | AutoForge |
|---|---|---|
| **When to stop** | "Looks good to me" | 3× 100% pass, 5× retained, or 3× discard |
| **Progress** | Chat history | TSV with pass rates & diffs per iteration |
| **Validation** | Same model checks itself | Multi-model blind cross-validation |
| **Reporting** | Final summary | Live Unicode bars + dashboard after every iteration |
| **Regressions** | "Oops, broke something" | Regression guard with individual eval tracking |
| **Modes** | One generic loop | 7 specialized modes |
| **Patches** | Full rewrite per iteration | Incremental patches (max 30% per iter) |
| **Track record** | Demo | 50+ iterations across 6 production skills |

---

## 🏗️ Architecture

### Core Loop

```
                         ┌─────────────────────┐
                         │  Define target +     │
                         │  evals               │
                         └─────────┬───────────┘
                                   │
                                   ▼
                         ┌─────────────────────┐
                         │  Baseline scan       │
                         │  (Iteration 1)       │
                         └─────────┬───────────┘
                                   │
                    ┌──────────────┘
                    │
                    ▼
           ┌───────────────┐     proposed     ┌───────────────┐
       ┌──▶│   Optimizer   │────────────────▶│   Validator   │
       │   │  (Claude Opus)│                  │    (GPT-5)    │
       │   └───────────────┘                  └───────┬───────┘
       │                                              │
       │                              ┌───────────────┴───────────────┐
       │                              │                               │
       │                              ▼                               ▼
       │                     ┌─────────────┐                 ┌─────────────┐
       │                     │ ✅ improved  │                 │ ❌ discarded │
       │                     └──────┬──────┘                 └──────┬──────┘
       │                            │                               │
       │                            ▼                               ▼
       │                     ┌─────────────┐                ┌──────────────┐
       │                     │ Regression  │                │  Log finding │
       │                     │ Guard ✓     │                │  for retry   │
       │                     └──────┬──────┘                └──────────────┘
       │                            │
       │                            ▼
       │                   ┌─────────────────┐
       │                   │  Log to TSV     │
       │                   │  + report.sh    │
       │                   │  + findings.md  │
       │                   └──────┬──────────┘
       │                          │
       │                          ▼
       │                  ┌──────────────┐
       │       No         │  Converged?  │
       └─────────────────┤              │
                          └──────┬───────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
                 ▼               ▼               ▼
          ┌─────────────┐ ┌──────────────┐ ┌───────────┐
          │ 3× 100% ✅  │ │ 5× retained  │ │ 3× discard│
          │   Deploy!   │ │  Converged   │ │   Stop ⚠️  │
          └─────────────┘ └──────────────┘ └───────────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │  report --final  │
                        │  + summary.sh    │
                        │  + visualize.py  │
                        └──────────────────┘
```

### Multi-Model Validation

```
  Iter 1 (Optimizer)          Iter 2 (Validator)         Iter 3 (Optimizer)
  ─────────────────           ──────────────────         ─────────────────

  ┌──────────────┐            ┌──────────────┐           ┌──────────────┐
  │ Claude Opus  │            │    GPT-5     │           │ Claude Opus  │
  │              │            │              │           │              │
  │ Analyze      │            │ Blind review │           │ Fix findings │
  │ Find issues  │            │ of output    │           │ from GPT-5   │
  │ Write fixes  │            │ (no context) │           │              │
  └──────┬───────┘            └──────┬───────┘           └──────┬───────┘
         │                           │                          │
         ▼                           ▼                          ▼
  pass_rate: 62%              pass_rate: 78%              pass_rate: 95%
  status: improved            status: improved            status: improved

         └────── TSV ──────────────── TSV ──────────────── TSV ──────┘

  Different model validates → no "grading your own homework" blind spot
```

### Regression Guard

```
  Best state: evals A✅ B✅ C✅ D✅ E❌  (80%)

  New iteration:     A✅ B✅ C✅ D❌ E✅  (80%)
                                  ▲       ▲
                            was passing   now passing
                            now failing   was failing

  Total rate: same (80%)
  But D regressed! → status: regression → revert → log finding
```

### Findings Loop

```
  optimize ──▶ test ──▶ findings.md ──▶ optimize ──▶ test ──▶ ...

  Round 1: 3 findings (stale flag, wrong path, missing example)
  Round 2: 2 resolved, 1 new finding (edge case)
  Round 3: All resolved → clean convergence

  Safety: maxFindingsLoops (default: 3) prevents infinite cycles
```

### Project Mode — Three Phases

```
  Phase 1                    Phase 2                      Phase 3
  SCAN & PLAN                CROSS-FILE ANALYSIS          ITERATIVE FIX LOOP
  ─────────────              ───────────────────          ──────────────────

  ┌──────────────┐           ┌──────────────────┐         ┌──────────────┐
  │ Walk repo    │           │ README ↔ CLI     │    ┌───▶│ Surgical fix │
  │ tree         │           │ Dockerfile ↔ deps│    │    │ across files │
  │              │──────────▶│ CI ↔ scripts     │───▶│    └──────┬───────┘
  │ Build file   │           │ .env ↔ code refs │    │           │
  │ priority map │           │ imports ↔ reqs   │    │           ▼
  └──────────────┘           │ .gitignore ↔ out │    │    ┌──────────────┐
                             └──────────────────┘    │    │ Validate     │
                                                     │    │ consistency  │
                                                     │    └──────┬───────┘
                                                     │           │
                                                     │     Not   │  Done?
                                                     └─── yet ◀──┘
```

---

## 🚀 Quick Start

**Install**

```bash
# Via ClawHub
clawhub install autoforge

# Or clone
git clone https://github.com/akrimm702/autoforge.git
cp -r autoforge ~/.openclaw/workspace/skills/autoforge
```

**Configure reporting** *(optional)*

```bash
export AF_CHANNEL="telegram"        # telegram | discord | slack
export AF_CHAT_ID="-100XXXXXXXXXX"  # chat/group ID
export AF_TOPIC_ID="1234"           # thread ID (optional)
```

No env vars? Reports print to stdout with ANSI colors.

**Tell your agent**

```
Start autoforge mode: prompt for the coding-agent skill.
Evals: PTY handling correct? Workspace protection enforced? Clear structure?
```

The agent reads the skill, runs the loop, tracks everything in TSV, reports live, and stops when convergence math says it's done.

---

## 🔧 Seven Modes

### `prompt` — Mental Simulation

Simulates 5 realistic scenarios per iteration, evaluates Yes/No against defined evals, calculates pass rate mathematically. No code execution.

**Best for:** SKILL.md files, prompt engineering, documentation, briefing templates.

### `code` — Real Execution

Runs code in a sandbox, measures exit codes, stdout, stderr, runtime. Evaluates against concrete test criteria.

**Best for:** Shell scripts, Python tools, data pipelines, build systems.

### `audit` — CLI Testing

Tests documented commands against actual CLI behavior (`--help`, read-only). Catches docs-vs-reality drift. Two variants: Simple (2 iterations) or Deep (iterative with multi-model).

**Best for:** Verifying skill documentation matches real CLI behavior.

### `project` — Whole Repository ⭐

Scans an entire repo, builds a file-map with priorities, runs **cross-file consistency checks**, and iteratively fixes issues across multiple files.

**Best for:** README ↔ CLI drift, Dockerfile ↔ dependency mismatches, CI ↔ project structure gaps.

Cross-file checks include:
- README documents what the CLI actually does
- Dockerfile installs the right dependency versions
- CI workflows reference correct paths and scripts
- `.env.example` covers all env vars used in code
- Every import has a matching dependency declaration
- `.gitignore` excludes build artifacts and secrets

### `e2e` — End-to-End Testing 🆕

Live tests against **real tools and APIs** — not mocked, not simulated. All evals are `live` category (99%+ confidence weight).

**Best for:** Integration testing, API validation, webhook verification, deployment checks.

Safety: NEVER destructive commands without `--dry-run`, ALWAYS timeouts, max 10 API calls/iteration.

### `personal` — Agent Self-Improvement 🆕

Analyzes real session logs, memory files, and cron run history to find behavioral patterns — repeated mistakes, slow responses, user corrections, missing proactivity, style mismatches, tool misuse.

**Best for:** Improving agent behavior from real usage data.

⚠️ **READ ONLY** — findings are proposals, never auto-applied to SOUL.md or AGENTS.md.

---

## 📊 Live Reporting

After each iteration, `report.sh` sends live updates:

```
📊 AutoForge: coding-agent

📍 Iter 1   █████████░░░░░░░░░░░  45%  baseline
✅ Iter 2   ████████████░░░░░░░░  62%  improved
✅ Iter 3   ███████████████░░░░░  78%  improved
✅ Iter 4   █████████████████░░░  85%  improved
⚠️ Iter 5   ████████████████░░░░  82%  regression → reverted
✅ Iter 6   ██████████████████░░  90%  improved
✅ Iter 7   ██████████████████░░  92%  retained
✅ Iter 8   ███████████████████░  95%  improved
✅ Iter 9   ████████████████████  100% improved
✅ Iter 10  ████████████████████  100% improved

──────────────────────
Iterations: 10  ✅ Keep: 8  ❌ Discard: 0  ⚠️ Regression: 1  ➡️ Retained: 1
🏆 Best: 100% (Iter 9)  📈 Δ +55pp
🔍 Findings: 3 found, 3 resolved

✅ Loop converged — 2× 100% confirmed
```

### Dashboard mode (`--dashboard`)

```
📊 AutoForge Dashboard: coding-agent
═══════════════════════════════════

📈 Velocity:  5.5 pp/iter (strong)
⚡ Efficiency: 80% keep rate
🎯 Convergence: 95% confidence
⏱️  Runtime: 12m 34s (10 iterations)

🔬 Eval Breakdown:
  Structural (S): 100%  ████████████████████
  Simulated  (M):  95%  ███████████████████░
  Live       (L): 100%  ████████████████████

🔀 Validators: claude:100% / gpt:98%
```

### TSV format

Every iteration logged in machine-readable TSV:

```
iteration  summary              pass_rate  change              status      confidence    blast    validators
1          Baseline             45%        Original            baseline    S:45%/M:40%   -        -
2          Add subcommands      62%        16 commands added   improved    S:80%/M:50%   +16/-0   claude:62%
...
10         Final validation     100%       All checks green    improved    S:100%/M:100% +2/-0    claude:100%/gpt:98%
```

---

## 📐 Convergence Rules

No vibes. No "looks good." Mathematical stop conditions:

| Condition | Rule | Purpose |
|-----------|------|---------|
| ⬇️ Minimum iters | Must reach N before any stop | Prevents premature convergence |
| 🛑 Max 30 iters | Hard safety cap | Cost protection |
| ❌ 3× discard streak | Stop + analyze | Detects structural problems |
| ❌ 3× regression streak | Stop + analyze | Detects fundamental issues |
| ✅ 3× 100% pass | Confirmed perfect | After minimum reached |
| ➡️ 5× retained streak | Fully converged | No further improvement possible |

**Multi-model convergence:** When validators are configured, convergence requires ALL validators ≥ threshold. A single validator below threshold blocks convergence.

**Validator noise detection:** In multi-model setups, validators can produce false positives. AutoForge recognizes config/path confusion, inverted checks, normal English flagged as forbidden references, and over-counting. After all real fixes, if >3 discards stem from non-reproducible complaints → declare convergence.

---

## 🛡️ Regression Guard

Unlike simple pass-rate tracking, AutoForge tracks **every individual eval** across iterations:

1. After baseline, store all **individually passing evals** as the "guard set"
2. On each iteration, check ALL evals — not just total pass rate
3. If total rate improves BUT a guard eval now fails → `regression`
4. Revert to best state, log the regression as a **finding** for future iterations
5. Findings feed back into the loop — no information is lost

This catches the classic "fix one thing, break another" failure mode that total pass rate alone misses.

---

## 🔀 Multi-Model Cross-Validation

For complex audits, split optimizer and validator across different models:

| Role | Example Models | Task |
|------|---------------|------|
| **Optimizer** | Claude Opus, GPT-4.1 | Finds issues, writes fixes |
| **Validator** | GPT-5, Gemini | Checks against ground truth independently |

The validator doesn't see the optimizer's reasoning — just the output. This prevents the "same model validates its own work" blind spot.

### Confidence-Weighted Eval Categories

| Category | Confidence | Weight | When used |
|----------|-----------|--------|-----------|
| `structural` (S) | High (95%+) | 1.0× | Static analysis, format checks |
| `simulated` (M) | Medium (70-90%) | 1.5× | Mental simulation, hypothetical |
| `live` (L) | Highest (99%+) | 2.0× | Actually executed and measured |

**Weighted pass rate:** `Σ(passing × weight) / Σ(all × weight) × 100`

`prompt` = simulated · `code`/`e2e` = live · `audit`/`project` = mixed

---

## 🏆 Real-World Results

*Production runs, not demos.*

**coding-agent SKILL.md** — 553 lines rewritten across 10 iterations. 16 Codex subcommands + 40 Claude CLI flags documented. 45% → 100%. Discovered `--yolo` was never a real flag.

**ACP Router** — 90% → 100% in 9 iterations. Agent coverage doubled from 6 to 12 harnesses. Thread spawn recovery policy written from scratch.

**Sub-Agents Documentation** — 70% → 100% in 14 iterations with multi-model validation. 6 real bugs found in upstream docs. Identified 4 categories of validator false positives.

**backup.sh** — Added rsync support, validation checks, restore-test. Code mode with sandboxed test runs. 3 iterations to stable, 2 more to polish.

**AutoForge on itself 🤯** — Self-forged in project mode: 67% → 100% in 8 iterations. Fixed 2 script bugs, cleaned config/doc inconsistencies across 7 files.

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AF_CHANNEL` | `telegram` | Report delivery channel |
| `AF_CHAT_ID` | *(none)* | Chat/group ID. Unset = stdout |
| `AF_TOPIC_ID` | *(none)* | Thread/topic ID |

### V2 Config (in task prompt or JSON)

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

All config fields are optional. Without them, classic single-model mode.

### Execution Flags

| Flag | Behavior |
|------|----------|
| `--dry-run` *(default)* | Only TSV + proposed files. Target unchanged. |
| `--live` | Overwrites target. Auto-backup to `results/backups/`. |
| `--resume` | Continue from existing TSV. |

---

## 🗂️ Directory Structure

```
autoforge/
├── SKILL.md                ← OpenClaw skill definition (the brain)
├── README.md               ← You are here
├── LICENSE                 ← MIT
├── .gitignore
├── scripts/
│   ├── report.sh           ← Live reporting (dashboard, trends, JSON)
│   ├── summary.sh          ← Markdown summary generator
│   └── visualize.py        ← PNG progress charts + multi-run comparison
├── references/
│   ├── eval-examples.md    ← Pre-built evals by category
│   └── ml-mode.md          ← ML training integration guide
├── examples/
│   └── demo-config.json    ← Example run configurations
└── results/                ← Your run data (gitignored)
    └── .gitkeep
```

---

## 🤝 Contributing

1. Fork → feature branch → PR
2. Run `shellcheck scripts/report.sh` and `python3 -m py_compile scripts/visualize.py`
3. Include real-world results from your own runs if possible

**Good contributions:** new eval templates, additional channel support, bug fixes with repro steps, production run case studies.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built by [Alexander Krimm](https://github.com/akrimm702).

Battle-tested across **50+ iterations** on **6 production skills**.

*Stop reflecting. Start forging.* 🔨

</div>
