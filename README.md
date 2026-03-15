<![CDATA[<div align="center">

# 🔨 AutoForge

### _Stop vibing. Start converging._

**Autonomous optimization loops for AI agent skills, code, docs & entire repos.**<br>
Mathematical convergence · Multi-model cross-validation · Live Unicode reporting

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-skill-brightgreen.svg)](https://openclaw.ai)
[![ClawHub](https://img.shields.io/badge/ClawHub-autoforge-8B5CF6.svg)](https://clawhub.com/skills/autoforge)

<br>

<img src="https://raw.githubusercontent.com/akrimm702/autoforge/main/.github/banner.svg" alt="AutoForge Banner" width="680">

<br>

**Most "self-improving agent" approaches boil down to _"reflect on your output."_**<br>
That's a vibe check, not optimization. AutoForge is different.

</div>

---

## Why AutoForge?

| | Typical "Reflect & Improve" | AutoForge |
|---|---|---|
| **When to stop** | "Looks good to me" 🤷 | 3× 100% pass rate, 5× retained streak, or 3× discard abort |
| **Progress** | Chat history | TSV with pass rates, diffs & status per iteration |
| **Validation** | Same model checks itself | Multi-model cross-validation (Optimizer ≠ Validator) |
| **Reporting** | Final summary | Live Unicode bars after **every** iteration |
| **Modes** | One generic loop | 4 specialized: prompt · code · audit · project |
| **Track record** | Demo | **50+ iterations across 6 production skills** |

---

## 🚀 Quick Start

### Install

```bash
# Via ClawHub (recommended)
clawhub install autoforge

# Or clone
git clone https://github.com/akrimm702/autoforge.git
cp -r autoforge ~/.openclaw/workspace/skills/autoforge
```

### Configure Reporting _(optional)_

```bash
export AF_CHANNEL="telegram"          # telegram | discord | slack
export AF_CHAT_ID="-100XXXXXXXXXX"    # your chat/group ID
export AF_TOPIC_ID="1234"             # thread ID (optional)
```

> No env vars? Reports print to stdout with ANSI colors. That's fine too.

### Tell Your Agent

```
Start autoforge mode: prompt for the coding-agent skill.
Evals: PTY handling correct? Workspace protection enforced? Clear structure?
```

That's it. The agent reads the skill, runs the loop, tracks everything in TSV, reports live, and stops when convergence math says it's done.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Top Agent (You)                     │
│                                                        │
│   ┌──────────┐    ┌──────────┐    ┌──────────────┐   │
│   │ Evaluate │───▶│ Improve  │───▶│ Compare Pass │   │
│   │ (Evals)  │    │ (Minimal)│    │ Rate + State │   │
│   └──────────┘    └──────────┘    └──────┬───────┘   │
│        ▲                                  │           │
│        │          ┌──────────┐            │           │
│        └──────────│  Stop?   │◀───────────┘           │
│                   └────┬─────┘                        │
│                        │                              │
│            ┌───────────▼───────────┐                  │
│            │  Write TSV → report  │                  │
│            │  → next or converge  │                  │
│            └───────────────────────┘                  │
└──────────────────────────────────────────────────────┘
              │                    │
         ┌────▼────┐          ┌────▼────┐
         │  TSV    │          │ Channel │
         │ Results │          │ Report  │
         └─────────┘          └─────────┘
```

In **multi-model mode**, the Optimizer (e.g. Claude Opus) and Validator (e.g. GPT-5) alternate — catching each other's blind spots.

---

## 🔧 Four Modes

### `prompt` — Mental Simulation
Simulates 5 realistic scenarios per iteration, evaluates Yes/No against defined evals, calculates pass rate mathematically. No code execution.

**Best for:** SKILL.md files, prompt engineering, documentation, briefing templates.

### `code` — Real Execution
Runs code in a sandbox, measures exit codes, stdout, stderr, runtime. Evaluates against concrete test criteria.

**Best for:** Shell scripts, Python tools, data pipelines, build systems.

### `audit` — CLI Testing
Tests documented commands against actual CLI behavior (`--help`, read-only execution). Catches docs-vs-reality drift.

**Best for:** Verifying skill documentation matches real CLI behavior. Two variants: Simple (2 iterations) or Deep (iterative with multi-model).

### `project` — Whole Repository ⭐ _NEW_
Scans an entire repo, builds a file-map with priorities, runs **cross-file consistency checks**, and iteratively fixes issues across multiple files.

**Best for:** README ↔ CLI drift, Dockerfile ↔ dependency mismatches, CI ↔ project structure gaps, whole-repo health checks.

**Cross-file checks include:**
- README documents what the CLI actually does
- Dockerfile installs the right dependency versions
- CI workflows reference correct paths and scripts
- `.env.example` covers all env vars used in code
- Every import has a matching dependency declaration
- `.gitignore` excludes build artifacts and secrets

---

## 📊 Live Reporting

After each iteration, `report.sh` sends live updates to your configured channel:

```
📊 AutoForge: coding-agent

📍 Iter 1   █████████░░░░░░░░░░░  45%
✅ Iter 2   ████████████░░░░░░░░  62%
✅ Iter 3   ███████████████░░░░░  78%
✅ Iter 4   █████████████████░░░  85%
✅ Iter 5   ██████████████████░░  90%
✅ Iter 6   ██████████████████░░  92%
✅ Iter 7   ██████████████████░░  92%
✅ Iter 8   ███████████████████░  95%
✅ Iter 9   ███████████████████░  95%
✅ Iter 10  ████████████████████  100%

──────────────────────
Iterations: 10  ✅ Keep: 10  ❌ Discard: 0
🏆 Best pass rate: 100% (Iter 10)

✅ Loop converged — improvement found
```

---

## 📐 Convergence Math

No vibes. No "looks good." Mathematical stop conditions:

| Condition | Rule | Purpose |
|-----------|------|---------|
| ⬇️ Minimum iters | Must reach N before any stop | Prevents premature convergence |
| 🛑 Max 30 iters | Hard safety cap | Cost protection |
| ❌ 3× discard streak | Stop + analyze | Detects structural problems |
| ✅ 3× 100% pass | Confirmed perfect | After minimum reached |
| ➡️ 5× retained streak | Fully converged | No further improvement possible |

### Validator Noise Detection

Multi-model validators can produce false positives. AutoForge recognizes:
- Config path vs. tool name confusion
- Inverted check logic
- Normal English flagged as forbidden reference
- Over-counting across categories

**Rule:** After all real fixes, if >3 discards stem from non-reproducible validator complaints → declare convergence.

---

## 🏆 Real-World Results

_Production runs, not demos._

### coding-agent SKILL.md
- **553 lines** rewritten across 10 iterations
- **16 Codex subcommands** + **40 Claude CLI flags** documented
- 45% → **100%** pass rate
- Discovered `--yolo` was never a real flag (correct: `--dangerously-bypass-approvals-and-sandbox`)

### ACP Router Skill
- 90% → **100%** in 9 iterations
- Agent coverage: **6 → 12 harnesses** (Cursor, Copilot, Kiro, Kilocode, Qwen, OpenClaw added)
- Thread spawn recovery policy written from scratch

### Sub-Agents Documentation
- 70% → **100%** in 14 iterations (multi-model validation)
- **6 real bugs found** in the upstream docs
- Identified 4 categories of validator false positives
- Demonstrated convergence detection when noise exceeded real issues

### backup.sh
- Added rsync support, validation checks, restore-test
- Code mode with real execution: each iteration ran `backup.sh --dry-run`
- 3 iterations to stable, 2 more to polish

### AutoForge on Itself 🤯
- **Self-forged in project mode:** 67% → **100%** in 8 iterations
- Fixed 2 script bugs (JSON booleans in report.sh, filename prefix in visualize.py)
- Cleaned config/doc inconsistencies across 7 files
- Proof that the loop works recursively

---

## 🔀 Multi-Model Cross-Validation

For complex audits, split optimizer and validator across different models:

| Role | Example Models | Task |
|------|---------------|------|
| **Optimizer** | Claude Opus, GPT-4.1 | Finds issues, writes fixes |
| **Validator** | GPT-5, Gemini | Checks against ground truth independently |

This prevents the "same model validates its own work" blind spot. The validator doesn't see the optimizer's reasoning — just the output.

---

## 📋 TSV Tracking

Every iteration logs exactly one row:

```tsv
iteration	prompt_version_summary	pass_rate	change_description	status
1	Baseline	45%	Original SKILL.md baseline	baseline
2	Add missing subcommands	62%	16 Codex subcommands added	improved
3	Fix approval flags	78%	Scoped flags by context	improved
...
10	Validation pass	100%	All checks green	improved
```

5 columns, tab-separated. Status is one of: `baseline` · `improved` · `retained` · `discard`.

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AF_CHANNEL` | `telegram` | Report delivery channel |
| `AF_CHAT_ID` | _(none)_ | Chat/group ID. Unset = stdout |
| `AF_TOPIC_ID` | _(none)_ | Thread/topic ID |

### Execution Flags

| Flag | Behavior |
|------|----------|
| `--dry-run` _(default)_ | Only TSV + proposed files. Target unchanged. |
| `--live` | Overwrites target. Auto-backup to `results/backups/`. |
| `--resume` | Continue from existing TSV. Aborts on format errors. |

> **Note:** AutoForge is configured entirely via environment variables. The `example-config.json` is a reference template only — no script reads it at runtime.

---

## 🗂️ Directory Structure

```
autoforge/
├── SKILL.md                ← OpenClaw skill definition (the brain)
├── README.md               ← You are here
├── LICENSE                 ← MIT
├── .gitignore
├── scripts/
│   ├── report.sh           ← Live reporting (channel or stdout)
│   └── visualize.py        ← PNG progress chart generator
├── references/
│   ├── eval-examples.md    ← 200+ pre-built evals by category
│   └── ml-mode.md          ← ML training integration guide
├── examples/
│   ├── demo-results.tsv    ← Sample iteration data
│   └── example-config.json ← Reference template (not read at runtime)
└── results/                ← Your run data (gitignored)
    └── .gitkeep
```

---

## 🤝 Contributing

1. Fork → feature branch → PR
2. Run `shellcheck scripts/report.sh` and `python3 -m py_compile scripts/visualize.py`
3. Include **real-world results** from your own runs if possible

**Good contributions:**
- New eval templates in `references/eval-examples.md`
- Additional channel support in `report.sh`
- Bug fixes with reproduction steps
- Production run results & case studies

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built by [Alexander Krimm](https://github.com/akrimm702).<br>
Battle-tested across **50+ iterations** on **6 production skills**.

_Stop reflecting. Start forging._ 🔨

</div>
]]>