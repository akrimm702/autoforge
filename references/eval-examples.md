# Eval Examples by Skill Type (v2-Extended)

Ready-to-use Yes/No evals for immediate deployment in autoforge loops.
Includes v2 categories: `structural` (S), `simulated` (M), `live` (L).

> **Mode mapping:**
> - **prompt** → Briefing, Email, Calendar, Summary, Proposal
> - **code** → Python, Shell, API, Data Pipeline, Build, Docker, CI/CD
> - **audit** → API Documentation, Code Review
> - **project** → Repository, Cross-File, Security, Infrastructure
> - **e2e** → Agent Workflow, Tool-Call, Integration (NEW in v2)

---

## Briefing / Email Summary
- All configured sources queried? (S)
- Summary under 400 words? (S)
- Important senders correctly prioritized? (M)
- No hallucinated or fabricated content? (M)

## Proposal / Pitch Generator
- Formatting correct (headings, structure)? (S)
- ROI or concrete value proposition stated? (M)
- Tone professional and context-appropriate? (M)
- All relevant client information included? (M)

## Code Review
- All critical issues found? (M)
- Proposed fixes correct and actionable? (M)
- No false positives (correct code flagged as bug)? (M)

## Email Assistant
- Tone matches recipient (formal/informal)? (M)
- All asked questions answered? (M)
- No hallucinations or false facts? (M)
- Email ready to send without manual editing? (M)

## Calendar Briefing
- All day's appointments listed? (M)
- Time and location correct? (M)
- Relevant context included (participants, prep)? (M)

## Summary / TL;DR
- Core message in first 2 sentences? (S)
- No important points omitted? (M)
- Under 200 words? (S)

---

## CI/CD Pipeline
- All pipeline stages documented? (S)
- Environment variables listed with defaults? (S)
- Failure modes and rollback described? (M)
- Secret management explained (no hardcoded values)? (S)
- Deployment targets and regions specified? (S)

## Terraform / Infrastructure as Code
- All resources have lifecycle rules? (S)
- State backend configured and documented? (S)
- Variables have descriptions and types? (S)
- Outputs documented for downstream consumers? (S)
- Provider version constraints specified? (S)
- Drift detection strategy described? (M)

## Kubernetes Manifests
- Resource limits and requests set? (S)
- Health checks (liveness, readiness) configured? (S)
- Security context (non-root, read-only FS) applied? (S)
- Namespace isolation enforced? (S)
- HPA/scaling strategy documented? (M)
- Network policies defined? (S)

## API Documentation
- All endpoints listed with methods? (S)
- Request/response schemas provided? (S)
- Authentication requirements described? (S)
- Error codes and messages documented? (S)
- Rate limiting explained? (M)
- Versioning strategy described? (M)

## Database Migration
- Forward migration tested? (L)
- Rollback migration provided and tested? (L)
- Data loss risks documented? (M)
- Performance impact estimated? (M)
- Compatible with zero-downtime deployment? (M)

---

## Project / Repository

### GitHub Actions
- Workflow YAML syntactically valid? (S)
- Workflow references correct paths? (S)
- All secrets documented? (S)
- Matrix covers target platforms? (S)
- Caching configured? (S)
- Triggers match branching strategy? (S)

### Docker
- `docker build .` succeeds? (L)
- No secrets in image layers? (S)
- Image size within budget? (L)
- Multi-stage build used? (S)
- `.dockerignore` excludes artifacts? (S)
- Base image pinned? (S)
- Health check defined? (S)

### Python Repository
- `pytest` passes? (L)
- Type checking clean? (L)
- Linter clean? (L)
- All imports resolvable? (L)
- `requirements.txt` ↔ imports consistent? (S)
- Python version constraint specified? (S)

### Node.js Repository
- `npm test` passes? (L)
- `npm run lint` clean? (L)
- `package.json` ↔ imports consistent? (S)
- `package-lock.json` up to date? (L)
- `engines` field specifies Node version? (S)
- Scripts defined and functional? (L)

### Cross-File Consistency
- README commands match CLI `--help`? (L)
- Dependencies ↔ imports in sync? (S)
- `.env.example` covers all env vars? (S)
- Version strings consistent across files? (S)
- License present and referenced? (S)
- `.gitignore` excludes build outputs? (S)

### Security Baseline
- No hardcoded passwords/keys/tokens? (S)
- No `.env` committed? (S)
- No known critical CVEs? (L)
- HTTPS for all external URLs? (S)

---

## Code-Mode Evals

### Python Script
- Exit code 0? (L)
- All unit tests green? (L)
- No uncaught exceptions in stderr? (L)
- Runtime under limit? (L)
- Output is valid JSON? (L)

### Shell Script
- shellcheck clean? (L)
- bash syntax ok? (L)
- No hardcoded secrets? (S)
- Exit code 0 on normal run? (L)

### API / Web Service
- Health endpoint reachable? (L)
- Response is valid JSON? (L)
- Response time under limit? (L)
- No 5xx errors? (L)

### Data Pipeline
- Output file created? (L)
- Output not empty? (L)
- Row count plausible? (L)
- No duplicates? (L)

---

## e2e Evals (v2 NEW)

### Agent Spawn & Lifecycle
- Agent process starts without errors? (L)
- Agent responds to initial prompt? (L)
- Agent completes full task without premature stop? (L)
- Agent produces expected output files? (L)
- Agent exits cleanly (no hang, no crash)? (L)

### Tool-Call Validation
- `exec` commands return expected exit codes? (L)
- `read` tool reads correct file content? (L)
- `write` tool creates expected file? (L)
- `web_search` returns relevant results? (L)
- `browser` actions produce expected page state? (L)
- `sessions_spawn` creates sub-agent successfully? (L)

### Skill Integration
- Skill SKILL.md describes correct CLI flags? (L)
- Skill examples are executable and produce expected output? (L)
- Skill handles error cases gracefully? (L)
- Skill output matches documented format? (L)
- Skill doesn't break other skills (isolation test)? (L)

### Workflow Integration
- End-to-end workflow completes in sequence? (L)
- Intermediate artifacts are correct? (L)
- Final output matches acceptance criteria? (L)
- No orphaned processes after completion? (L)
- Cleanup happens (temp files removed)? (L)

### Agent Behavioral Evals
- Agent follows instructions from SKILL.md? (L)
- Agent doesn't hallucinate tool names? (L)
- Agent uses incremental approach (not full rewrite)? (L)
- Agent reports progress correctly? (L)
- Agent stops at convergence (not too early, not too late)? (L)

### Multi-Agent Coordination
- Sub-agents receive correct task prompts? (L)
- Sub-agents write to correct TSV path? (L)
- Sub-agents call report.sh after each iteration? (L)
- Parent agent correctly aggregates sub-agent results? (L)
- No race conditions on shared files? (L)

---

## Personal Improvement Evals (v2 NEW)

### Session Analysis
- Premature stop rate <10% of sessions? (L)
- Tool-call success rate >90%? (L)
- No repeated identical tool-call errors >3x? (L)
- Agent follows execution contracts? (L)
- Average task completion >85%? (L)

### Model-Specific Patterns
- GPT models don't summarize instead of executing? (L)
- Claude models don't refuse valid requests? (L)
- Model switches don't break ongoing tasks? (L)
- Token usage within expected bounds? (L)
