# lens-work v2 — Concrete Architecture Proposal

**Author:** CrisWeber + BMad Brainstorming Session  
**Date:** 2026-03-08  
**Status:** PROPOSAL  
**Context:** Ground-up rebuild of `lens-work` based on v1 lessons learned  
**Input:** Brainstorming session 2026-03-08-001 (Five Whys, Morphological Analysis, First Principles, Assumption Reversal)

---

## 0. Design Axioms (Non-Negotiable)

These axioms are derived directly from v1 failures. Every design decision below must satisfy all of them, or be rejected.

| Axiom | Source |
|-------|--------|
| **A1: Git is the only source of truth for shared workflow state.** No git-ignored runtime state. Branch-traveling state is committed; machine-local secrets stay in provider or OS credential stores. | v1 `state.yaml` failure — staleness was systemic |
| **A2: PRs are the only gating mechanism.** Review, approval, promotion, and compliance happen through PRs. No side-channel approval, and required PRs are created automatically by the lifecycle workflows once prerequisites pass. | v1 PR-as-PBR was the primary validated success |
| **A3: Authority domains must be explicit.** Every file must belong to exactly one authority. Cross-authority writes are forbidden. | v1 drift between governance/initiative/personal zones |
| **A4: Sensing must be automatic.** Cross-initiative awareness must happen at lifecycle gates, not through manual discovery commands. | v1 discovery was manual and never exercised |
| **A5: The control repo is an operational workspace.** It's not a code repo. It contains release payloads, governance clones, output, docs, and the `.github` adapter layer. | Real-world usage pattern |

---

## 1. Authority Domains — Boundaries, Runtime, and Data Flow

### 1.1 The Four Domains

lens-work v2 operates across four authority domains. Each has an owner, a write surface, and explicit rules about what can read from or write to it.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CONTROL REPO (Operational Workspace)            │
│                                                                     │
│  D:\weberbot.bmad                                                   │
│  ├── .github/                 ← DOMAIN 3: Copilot Adapter          │
│  ├── bmad.lens.release/       ← DOMAIN 2: Release Module           │
│  ├── TargetProjects/                                                │
│  │   └── lens/                                                      │
│  │       └── lens-governance/ ← DOMAIN 4: Governance (cloned)       │
│  ├── Docs/                    ← Canonical documentation output      │
│  └── _bmad-output/            ← DOMAIN 1: Working state/artifacts   │
│      └── lens-work/                                                 │
│          └── initiatives/     ← Initiative branches (committed)     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 Domain Contracts

#### Domain 1: Control Repo / Operational Workspace

- **Authority:** The user's working environment.
- **Physical location:** The umbrella repo root (e.g., `D:\weberbot.bmad`).
- **Contains:** `.github/`, `bmad.lens.release/`, `TargetProjects/`, `Docs/`, `_bmad-output/`.
- **Branching:** The control repo has its own git history. Initiative branches live here. `_bmad-output/lens-work/initiatives/` is where all initiative artifacts are committed.
- **Write authority:** `@lens` agent writes initiative artifacts here. Governance clone is read-only from this repo's perspective.
- **Key v2 change:** `_bmad-output/lens-work/initiatives/` is now committed, not git-ignored. This is the foundation of git-derived state.

#### Domain 2: Release Repo / Module Payload

- **Authority:** The BMAD framework authors (you, as module builder).
- **Physical location:** `bmad.lens.release/` (a pinned submodule or pinned clone).
- **Contains:** `_bmad/lens-work/` — the module definition: `lifecycle.yaml`, agent, skills, workflows, prompts. Also `_bmad/core/`, `_bmad/bmm/`, etc.
- **Branching:** Follows release cadence (semver tags). Not involved in initiative branching.
- **Write authority:** Module builder only. `@lens` never writes here during initiative work. The release repo is a read-only dependency at runtime and is updated through an explicit self-service flow, not background mutation.
- **Key v2 change:** No JS libs, no `impl-*` prompts, no `state-management` skill. Dramatically smaller surface.

#### Domain 3: Copilot Adapter / `.github` Runtime Layer

- **Authority:** The control repo owner (user).
- **Physical location:** `.github/` at the control repo root.
- **Contains:** `copilot-instructions.md`, agent definitions (`.agents/`), skill wrappers, prompt launchers. This is the adapter that wires BMAD module capabilities into the IDE.
- **Branching:** Same as control repo. Changes here are typically mainline.
- **Write authority:** User or module installer. `@lens` does not modify `.github/` during initiative work.
- **Key v2 change:** Adapter layer references module skills/workflows by path, does not duplicate them. Thin adapter, not a copy.

#### Domain 4: Governance Repo

- **Authority:** Org/domain leads — the constitution authors.
- **Physical location:** Cloned into `TargetProjects/lens/lens-governance/` (or configurable path).
- **Contains:** `constitutions/` (4 levels: org, domain, service, repo), `roster/`, `policies/`, `repo-inventory.yaml`.
- **Branching:** Own repo with own branches. Constitutional changes happen via PRs in this repo, not in the control repo.
- **Write authority:** Governance leads only. `@lens` reads governance but never writes to it during initiative work. The one exception: `@lens` can propose a governance PR (e.g., requesting a new track permission), but cannot merge it.
- **Key v2 change:** Governance repo is a hard prerequisite. `@lens` verifies its clone at session start. No governance = no lifecycle.

### 1.3 Authority Violation Rules

These are **hard errors**, not warnings:

| Violation | Result |
|-----------|--------|
| Write initiative data to `bmad.lens.release/` | BLOCK — release repo is read-only at runtime |
| Write governance data to `_bmad-output/` | BLOCK — governance lives in its own repo |
| Write initiative data to governance repo | BLOCK — initiative artifacts stay in control repo |
| Merge governance changes in control repo | BLOCK — constitutional changes require governance repo PRs |
| Run lifecycle without governance clone | BLOCK — clone governance first |

### 1.4 Runtime Data Flow

```
                    ┌──────────────────────┐
                    │   User says /preplan │
                    └──────┬───────────────┘
                           │
                    ┌──────▼───────────────┐
                    │  .github adapter      │  ← Domain 3: routes to @lens
                    │  resolves /preplan    │
                    └──────┬───────────────┘
                           │
                    ┌──────▼───────────────┐
                    │  @lens (phase router) │  ← Domain 2: lifecycle.yaml
                    │  loads lifecycle.yaml  │     determines phase, agent,
                    │  reads branch state   │     artifacts, gates
                    └──────┬───────────────┘
                           │
              ┌────────────┼────────────────┐
              │            │                │
    ┌─────────▼──┐  ┌──────▼─────┐  ┌───────▼───────┐
   │ git query  │  │ governance │  │ initiative    │
   │ branches,  │  │ repo read  │  │ dir read      │
   │ PR meta,   │  │ (Domain 4) │  │ (Domain 1)    │
   │ HEAD       │  │            │  │               │
    │            │  │            │  │               │
    │ derive:    │  │ resolve:   │  │ check:        │
    │ - phase    │  │ - const.   │  │ - artifacts   │
    │ - audience │  │ - gates    │  │ - configs     │
    │ - status   │  │ - tracks   │  │ - history     │
    └────────────┘  └────────────┘  └───────────────┘
              │            │                │
              └────────────┼────────────────┘
                           │
                    ┌──────▼───────────────┐
                    │  Execute phase work   │
                    │  Delegate to agent    │
                    │  Write artifacts to   │
                    │  initiative branch    │
                    │  (Domain 1)           │
                    └──────┬───────────────┘
                           │
                    ┌──────▼───────────────┐
                    │  commit + push        │
                    │  (reviewable bundle)  │
                    └──────────────────────┘
```

---

## 2. How the Four Domains Interact

### 2.1 Interaction Matrix

| From ↓ / To → | Control (1) | Release (2) | Copilot (3) | Governance (4) |
|----------------|-------------|-------------|-------------|----------------|
| **Control (1)** | Initiative branching, artifact commits | Read lifecycle.yaml, skills, workflows | — | — |
| **Release (2)** | — | Self-contained module | — | — |
| **Copilot (3)** | Session routing → @lens | Skill/workflow path references | Self-contained adapter | — |
| **Governance (4)** | — | — | — | Constitution PRs |
| **@lens reads** | Branch state, initiative configs, artifacts | Lifecycle contract, skills | — | Constitutions, roster, policies |
| **@lens writes** | Initiative artifacts (committed) | NEVER | NEVER | Propose PR only |

### 2.2 Cross-Domain Interactions at Each Lifecycle Gate

| Gate | Domains Involved | What Happens |
|------|-----------------|--------------|
| `/new-*` (init) | 1 + 2 + 4 | Read lifecycle.yaml (2) for track/phase/audience rules. Read governance (4) for permitted tracks. Create branches in control repo (1). Commit initiative config (1). |
| Phase start | 1 + 2 | Read lifecycle.yaml (2) for phase definition. Create phase branch in control repo (1). |
| Phase end (PR) | 1 + 4 | Create PR in control repo (1) from phase branch → audience branch. Constitution check (4) at PR gate. |
| Audience promotion | 1 + 4 | Create PR in control repo (1) from audience → next audience. Governance gate check (4). Cross-initiative sensing scan (1 — read all active initiative branches). |
| `/switch` | 1 | Pure git operation — checkout a different initiative branch in control repo (1). Read committed initiative config from that branch. |
| `/status` | 1 + 2 | Read branches + PRs (1) to derive state. Map against lifecycle.yaml (2) to interpret. |
| Constitution amend | 4 | PR in governance repo only. Propagation to active initiatives is read-side (re-resolve on next gate). |

---

## 3. Minimum File / Folder / Config Set for v2

### 3.1 Module Structure (Domain 2 — `bmad.lens.release/_bmad/lens-work/`)

```
lens-work/
├── README.md                      # Module overview
├── lifecycle.yaml                 # THE contract — phases, audiences, tracks, branches, constitution schema
├── module.yaml                    # Module identity, dependencies, skills, workflow manifest
├── module-help.csv                # Help entries
│
├── agents/
│   ├── lens.agent.yaml            # Unified @lens agent — phase router + skill delegation
│   └── constitution.md            # Lex persona — constitutional governance voice
│
├── skills/
│   ├── git-orchestration.md       # Branch creation, commits, pushes, PR management
│   ├── git-state.md               # NEW: state queries from git topology + PR metadata
│   ├── constitution.md            # Constitution resolution, compliance, gates
│   ├── sensing.md                 # NEW: Cross-initiative overlap detection (replaces discovery sprawl)
│   └── checklist.md               # Phase gate checklists
│
├── workflows/
│   ├── core/
│   │   ├── phase-lifecycle/       # Phase start, phase end, phase-to-audience PR
│   │   └── audience-promotion/    # Audience→audience PR with gate + sensing
│   ├── router/
│   │   ├── init-initiative/       # /new-domain, /new-service, /new-feature
│   │   ├── preplan/               # /preplan
│   │   ├── businessplan/          # /businessplan
│   │   ├── techplan/              # /techplan
│   │   ├── devproposal/           # /devproposal
│   │   ├── sprintplan/            # /sprintplan
│   │   └── dev/                   # /dev
│   ├── utility/
│   │   ├── onboard/               # /onboard — profile, auth health, governance bootstrap
│   │   ├── status/                # /status — git-derived state report
│   │   ├── next/                  # /next — what should I do next
│   │   ├── switch/                # /switch — checkout to different initiative
│   │   └── help/                  # /help
│   ├── governance/
│   │   ├── compliance-check/      # Run constitution against current artifacts
│   │   ├── resolve-constitution/  # 4-level hierarchy resolution
│   │   └── cross-initiative/      # Cross-initiative sensing at gates
│   └── includes/
│       ├── pr-links.md            # PR URL construction helpers
│       ├── artifact-validator.md  # Artifact presence/quality checks
│       └── size-topology.md       # Audience → branch mapping
│
├── prompts/
│   ├── lens-work.new-initiative.prompt.md
│   ├── lens-work.preplan.prompt.md
│   ├── lens-work.businessplan.prompt.md
│   ├── lens-work.techplan.prompt.md
│   ├── lens-work.devproposal.prompt.md
│   ├── lens-work.sprintplan.prompt.md
│   ├── lens-work.status.prompt.md
│   ├── lens-work.next.prompt.md
│   ├── lens-work.switch.prompt.md
│   ├── lens-work.promote.prompt.md
│   ├── lens-work.constitution.prompt.md
│   ├── lens-work.onboard.prompt.md
│   └── lens-work.help.prompt.md
│
├── docs/
│   └── lifecycle-reference.md     # Human-readable lifecycle guide
└── tests/
   └── contracts/                 # Slim contract tests for branch parsing, provider adapters, sensing, governance
```

**v1 → v2 delta:**
- **DROPPED:** `lib/` (33 JS files), the heavy JS test layer (34 files), `scripts/`, `package.json`, `bmadconfig.yaml`, 28 `impl-*` prompts, `state-management.md` skill, `discovery.md` skill (replaced by `sensing.md`), `visual-documentation.md` skill, `phase-completion.md` skill (merged into `phase-lifecycle` workflow).
- **DROPPED workflows:** `fix-state/`, `migrate-state/`, `migrate-lifecycle/`, `recreate-branches/`, `setup-rollback/`, `fix-story/`, `batch-process/`, `bootstrap/`, `override/`, `resume/`, `adjust/`, `check-repos/`, `manage-credentials/`, `context/`, `sync-and-select-branch/`, all 10 `discovery/` workflows, `event-log/`, `state-sync/`.
- **ADDED:** `git-state.md` skill, `sensing.md` skill, `cross-initiative/` workflow, `/onboard` utility workflow, and a slim contract-test suite.
- **v1: ~60 workflows, 47 prompts, 7 skills. v2: ~16 workflows, 13 prompts, 5 skills, and a small contract-test surface.**

### 3.2 Control Repo Structure (Domain 1 — `_bmad-output/lens-work/`)

```
_bmad-output/
└── lens-work/
    ├── governance-setup.yaml      # Points to governance repo clone location
   ├── profile.yaml               # Committed, non-secret role/provider/preferences profile
    └── initiatives/
        └── {domain}/
            └── {service}/
                ├── {feature}.yaml         # Initiative config (committed, single source of truth)
                └── phases/
                    ├── preplan/
                    │   ├── product-brief.md
                    │   ├── research.md
                    │   └── brainstorm.md
                    ├── businessplan/
                    │   ├── prd.md
                    │   └── ux-design.md
                    ├── techplan/
                    │   └── architecture.md
                    ├── devproposal/
                    │   ├── epics.md
                    │   └── stories.md
                    └── sprintplan/
                        ├── sprint-status.yaml
                        └── stories/
                            └── {story-id}.md
```

**Critical difference from v1:** All of this is **committed to git**, not git-ignored. The initiative branch topology means each initiative's artifacts live on their own branches and are visible to `git branch --list`, `git log`, and PR state queries.

### 3.3 Governance Repo Structure (Domain 4)

```
lens-governance/
├── constitutions/
│   ├── org/
│   │   ├── constitution.md                # Universal org constitution
│   │   └── {language}/constitution.md     # Language-specific
│   ├── {domain}/
│   │   ├── constitution.md
│   │   └── {language}/constitution.md
│   ├── {domain}/{service}/
│   │   ├── constitution.md
│   │   └── {language}/constitution.md
│   └── {domain}/{service}/{repo}/
│       ├── constitution.md
│       └── {language}/constitution.md
├── roster/
│   └── team.yaml
├── policies/
│   └── *.md
└── repo-inventory.yaml
```

### 3.4 Copilot Adapter Structure (Domain 3 — `.github/`)

```
.github/
├── copilot-instructions.md        # References lens-work module
└── agents/
    └── lens.agent.md              # Thin wrapper → @lens agent in release module
```

The adapter is intentionally thin. It references, never duplicates.

---

## 4. Minimum Workflow Set for v2

### 4.0 Onboarding — `/onboard`

**Purpose:** Bootstrap a new control repo user without committing secrets.

**Steps:**
1. Detect the configured PR provider for this control repo (GitHub or Azure DevOps).
2. Validate provider authentication using existing CLI or device-flow sign-in. Secrets remain in the local credential store or provider login state; they are never written to git.
3. Verify or clone the governance repo to the configured path.
4. Create or update `_bmad-output/lens-work/profile.yaml` with non-secret user settings: role, domain, provider choice, batch preferences, and default target-project paths.
5. Bootstrap configured TargetProjects clones or verify their paths.
6. Run a health check covering provider auth, governance availability, and release-module version compatibility.
7. Report the next recommended command.

### 4.1 Init — `/new-domain`, `/new-service`, `/new-feature`

**Purpose:** Create an initiative with proper branch topology.

**Steps:**
1. User provides: domain, service (if applicable), feature name, track (full/feature/tech-change/hotfix/spike/quickdev).
2. Read `lifecycle.yaml` to determine which phases and audiences the track enables.
3. Read governance repo to verify track is permitted at this LENS level.
4. Derive `{initiative-root}` from naming convention: `{domain}-{service}-{feature}` or `{domain}-{feature}`.
5. Create initiative config YAML at `_bmad-output/lens-work/initiatives/{domain}/{service}/{feature}.yaml`:
   ```yaml
   initiative: {feature}
   domain: {domain}
   service: {service}                # optional
   track: full
   language: typescript              # auto-detected or specified
   created: 2026-03-08T10:00:00Z
   initiative_root: foo-bar-auth
   ```
6. Create branch: `{initiative-root}` from control repo default branch.
7. Create first audience branch: `{initiative-root}-small`.
8. **Do NOT pre-create medium/large/base audience branches.** (Lazy creation — see §8.)
9. Commit initiative config on `{initiative-root}` branch.
10. Push.

**Cross-initiative sensing trigger:** At step 3, before creating branches, run sensing (§7) to alert if another active initiative in the same domain/service exists.

### 4.2 Phase Routing — `/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`

**Purpose:** Start the named phase within the current initiative.

**Steps:**
1. Derive current initiative from branch name (git HEAD).
2. Query git-derived state (§5) to determine current phase and audience.
3. Validate: is this phase valid for the current track? Is the prior phase complete?
4. If phase requires a different audience (e.g., `/devproposal` requires medium): check if promotion PR was merged. If not, tell user to promote first.
5. Create phase branch: `{initiative-root}-{audience}-{phase}` from `{initiative-root}-{audience}`.
6. Checkout phase branch.
7. Delegate to the phase-owning agent (e.g., Mary for preplan, John for businessplan).
8. Agent executes sub-workflows, writes artifacts to `_bmad-output/lens-work/initiatives/{path}/phases/{phase}/`.
9. Save artifacts incrementally as drafts, but commit + push only when the phase bundle is reviewable or when the user explicitly requests a checkpoint.
10. When phase work is complete: automatically create PR from `{initiative-root}-{audience}-{phase}` → `{initiative-root}-{audience}`.
11. PR description includes: checklist of artifacts produced, constitution compliance result, phase gate status.

### 4.3 Promotion — `/promote`

**Purpose:** Promote from one audience level to the next.

**Steps:**
1. Derive current initiative and audience from branch name.
2. Determine next audience from `lifecycle.yaml` audience chain.
3. **Pre-promotion gate checks:**
   - All phase PRs for current audience are merged.
   - All required artifacts per `lifecycle.yaml` exist and pass validation.
   - Constitution compliance check passes (resolve full 4-level chain from governance repo).
   - Cross-initiative sensing check runs (§7).
4. **Lazy-create** the next audience branch if it doesn't exist: `{initiative-root}-{next-audience}` from `{initiative-root}-{current-audience}`.
5. Automatically create PR from `{initiative-root}-{current-audience}` → `{initiative-root}-{next-audience}`.
6. PR title: `[PROMOTE] {initiative} small→medium — Adversarial Review Gate`.
7. PR body includes: sensing results, constitution compliance, artifact summary, gate requirements.
8. Promotion is **not automatic.** The PR must be reviewed and merged according to the audience gate (adversarial-review, stakeholder-approval, or constitution-gate).

### 4.4 Status / Next — `/status`, `/next`

**Purpose:** Report current state and recommend next action.

**Steps (status):**
1. Derive initiative from branch name.
2. Query git-derived state (§5) to build status model.
3. Report: initiative, domain, service, track, current phase, current audience, completed phases, pending promotion, open PRs, artifact inventory.

**Steps (next):**
1. Run `/status` internally.
2. Apply lifecycle rules: if current phase is done and PR not created → suggest PR. If PR merged and next phase applicable → suggest next phase command. If audience complete → suggest `/promote`. If track complete → report done.

### 4.5 Constitution / Compliance — `/constitution`, `/compliance-check`

**Purpose:** Resolve and enforce governance rules.

**Steps (resolve):**
1. Load governance repo clone.
2. Resolve 4-level chain: org → domain → service → repo. Union all layers (additive inheritance).
3. Apply language-specific constitutions if initiative config declares a language.
4. Return resolved constitution (merged, with per-gate requirements).

**Steps (compliance-check):**
1. Resolve constitution (above).
2. Scan current initiative's artifacts against constitutional requirements.
3. For each requirement: PASS / FAIL / NOT-APPLICABLE (based on track).
4. Report compliance status. Hard-fail promotion PRs if any required gate fails.

### 4.6 Cross-Initiative Sensing / Impact Analysis

**Purpose:** Detect overlapping or conflicting initiatives at lifecycle gates.

**Steps:**
1. Triggered automatically at: init, promotion gates, and on-demand via `/sense`.
2. List all branches in the control repo matching initiative root patterns:
   ```bash
   git branch --list '*-small*' '*-medium*' '*-large*'
   ```
3. Parse branch names to extract: domain, service, feature, current audience.
4. For the current initiative, find all other initiatives in the same domain (or service):
   - Same domain: `foo-*` when current is `foo-bar-*`.
   - Same service: `foo-bar-*` when current is `foo-bar-auth-*`.
5. For each overlapping initiative, read its committed initiative config to determine:
   - Track, current phase (from branch existence), language, scope.
6. Report: "⚠️ Active initiatives in domain `foo`: `foo-bar` (techplan/small), `foo-car` (devproposal/medium). Review for conflict."
7. This is an **informational gate** by default. Constitution can upgrade it to a **hard gate** per domain/service.

---

## 5. Git-Derived State Model

### 5.1 Core Principle

**There is no `state.yaml`.** State is derived from three durable sources:
1. **Branch existence** — what branches exist tells you what's been started.
2. **PR provider metadata** — open/merged/closed PRs in the configured provider tell you what's been reviewed.
3. **Committed artifacts** — what files exist on what branches tells you what's been produced.

### 5.2 State Queries

#### "What initiative am I in?"

```bash
# Parse current branch name
BRANCH=$(git symbolic-ref --short HEAD)
# Branch pattern: {initiative-root}-{audience}-{phase}
# or: {initiative-root}-{audience}
# or: {initiative-root}
INITIATIVE_ROOT=$(echo "$BRANCH" | sed -E 's/-(small|medium|large|base)(-.*)?$//')
```

The initiative root is the prefix before any audience suffix. The initiative config file lives at:
```
_bmad-output/lens-work/initiatives/{domain}/{service}/{feature}.yaml
```
Read it from the current branch to get track, language, scope.

#### "What phase am I in?"

```bash
# If branch matches {root}-{audience}-{phase}, the phase is the last segment
PHASE=$(echo "$BRANCH" | sed -E 's/^.*-(small|medium|large|base)-//')
# If branch is just {root}-{audience}, no active phase (between phases)
```

Fallback: list all phase branches for this initiative and audience:
```bash
git branch --list "${INITIATIVE_ROOT}-${AUDIENCE}-*"
```
Presence of a branch = phase was started. Check if a PR exists from that branch → audience branch. If PR is merged, phase is complete.

#### "What audience level am I in?"

```bash
# Parse from branch name
AUDIENCE=$(echo "$BRANCH" | grep -oE '(small|medium|large|base)')
```

If on the initiative root branch (no audience suffix), the initiative is at the root level (pre-init or all audiences completed).

#### "What phases are complete?"

For each phase defined by the initiative's track:
```bash
# Query the configured PR provider for a merged PR from the phase branch to its audience branch
prctl list --base "${INITIATIVE_ROOT}-${AUDIENCE}" \
           --head "${INITIATIVE_ROOT}-${AUDIENCE}-${PHASE}" \
           --state merged
```

Phase is complete if and only if a merged PR exists from `{root}-{audience}-{phase}` → `{root}-{audience}`.

#### "Has promotion occurred?"

```bash
# Query the configured PR provider for a merged PR from one audience to the next
prctl list --base "${INITIATIVE_ROOT}-medium" \
           --head "${INITIATIVE_ROOT}-small" \
           --state merged
```

Promotion from small→medium is complete if and only if a merged PR from `{root}-small` → `{root}-medium` exists. Same pattern for medium→large, large→base.

Additionally: audience branch existence is a signal. If `{root}-medium` exists, either promotion has occurred or is in progress (check PR state).

#### "What other active initiatives in the same domain may conflict?"

```bash
# List all initiative-root branches, filter by domain prefix
git branch --list "${DOMAIN}-*" | grep -v "${INITIATIVE_ROOT}" | \
  sed -E 's/-(small|medium|large|base)(-.*)?$//' | sort -u
```

For each unique initiative root found, read its config from its branch to get scope, track, and current position.

### 5.3 State Derivation Summary

| Question | v1 Answer | v2 Answer |
|----------|-----------|-----------|
| Current initiative | `state.yaml → active_initiative` | Parse `git symbolic-ref --short HEAD` |
| Current phase | `state.yaml → current_phase` | Parse branch name suffix after audience |
| Current audience | `state.yaml → current_audience` | Parse branch name for `small/medium/large/base` |
| Completed phases | `state.yaml → completed_phases[]` | Query merged PRs from phase→audience branches via the provider adapter |
| Promotion status | `state.yaml → promoted_audiences[]` | Query merged PRs from audience→audience branches via the provider adapter |
| Active initiatives | `state.yaml → initiatives{}` scan | `git branch --list` + parse initiative roots |
| Initiative config | `_bmad-output/.../initiatives/{path}.yaml` (was dual-written) | Same path, but now committed on initiative branch |
| Event history | `event-log.jsonl` (git-ignored) | PR descriptions + commit messages (searchable via `git log`) |

### 5.4 The `git-state` Skill

Replaces `state-management.md`. No file I/O to `state.yaml`. All reads are git queries.

```markdown
# Skill: git-state

## Purpose
Derive initiative state from git primitives. No runtime state files.

## Queries Available
- `current-initiative` — parse HEAD branch name → initiative root → read config
- `current-phase` — parse branch name → phase suffix
- `current-audience` — parse branch name → audience token
- `phase-status(phase)` — check PR state for phase→audience
- `promotion-status(from, to)` — check PR state for audience→audience
- `active-initiatives(domain?)` — list branches → parse roots → filter by domain
- `initiative-config(root)` — read config from the target branch via `git show`, without changing HEAD
- `artifact-inventory(initiative, phase)` — list files in phase directory on branch

## Data Sources (read-only)
- `git symbolic-ref --short HEAD`
- `git branch --list`
- `git log --oneline`
- `prctl list` via the configured provider adapter (`gh` for GitHub, provider-specific API/CLI for Azure DevOps)
- `git show <branch>:<path>` for read-only config inspection across branches
- File reads on current branch (committed artifacts)

## Write Operations
NONE. This skill is read-only. Writes happen through:
- `git-orchestration` skill (branch creation, commits, pushes)
- PR creation (phase completion, promotion)
```

---

## 6. How `/switch` Works in v2

### 6.1 The v1 Problem

In v1, `/switch` modified `state.yaml` to change `active_initiative`. But `state.yaml` was git-ignored, so:
- Switching branches didn't update state.yaml.
- State.yaml didn't reflect the branch you were actually on.
- Switching back loaded stale state.
- Dual-write tried to reconcile, failed.

### 6.2 v2 Design: `/switch` = `git checkout`

In v2, switching initiatives is literally `git checkout {initiative-root}` or `git checkout {initiative-root}-{audience}` or any branch in the initiative's topology.

**Steps:**
1. User says `/switch` or `/switch foo-bar`.
2. If no argument: list all initiative root branches:
   ```bash
   git branch --list | sed -E 's/-(small|medium|large|base)(-.*)?$//' | sort -u
   ```
   Present as a numbered list. User picks one.
3. Determine which branch to checkout:
   - If the initiative has an active phase branch (open PR from phase→audience), checkout that phase branch.
   - Otherwise, checkout the highest audience branch: base > large > medium > small.
   - If user specifies a phase, checkout `{root}-{audience}-{phase}` directly.
4. `git checkout {target-branch}`.
5. Read the initiative config from the now-checked-out branch at `_bmad-output/lens-work/initiatives/{domain}/{service}/{feature}.yaml`.
6. Report: "Switched to initiative `foo-bar`. Track: full. Current phase: techplan. Audience: small."

**Why this works:**
- The branch IS the state. Checking out the branch loads the committed artifacts and config.
- No state file to keep in sync. No dual-write. No staleness.
- `git stash` / `git worktree` are available if the user wants to context-switch without committing.

### 6.3 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Dirty working directory on switch | Prompt: commit, stash, or abort. Never silently discard. |
| Initiative branch deleted | Report error: initiative not found. Suggest `git branch --list`. |
| Multiple checkout candidates | Present options: "foo-bar has branches: `-small`, `-small-businessplan`, `-medium`. Which?" |
| New initiative (no phase started) | Checkout `{root}-small`. Next action: `/preplan`. |

---

## 7. Cross-Initiative Sensing Model

### 7.1 The v1 Problem

v1 had 10 discovery workflow folders. None were exercised. Discovery was manual, required user to invoke specific commands, and had no lifecycle integration. Cross-initiative awareness was a stated goal but never worked.

### 7.2 v2 Design: Automatic Sensing at Lifecycle Gates

Sensing is **not a separate workflow category.** It is a step within existing lifecycle gates.

**Trigger points (automatic, not user-invoked):**
1. **`/new-*` (init):** Before creating branches, scan for other active initiatives in the same domain/service.
2. **Promotion PR creation:** Before creating a promotion PR, scan for conflicts.
3. **On-demand:** User can say `/sense` to run it manually.

**Sensing algorithm:**

```
INPUT:
  current_initiative: {domain}-{service}-{feature}
  current_domain: {domain}
  current_service: {service}  # may be null

PROCESS:
  1. List all branches in control repo
  2. Parse each branch name to extract initiative roots
  3. Deduplicate roots
  4. For each root != current_initiative:
     a. If root starts with {current_domain}-:
        → same-domain overlap detected
     b. If root starts with {current_domain}-{current_service}-:
        → same-service overlap detected (higher risk)
   c. Read that initiative's config with `git show {root}:path/to/config`, without checking out the branch
     d. Determine its phase and audience (from branch existence / PR state)
  5. Build overlap report

OUTPUT:
  overlapping_initiatives:
    - root: foo-car
      domain: foo
      service: car
      track: feature
      phase: devproposal
      audience: medium
      risk: same-domain
    - root: foo-bar-cache
      domain: foo
      service: bar
      track: tech-change
      phase: techplan
      audience: small
      risk: same-service

GATE BEHAVIOR:
  - Default: informational (report + continue)
  - Constitution can escalate to hard gate per domain/service:
    constitution.md:
      ## Article: Cross-Initiative Gate
      domain/foo: hard-block on same-service overlap at promotion
```

### 7.3 Sensing Skill (`sensing.md`)

```markdown
# Skill: sensing

## Purpose
Detect cross-initiative overlaps at lifecycle gates. Automatic, not manual.

## Triggers
- /new-* (before branch creation)
- /promote (before PR creation)
- /sense (on-demand)

## Algorithm
1. git branch --list → parse initiative roots by domain/service prefix
2. Filter for same-domain or same-service overlap with current initiative
3. For each overlap: read initiative config, derive phase/audience from branch state
4. Build overlap report

## Output
Structured overlap report with risk classification.

## Gate Integration
- Default: informational (warn + proceed)
- Constitution can upgrade to hard gate per domain/service
- Promotion PRs include sensing results in PR body
- Phase-completion and promotion PRs are auto-created after sensing and compliance prechecks finish
```

---

## 8. Branch Model for v2

### 8.1 Branch Naming Convention (unchanged from v1, validated)

```
{initiative-root}                           # Initiative root branch
{initiative-root}-small                     # IC creation audience
{initiative-root}-small-preplan             # Phase branch
{initiative-root}-small-businessplan        # Phase branch
{initiative-root}-small-techplan            # Phase branch
{initiative-root}-medium                    # Lead review audience
{initiative-root}-medium-devproposal       # Phase branch
{initiative-root}-large                     # Stakeholder audience
{initiative-root}-large-sprintplan          # Phase branch
{initiative-root}-base                      # Ready for execution
```

### 8.2 Lazy vs. Eager Audience Branch Creation

**v2 decision: LAZY creation.**

Rationale:
- v1 created all audience branches eagerly at init. For a `spike` track, medium/large/base were created but never used.
- Lazy creation means audience branches are created only when promotion to that audience is triggered.
- Branch existence becomes meaningful: if `{root}-medium` exists, promotion to medium was at least attempted.
- Reduces branch clutter for short-track initiatives.

**Rules:**
- At init: create `{root}` and `{root}-small` only.
- At promotion small→medium: create `{root}-medium` from `{root}-small`, then create promotion PR.
- At promotion medium→large: create `{root}-large` from `{root}-medium`, then create promotion PR.
- At promotion large→base: create `{root}-base` from `{root}-large`, then create promotion PR.

### 8.3 Phase Branch Lifecycle

1. **Created** when phase starts: `{root}-{audience}-{phase}` from `{root}-{audience}`.
2. **Worked on** during phase: artifacts are saved incrementally, with one reviewable commit at the end of the batch and optional explicit checkpoints.
3. **PR created** when phase is complete: `{root}-{audience}-{phase}` → `{root}-{audience}`.
4. **Deleted** after PR is merged. (Standard PR branch cleanup.)
5. **Phase completion** = merged PR from phase branch to audience branch.

### 8.4 Merge Chain

```
Phase branches ─PR→ Audience branch ─Promotion PR→ Next audience ─Promotion PR→ ...→ base

preplan ──PR──┐
businessplan ─PR──┤ small ──Promotion PR──→ medium ──Promotion PR──→ large ──Promotion PR──→ base
techplan ─────PR──┘              │                      │                       │
                          devproposal ─PR──┘    sprintplan ─PR──┘              │
                                                                         (handoff to dev)
```

### 8.5 Target Project Branches (Code Repos)

Unchanged from v1 (validated). GitFlow model:
```
feature/{epic-key}-{story-key} ──PR──→ feature/{epic-key} ──PR──→ develop ──→ release/{version} ──→ main
```

Target project branches are managed by the `dev` phase and `@dev` agent (Amelia), not by `@lens`. `@lens` only orchestrates the planning lifecycle in the control repo.

---

## 9. What Belongs Where

### 9.1 `.github/` (Domain 3 — Copilot Adapter)

**Contains:**
- `copilot-instructions.md` — References BMAD framework, wires lens-work module.
- `.agents/lens.agent.md` — Thin wrapper that activates `@lens` from `bmad.lens.release/_bmad/lens-work/agents/lens.agent.yaml`.
- `.agents/skills/` — Skill wrappers that reference module skills by path.

**Does NOT contain:**
- Copies of lifecycle.yaml, skills, or workflows.
- Any initiative-specific data.
- Governance data.

**Write frequency:** Rarely. Only changes when BMAD module version changes or agent configuration is updated.

### 9.2 `bmad.lens.release/` (Domain 2 — Module Payload)

**Contains:**
- `_bmad/lens-work/` — The complete module: lifecycle contract, agent, skills, workflows, prompts.
- `_bmad/core/`, `_bmad/bmm/`, `_bmad/cis/`, etc. — Other BMAD modules.
- `_bmad-output/` — Module-level outputs (not initiative data).

**Does NOT contain:**
- User initiative data.
- Governance data.
- Runtime state of any kind.

**Write frequency:** Only on module releases (version bumps). Read-only during initiative work.

### 9.3 `TargetProjects/.../governance/` (Domain 4 — Governance)

**Contains:**
- `constitutions/` — 4-level hierarchy of constitutional rules.
- `roster/` — Team configuration.
- `policies/` — Coding and process policies.
- `repo-inventory.yaml` — Canonical list of known repositories.

**Does NOT contain:**
- Initiative data.
- Module code.
- Planning artifacts.

**Write frequency:** Infrequent. Changes are PRs in the governance repo. Constitutional amendments propagate through re-resolution (read-side), not through writes to active initiatives.

### 9.4 `_bmad-output/` (Domain 1 — Working State / Artifacts)

**Contains:**
- `lens-work/governance-setup.yaml` — Pointer to governance repo clone.
- `lens-work/initiatives/{domain}/{service}/{feature}.yaml` — Initiative configs.
- `lens-work/initiatives/{domain}/{service}/phases/` — Planning artifacts per phase.
- `brainstorming/`, `planning-artifacts/`, `implementation-artifacts/` — BMAD workflow outputs.

**Does NOT contain:**
- Module code (that's in `bmad.lens.release/`).
- Governance source of truth (that's in the governance repo).
- git-ignored runtime state. **Everything here is committed.**

**Write frequency:** High. This is where `@lens` writes during active initiative work. Reviewable phase bundles are committed + pushed; draft writes do not need their own commits.

---

## 10. v2 Blueprint

### 10.1 Keep / Fix / Drop Summary

#### KEEP (validated by v1)

| Feature | Rationale |
|---------|-----------|
| PR-as-PBR | Core value proposition. Artifact review via PR diffs. No meetings. |
| Automatic PR creation | Key validated UX feature. Phase-completion and promotion PRs are opened automatically once the workflow reaches a reviewable handoff. |
| Phase lifecycle (named phases) | preplan → businessplan → techplan → devproposal → sprintplan. Clear ownership, clear artifacts. |
| Audience promotion chain | small → medium → large → base. Each promotion is a gated PR. |
| Constitution system | 4-level additive inheritance, per-article gates, language-specific variants. |
| User interaction keywords | `defaults`, `yolo`, `skip`, `pause`, `back`. Reduce friction without bypassing safety. |
| Tracks | full, feature, tech-change, hotfix, spike, quickdev. Skip what doesn't apply. |
| Reviewable-checkpoint push convention | Push reviewable phase bundles or explicit checkpoints, not every draft artifact write. |
| Branch naming convention | `{root}-{audience}-{phase}`. Human-readable, parseable, state-carrying. |
| Adversarial review (party mode) | Multi-agent review at promotion gates. |
| Single @lens agent | Routing through one agent with skill delegation. Unified UX. |

#### FIX / REDESIGN

| Feature | v1 Problem | v2 Solution |
|---------|------------|-------------|
| State management | `state.yaml` git-ignored → staleness, drift, dual-write failure | Git-derived state → branch names, PR state, committed configs |
| `/switch` | Modified git-ignored `state.yaml` → state/branch desync | Pure `git checkout` → branch IS state |
| Cross-initiative awareness | 10 manual discovery workflows, never used | Automatic sensing at init + promotion gates |
| PR provider lock-in | GitHub-only query assumptions | Provider adapter supports GitHub and Azure DevOps without changing lifecycle semantics |
| Onboarding and secrets | PAT/preferences were undefined under the git-only model | `/onboard` writes only non-secret profile data; auth lives in credential stores |
| Event history | `event-log.jsonl` git-ignored → lost on switch | PR descriptions + commit messages → searchable, permanent |
| Config files | 3 configs (`lifecycle.yaml`, `module.yaml`, `bmadconfig.yaml`) | 2 configs (`lifecycle.yaml`, `module.yaml`). Drop `bmadconfig.yaml` — merge into `module.yaml`. |
| Audience branch creation | Eager (all created at init) → branch clutter | Lazy (created on promotion) → branch existence = signal |
| Repair/recovery workflows | 9 repair workflows → instability signal | Eliminate root cause (state.yaml) → eliminate most repair workflows and keep only onboarding/health checks |
| Test coverage | Dropping the JS runtime should not mean dropping verification | Replace the JS-heavy suite with a slim contract-test layer around parsing, provider queries, sensing, and governance |

#### DROP

| Feature | Rationale |
|---------|-----------|
| `state.yaml` | Root cause of systemic staleness. Contradicts git-native design. |
| Dual-write model | Tried to compensate for `state.yaml` failure. Created more staleness. |
| `event-log.jsonl` (git-ignored) | History without permanence. PR descriptions replace it. |
| JS lib layer (33 files) | Orphaned. Violates module's own `no_runtime_js` convention. |
| JS test layer (34 files) | Tied to orphaned JS libs. Replace with a smaller contract-test suite. |
| `impl-*` prompts (28 files) | Dev artifacts shipped as features. Never invoked at runtime. |
| `state-management.md` skill | Replaced by `git-state.md`. |
| `discovery.md` skill | Replaced by `sensing.md`. Much smaller scope. |
| `visual-documentation.md` skill | Never referenced by any workflow. |
| `phase-completion.md` skill | Merged into `phase-lifecycle` workflow. |
| `scripts/` directory | PowerShell/bash scripts for manual operations. Not needed with git-CLI-native workflows. |
| 10 discovery workflows | Sprawl. Replaced by 1 sensing workflow with lifecycle integration. |
| 9 repair/recovery workflows | Symptom of state.yaml instability. Root cause eliminated. |
| `resume/` workflow | No state file to resume from. Branch is the resume point. |
| `bootstrap/` workflow | Init workflow covers this. |
| `batch-process/` workflow | Over-engineering for a never-used scenario. |
| `package.json`, `package-lock.json`, `index.js` | No JS runtime in v2. |
| `bmadconfig.yaml` | Merge relevant settings into `module.yaml`. |

### 10.2 File Tree Sketch (Complete v2)

```
Control Repo (D:\weberbot.bmad)
├── .github/                                    # Domain 3: Copilot Adapter
│   ├── copilot-instructions.md
│   └── agents/
│       └── lens.agent.md                       # Thin wrapper → release module
│
├── bmad.lens.release/                          # Domain 2: Release Module
│   └── _bmad/
│       ├── lens-work/
│       │   ├── README.md
│       │   ├── lifecycle.yaml                  # THE contract
│       │   ├── module.yaml                     # Module identity + config
│       │   ├── module-help.csv
│       │   ├── agents/
│       │   │   ├── lens.agent.yaml
│       │   │   └── constitution.md
│       │   ├── skills/
│       │   │   ├── git-orchestration.md        # Branch ops, commits, PRs
│       │   │   ├── git-state.md                # NEW: git-derived state queries
│       │   │   ├── constitution.md             # Governance resolution
│       │   │   ├── sensing.md                  # NEW: cross-initiative detection
│       │   │   └── checklist.md                # Phase gate checklists
│       │   ├── workflows/
│       │   │   ├── core/
│       │   │   │   ├── phase-lifecycle/
│       │   │   │   └── audience-promotion/
│       │   │   ├── router/
│       │   │   │   ├── init-initiative/
│       │   │   │   ├── preplan/
│       │   │   │   ├── businessplan/
│       │   │   │   ├── techplan/
│       │   │   │   ├── devproposal/
│       │   │   │   ├── sprintplan/
│       │   │   │   └── dev/
│       │   │   ├── utility/
│       │   │   │   ├── onboard/
│       │   │   │   ├── status/
│       │   │   │   ├── next/
│       │   │   │   ├── switch/
│       │   │   │   └── help/
│       │   │   ├── governance/
│       │   │   │   ├── compliance-check/
│       │   │   │   ├── resolve-constitution/
│       │   │   │   └── cross-initiative/
│       │   │   └── includes/
│       │   │       ├── pr-links.md
│       │   │       ├── artifact-validator.md
│       │   │       └── size-topology.md
│       │   ├── prompts/                        # 13 prompts (down from 47)
│       │   │   ├── lens-work.new-initiative.prompt.md
│       │   │   ├── lens-work.preplan.prompt.md
│       │   │   ├── lens-work.businessplan.prompt.md
│       │   │   ├── lens-work.techplan.prompt.md
│       │   │   ├── lens-work.devproposal.prompt.md
│       │   │   ├── lens-work.sprintplan.prompt.md
│       │   │   ├── lens-work.status.prompt.md
│       │   │   ├── lens-work.next.prompt.md
│       │   │   ├── lens-work.switch.prompt.md
│       │   │   ├── lens-work.promote.prompt.md
│       │   │   ├── lens-work.constitution.prompt.md
│       │   │   ├── lens-work.onboard.prompt.md
│       │   │   └── lens-work.help.prompt.md
│       │   └── docs/
│       │       └── lifecycle-reference.md
│       │   └── tests/
│       │       └── contracts/
│       │
│       ├── core/                               # Core BMAD module
│       ├── bmm/                                # BMM module
│       └── ...                                 # Other modules
│
├── TargetProjects/
│   └── lens/
│       └── lens-governance/                    # Domain 4: Governance Repo (cloned)
│           ├── constitutions/
│           │   ├── org/constitution.md
│           │   ├── {domain}/constitution.md
│           │   └── {domain}/{service}/constitution.md
│           ├── roster/team.yaml
│           ├── policies/*.md
│           └── repo-inventory.yaml
│
├── Docs/                                       # Canonical documentation output
│
└── _bmad-output/                               # Domain 1: Working State
    ├── lens-work/
    │   ├── governance-setup.yaml               # Governance repo pointer
   │   ├── profile.yaml                        # Committed non-secret user profile
    │   └── initiatives/                        # COMMITTED (not git-ignored)
    │       └── {domain}/
    │           └── {service}/
    │               ├── {feature}.yaml          # Initiative config
    │               └── phases/
    │                   ├── preplan/*.md
    │                   ├── businessplan/*.md
    │                   ├── techplan/*.md
    │                   ├── devproposal/*.md
    │                   └── sprintplan/*.md
    ├── brainstorming/
    ├── planning-artifacts/
    └── implementation-artifacts/
```

### 10.3 Lifecycle Sketch (Full Track)

```
USER                     @lens                      GIT                         GOVERNANCE
  │                        │                          │                             │
  ├─/new-feature foo-bar───►│                          │                             │
  │                        ├─read lifecycle.yaml──────►│                             │
  │                        ├─read constitution────────►├─────────────────────────────►│
  │                        │                          │ verify track permitted       │
  │                        ├─sensing: any foo-* active?│                             │
  │                        ├─create branches──────────►│ {root}, {root}-small        │
  │                        ├─commit initiative config─►│ push                        │
  │                        │                          │                             │
  ├─/preplan───────────────►│                          │                             │
  │                        ├─derive state from git────►│ parse HEAD, list branches   │
  │                        ├─create {root}-small-preplan►│                            │
  │                        ├─delegate to Mary──────────┤                             │
   │                        │ (artifacts drafted, then bundled) │                       │
  │                        ├─create PR: preplan→small──►│                             │
  │                        │                          │                             │
  ├─(merge PR)─────────────┤──────────────────────────►│ preplan merged into small   │
  │                        │                          │                             │
  ├─/businessplan──────────►│                          │                             │
  │                        ├─derive state: preplan PR merged? yes                   │
  │                        ├─create {root}-small-businessplan►│                      │
  │                        ├─delegate to John+Sally───┤                              │
  │                        ├─create PR: businessplan→small►│                         │
  │                        │                          │                             │
  ├─(repeat for techplan)──►│                          │                             │
  │                        │                          │                             │
  ├─/promote───────────────►│                          │                             │
  │                        ├─all small phases merged?──►│ yes                        │
  │                        ├─constitution compliance───►├────────────────────────────►│
  │                        │                          │ resolve 4-level chain        │
  │                        ├─sensing: foo-* conflicts?─►│                            │
  │                        ├─lazy-create {root}-medium─►│                            │
  │                        ├─create PR: small→medium───►│ adversarial-review gate    │
  │                        │                          │                             │
  ├─(adversarial review)───┤──────────────────────────►│ party mode → merge PR      │
  │                        │                          │                             │
  ├─/devproposal───────────►│                          │                             │
  │                        ├─derive state: on medium───►│                            │
  │                        ├─create {root}-medium-devproposal►│                     │
  │                        ├─delegate to John──────────┤                             │
  │                        ├─create PR: devproposal→medium►│                        │
  │                        │                          │                             │
  ├─(merge → promote → sprintplan → promote → base)──►│                             │
  │                        │                          │                             │
  ├─/dev───────────────────►│                          │                             │
  │                        ├─derive state: on base─────►│                            │
  │                        ├─delegate to Amelia────────┤ (works in TargetProjects)   │
  │                        │                          │                             │
  └────────────────────────┘──────────────────────────┘─────────────────────────────┘
```

### 10.4 Biggest Architectural Risks to Avoid

#### Risk 1: Git Query Performance at Scale

**Threat:** With many initiatives, `git branch --list` and provider PR queries may become slow. Sensing must parse all branches on every trigger.

**Mitigation:**
- Cache branch-list results within a single session (branches don't change mid-session unless you create them).
- Initiative root parsing is O(n) on branch count. For <100 active initiatives, this is instant.
- Provider PR queries add network latency. Batch queries and normalize them through the provider adapter.
- If scale becomes a problem later, introduce a committed `_bmad-output/lens-work/.branch-index.yaml` that is updated on branch creation/deletion — but only if needed. Don't pre-engineer this.

#### Risk 2: Branch Name Parsing Fragility

**Threat:** The entire state model depends on parsing branch names. If branch naming is inconsistent, state derivation breaks.

**Mitigation:**
- Branch naming is enforced by `git-orchestration` skill — `@lens` creates all branches, users don't.
- Validate branch names at creation time against `lifecycle.yaml` patterns.
- Add a branch-name validation step to `/status` and `/next` as a sanity check.
- Feature name part of `{initiative-root}` must be slug-safe (lowercase, hyphens only, no audience/phase keywords). Enforce at `/new-*`.

#### Risk 3: Lazy Branch Creation and PR Targeting

**Threat:** If `{root}-medium` doesn't exist yet when `/promote` is called, the promotion PR target branch doesn't exist. The configured PR provider will reject a PR targeting a non-existent branch.

**Mitigation:**
- Promotion workflow creates the target branch first, then creates the PR. This is explicitly sequenced in the promotion workflow (§4.3, step 4).
- Guard: if branch creation fails, abort promotion with clear error.

#### Risk 4: Governance Repo Availability

**Threat:** If governance repo is not cloned or falls behind, constitution resolution becomes inconsistent across control repos.

**Mitigation:**
- `@lens` verifies governance clone at session start (every initial command runs a governance check).
- `governance-setup.yaml` exists in control repo with expected clone path.
- If governance repo is missing: hard block with clear message "Run `/onboard` to bootstrap governance, or clone `{governance-url}` into `{expected-path}` first."
- If governance repo is stale: warn for read-only commands, but block `/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/promote`, and `/compliance-check` until the governance clone is refreshed.

#### Risk 5: PR State as Source of Truth for Phase Completion

**Threat:** PRs can be closed without merging, reopened, or force-merged. This creates ambiguous state.

**Mitigation:**
- Only **merged** PRs count as phase completion. Closed-without-merge is not completion.
- If a phase branch exists but no PR exists → phase is in-progress.
- If a phase branch exists AND a closed (not merged) PR exists → phase was abandoned. `/status` reports this explicitly.
- Force-merges are treated the same as normal merges (the PR is merged).

#### Risk 6: Multi-Machine / Multi-Session State Consistency

**Threat:** User works from two machines. On machine A, they're in initiative X. On machine B, they switch to initiative Y. Without `state.yaml`, there's no "active initiative" concept to conflict — but they might have different branch checkouts.

**Mitigation:**
- This is actually **solved by v2's design.** Git itself handles multi-machine state via `git pull` and `git checkout`. There's no side-channel state to desync.
- Standard git workflow still applies. Users can run `git pull --rebase` directly until a convenience wrapper is justified later.

#### Risk 7: Rebuilding Too Much at Once

**Threat:** The v1→v2 rewrite is large. Attempting to build all 16 workflows, 5 skills, and 13 prompts simultaneously will create a system that's never been tested end-to-end.

**Mitigation:**
- Build in layers:
   1. **Layer 0:** `lifecycle.yaml` (contract) + `module.yaml` (identity) + `git-state` skill + `git-orchestration` skill + provider-adapter contract.
   2. **Layer 1:** `/onboard` + `/new-*` init workflow + `/status` + `/next` + `/switch`. This gives a working entry experience and initiative shell.
   3. **Layer 2:** Phase router workflows (`/preplan` through `/sprintplan`) + `phase-lifecycle` core workflow.
   4. **Layer 3:** `/promote` + `audience-promotion` core workflow + `constitution` skill + `sensing` skill.
   5. **Layer 4:** Governance workflows + cross-initiative workflow + compliance check + migration checklist.
- Test each layer before building the next. Layers 0-4 together form the MVP release slice; Layers 0-1 are only the first implementation increment.

---

## Appendix A: v1 → v2 Reduction Metrics

| Metric | v1 | v2 | Reduction |
|--------|------|------|-----------|
| Skills | 7 | 5 | -29% |
| Workflows | ~60 | ~16 | -73% |
| Prompts | 47 | 13 | -72% |
| JS files | 33 | 0 | -100% |
| Test files | 34 | ~8 | ~-76% |
| Config files | 3 | 2 | -33% |
| Scripts | 4 | 0 | -100% |
| Repair workflows | 9 | 0 | -100% |
| Discovery workflows | 10 | 1 | -90% |
| State files (git-ignored) | 2 | 0 | -100% |

## Appendix B: v2 Prompt Map

| Prompt | Command | Phase | Agent |
|--------|---------|-------|-------|
| `new-initiative` | `/new-*` | — | @lens |
| `preplan` | `/preplan` | preplan | Mary |
| `businessplan` | `/businessplan` | businessplan | John+Sally |
| `techplan` | `/techplan` | techplan | Winston |
| `devproposal` | `/devproposal` | devproposal | John |
| `sprintplan` | `/sprintplan` | sprintplan | Bob |
| `status` | `/status` | — | @lens |
| `next` | `/next` | — | @lens |
| `switch` | `/switch` | — | @lens |
| `promote` | `/promote` | — | @lens |
| `constitution` | `/constitution` | — | @lens (Lex) |
| `onboard` | `/onboard` | — | @lens |
| `help` | `/help` | — | @lens |

## Appendix C: Initiative Config Schema (v2)

```yaml
# _bmad-output/lens-work/initiatives/{domain}/{service}/{feature}.yaml
# COMMITTED — this is a git-tracked source of truth

initiative: user-authentication
domain: identity
service: auth-service
track: full
language: typescript
scope: service
created: 2026-03-08T10:00:00Z
initiative_root: identity-auth-service-user-authentication

# No phase/audience tracking here.
# Phase and audience state are derived from branch existence and PR state.
# This file is the IDENTITY of the initiative, not the STATUS.
```
