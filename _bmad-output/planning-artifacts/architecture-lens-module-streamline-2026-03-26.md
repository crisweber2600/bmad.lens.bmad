---
stepsCompleted: [step-01-init, step-02-context, step-03-starter, step-04-decisions, step-05-patterns, step-06-structure, step-07-validation, step-08-complete]
inputDocuments:
  - '_bmad-output/planning-artifacts/prd-lens-module-streamline-2026-03-26.md'
  - '_bmad-output/planning-artifacts/businessplan-questions-lens-module-streamline-2026-03-26.md'
  - '_bmad-output/planning-artifacts/research/technical-lens-work-streamline-research-2026-03-26.md'
  - '_bmad-output/planning-artifacts/research/domain-lens-work-architecture-research-2026-03-26.md'
batchMode: true
date: '2026-03-26'
author: '@lens'
initiative: lens-module-streamline
version: '3.0.0'
status: PROPOSAL
---

# lens-work v3 — Architecture Document (Streamline)

**Author:** @lens
**Date:** 2026-03-26
**Version:** 3.0.0
**Initiative:** lens-module-streamline
**Status:** PROPOSAL
**Input:** PRD v3.0 (2026-03-26), businessplan answers (2026-03-26), research documents

---

## 0. Design Axioms (Non-Negotiable)

These axioms govern all v3 decisions. Any design that violates one of these is rejected regardless of other merits.

| Axiom | Statement | Source |
|-------|-----------|--------|
| **A1: YAML is the single source of truth for runtime state.** | `initiative-state.yaml` owns all initiative runtime state. No state encoded in branch names. No state derived from git log scanning. | Branch-name parsing brittleness; git log O(N) performance |
| **A2: Git is the durability layer.** | All state files are committed in git. No git-ignored runtime state. Any state is fully reproducible from a checkout alone. | v2 axiom retained |
| **A3: PRs are the only gate for audience promotion.** | Phase artifacts are reviewed as PR diffs. Promotion happens through milestone-branch PRs. | v2 axiom retained |
| **A4: Authority domains must be explicit.** | Every file belongs to exactly one authority. Cross-authority writes are forbidden. | v2 axiom retained |
| **A5: Sensing must be automatic.** | Cross-initiative awareness happens at lifecycle gates without manual discovery. | v2 axiom retained |
| **A6: Batch-first execution.** | Phase workflows produce complete artifacts in one pass; review happens at the end. | Introduced in v3 |
| **A7: Branch = lookup key only.** | Branch names identify which initiative YAML to load. No state is parsed from branch strings. | New in v3 |

---

## 1. Current System Analysis (v2)

### What Exists

```
Control Repo (git)
├── .github/                    ← Copilot Adapter
├── bmad.lens.release/          ← Release Module (read-only at runtime)
│   └── _bmad/lens-work/
│       ├── lifecycle.yaml      ← schema_version: 2; audience tokens: small/medium/large/base
│       ├── agents/
│       ├── skills/
│       │   ├── git-state.md    ← reads branch names + git log --grep for state
│       │   └── git-orchestration.md
│       └── workflows/
│           └── router/
│               ├── preplan/steps/        ← creates phase branch, opens PR
│               ├── businessplan/steps/   ← creates phase branch, opens PR
│               ├── techplan/steps/       ← creates phase branch, opens PR
│               ├── devproposal/steps/    ← creates phase branch, opens PR
│               └── sprintplan/steps/     ← creates phase branch, opens PR
├── TargetProjects/
│   └── lens/
│       └── lens-governance/    ← constitutions only; artifacts never published here
└── _bmad-output/
    └── planning-artifacts/     ← artifacts exist only in control repo; not queryable externally
```

### v2 Branch Topology (per full-track initiative)

```
foo-bar-auth                        ← root
foo-bar-auth-small                  ← audience branch
foo-bar-auth-small-preplan          ← phase branch (PR → small)
foo-bar-auth-small-businessplan     ← phase branch (PR → small)
foo-bar-auth-small-techplan         ← phase branch (PR → small)
foo-bar-auth-medium                 ← audience branch
foo-bar-auth-medium-devproposal     ← phase branch (PR → medium)
foo-bar-auth-large                  ← audience branch
foo-bar-auth-large-sprintplan       ← phase branch (PR → large)
foo-bar-auth-base                   ← audience branch
```

**Total: 10 branches**

### Known Problems with v2

| Problem | Root Cause | Impact |
|---------|-----------|--------|
| 9–11 branches per initiative | Phase branches + audience branches both exist | Branch list unreadable; wrong-branch work |
| `/status` is slow and brittle | State derived from branch suffix parsing + `git log --grep` | O(N) log scan; breaks on branch renames |
| `/switch` parses branch names | Discovery is `git branch --list` + string split | Wrong results if branches are renamed or non-standard |
| Governance repo empty | No publish-to-governance operation exists | Cannot query prior decisions without control repo checkout |
| Ghost work poisons sensing | No `/close`; abandoned branches = "active" in conflict detection | False-positive conflicts; incorrect sensing reports |
| Silent version failures | No `LENS_VERSION` file; no preflight version check | v2 config + v3 module → corrupt state |

---

## 2. v3 Target Architecture

### 2.1 Branch Topology (Redesigned)

Replace audience-name tokens with milestone names. Eliminate phase branches entirely.

**v3 branch topology per full-track initiative:**

```
foo-bar-auth                    ← root branch
foo-bar-auth-techplan           ← milestone: preplan + businessplan + techplan complete
foo-bar-auth-devproposal        ← milestone: devproposal complete
foo-bar-auth-sprintplan         ← milestone: sprintplan complete
foo-bar-auth-dev-ready          ← milestone: ready for execution
```

**Total: 5 branches** (50% reduction)

**Milestone naming rationale:**
- `techplan` replaces `small` — describes the gate achieved, not the audience size
- `devproposal` replaces `medium` — self-documenting for reviewers
- `sprintplan` replaces `large` — stakeholder-legible
- `dev-ready` replaces `base` — describes the execution-ready state

**Phase tracking:** Phase history is recorded via `[PHASE:X:COMPLETE]` commit markers on the milestone branch (append-only audit trail) and via `initiative-state.yaml` (queryable runtime state). No phase branch is created.

### 2.2 State Model (New)

#### `initiative-state.yaml` — Single Source of Truth

A new committed YAML file, one per initiative, stored alongside planning artifacts in the control repo.

**Schema:**

```yaml
# initiative-state.yaml
initiative: foo-bar-auth          # initiative slug
milestone: techplan               # current milestone branch token
phase: businessplan               # current phase within milestone
phase_status: in-progress         # in-progress | complete
lifecycle_status: active          # active | completed | abandoned | superseded
superseded_by: ~                  # initiative slug if lifecycle_status == superseded
last_updated: '2026-03-26'
lens_version: '3.0.0'            # module version at time of last write
```

**Read contract:** All state queries are a single `initiative-state.yaml` YAML read. No branch string parsing. No git log scanning. O(1) in all cases.

**Write contract:** `git-orchestration.md` `update-initiative-state` operation writes `initiative-state.yaml` and always includes it in the same commit as the triggering event (phase transition, close, upgrade). State and artifacts are atomically consistent at every commit boundary.

**Lookup contract:** The current git branch name is used as a lookup key to identify which initiative is active and therefore which `initiative-state.yaml` to read. The branch name is NOT parsed for structural state — it is only matched to the `initiative` field in the YAML.

#### `/switch` Discovery Model

`/switch` enumerates `initiative-state.yaml` files in the control repo to list available initiatives. Branch checkout is a side effect of the user selecting an initiative by name — not the discovery mechanism. This means `/switch` works correctly even if branch names are opaque or follow non-standard patterns.

#### Commit Markers (Audit Trail)

`[PHASE:{NAME}:{EVENT}]` commit markers remain as an append-only git log audit trail. They are never the state query path.

Format:
```
[PHASE:PREPLAN:COMPLETE] foo-bar-auth — preplan artifacts committed
[PHASE:BUSINESSPLAN:START] foo-bar-auth — businessplan phase started
[PHASE:BUSINESSPLAN:COMPLETE] foo-bar-auth — prd and architecture committed
[CLOSE:ABANDONED] foo-bar-auth — superseded by foo-bar-auth-v2
```

### 2.3 Governance Publication (New)

At every audience promotion (milestone-branch PR merge), `git-orchestration.md` `publish-to-governance` runs a direct push of all phase artifacts to the governance repo.

**Governance artifact path structure (deferred to TechPlan for exact spec):**

```
governance:
└── artifacts/
    └── {domain}/
        └── {service}/
            └── {initiative}/
                ├── product-brief.md
                ├── prd.md
                ├── architecture.md
                └── ...
```

**Tombstone path:**

```
governance:
└── tombstones/
    └── {domain}/
        └── {service}/
            └── {initiative}-tombstone.md
```

**Write model:** Direct push (not PR). Rationale: the artifact review gate is the milestone-branch PR. Once merged, artifacts are locked-in and propagate to governance without additional ceremony. See Decision 3.

### 2.4 Version Safety (New)

**`LENS_VERSION` file** in control repo root:

```
3.0.0
```

Written by `setup-control-repo.sh`/`.ps1` on initialization and by `/lens-upgrade` on upgrade.

**Preflight check (write-tier only):**

```
read LENS_VERSION from control repo root
read schema_version from lifecycle.yaml
if LENS_VERSION != schema_version:
  HARD STOP: "VERSION MISMATCH: control repo is v{X}, module expects v{Y}. Run /lens-upgrade."
```

**Preflight tiers** (defined in `lifecycle.yaml preflight_tiers`):
- **Read tier (lightweight — no pull required):** `/status`, `/discover`, `/next`, `/switch`
- **Write tier (full — pull + version validate):** `/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/promote`, `/close`, `/lens-upgrade`

---

## 3. Component Architecture

### 3.1 Component Map

```
MODULE (bmad.lens.release/_bmad/lens-work/)
│
├── lifecycle.yaml v3               ← Schema, milestone names, preflight tiers,
│                                      artifact_publication, close_states, migrations
│
├── skills/
│   ├── git-state.md                ← YAML read for all state; branch=lookup key;
│   │                                  /switch via YAML file enumeration
│   ├── git-orchestration.md        ← Branch create/push/validate;
│   │                                  update-initiative-state (atomic);
│   │                                  publish-to-governance (direct push)
│   ├── sensing.md                  ← Branch topology (live) + governance:artifacts/ (historical)
│   └── batch-process.md            ← One-pass artifact generation for batch-mode phases
│
├── workflows/
│   └── router/
│       ├── preplan/steps/          ← [PHASE:PREPLAN:START] marker; no phase branch created
│       ├── businessplan/steps/     ← [PHASE:BUSINESSPLAN:START/COMPLETE] markers; YAML update
│       ├── techplan/steps/         ← [PHASE:TECHPLAN:START/COMPLETE] markers; YAML update
│       ├── devproposal/steps/      ← [PHASE:DEVPROPOSAL:START/COMPLETE] markers; YAML update
│       ├── sprintplan/steps/       ← [PHASE:SPRINTPLAN:START/COMPLETE] markers; YAML update
│       ├── audience-promotion/     ← Milestone PR + publish-to-governance
│       ├── close/                  ← NEW: tombstone + initiative-state.yaml update + CLOSE marker
│       └── lens-upgrade/           ← NEW: migration descriptor execution + LENS_VERSION update
│
CONTROL REPO (per-initiative)
│
├── LENS_VERSION                    ← Current version binding (e.g., "3.0.0")
├── initiative-state.yaml           ← Per-initiative committed state (one per active initiative)
└── _bmad-output/planning-artifacts/
    ├── product-brief-{initiative}.md
    ├── prd-{initiative}.md
    ├── architecture-{initiative}.md
    └── businessplan-questions-{initiative}.md
```

### 3.2 Component Dependencies

```
[phase router steps] → [git-orchestration.md]: commit-artifacts (atomic with YAML update), create-branch (milestone only)
[phase router steps] → [git-state.md]: read current phase, initiative, milestone level from YAML
[audience-promotion workflow] → [git-orchestration.md]: publish-to-governance, create next milestone branch
[/close workflow] → [git-orchestration.md]: publish-to-governance (tombstone), update-initiative-state (lifecycle_status)
[/lens-upgrade workflow] → [lifecycle.yaml]: read migrations section; write updated lifecycle.yaml
[/lens-upgrade workflow] → [git-orchestration.md]: branch rename, LENS_VERSION update commit
[sensing.md] → [git-orchestration.md]: git show governance:artifacts/ (new governance read)
[preflight (all write commands)] → [LENS_VERSION + lifecycle.yaml]: version mismatch check
[git-state.md] → [initiative-state.yaml]: direct YAML read for all state queries
[git-state.md] → [lifecycle.yaml]: milestone token list lookup (for validation)
[git-orchestration.md] → [lifecycle.yaml]: validate-branch-name milestone token lookup
[git-orchestration.md] → [initiative-state.yaml]: atomic update on every phase transition commit
[batch-process.md] → [phase router templates]: context pre-population; one-pass artifact generation
```

### 3.3 Authority Boundaries

| Authority | Owner | Writes |
|-----------|-------|--------|
| Module (bmad.lens.release) | Module maintainer | `lifecycle.yaml`, all skill/workflow/step files |
| Control repo | User / agent | `LENS_VERSION`, `initiative-state.yaml`, planning artifacts |
| Governance repo | Module + user | `artifacts/{domain}/{service}/`, `tombstones/` |

---

## 4. Key Architectural Decisions

### Decision 1: Phase State Storage Model

**Decision: Committed YAML state file (`initiative-state.yaml`)**

Options evaluated:

| Option | Verdict |
|--------|---------|
| A. Git tags | Rejected — mutable (`git tag -f` replaces without trace) |
| B. Commit message markers | Rejected as primary state — O(N) log scan; requires log-stream interpretation for current state |
| C. Committed YAML state file | **Selected** |

**Rationale:**
- Branch name parsing is brittle and slow — string splitting with no schema, breaks on rename
- `git log --grep` is O(N) across commit history; requires interpreting log stream to find most-recent state
- `initiative-state.yaml` is O(1), explicitly typed, human-readable, and diff-able in PRs
- Consistency risk mitigated by atomic commits: `git-orchestration.md` updates `initiative-state.yaml` in the same commit as every phase transition; state and artifacts are always consistent at any commit boundary

**Retained from option B:** `[PHASE:X:COMPLETE]` commit markers remain as append-only audit trail for git history readability. They are never the query path.

---

### Decision 2: Branch Topology Redesign

**Decision: Milestone names + phase branches eliminated**

Options evaluated:

| Option | Verdict |
|--------|---------|
| A. Keep audience names; reduce phase branches only | Rejected — half-measure; `small/medium/large/base` still require domain knowledge |
| B. Milestone names + phase branches eliminated | **Selected** |
| C. Keep current model; add phase-state YAML only | Rejected — does not improve branch topology |

**Rationale:**
- Milestone names (`techplan`/`devproposal`/`sprintplan`/`dev-ready`) are self-documenting without knowing the audience model
- Reducing from 10 → 5 branches is the primary user-visible improvement
- Phase state now lives in `initiative-state.yaml`; phase branches are structurally redundant

---

### Decision 3: Governance Write Model

**Decision: Direct push (not PR)**

Options evaluated:

| Option | Verdict |
|--------|---------|
| A. PR-based governance writes | Rejected |
| B. Direct push | **Selected** |

**Rationale:**
- The artifact review gate is the PR that merges work into the milestone branch. Once merged, artifacts are locked-in.
- PR-based governance writes add a second review step for content already reviewed and approved.
- Direct push removes friction; trust is established by the milestone PR.

---

### Decision 4: Branch Naming Enforcement

**Decision: Strengthen `git-orchestration` validation**

Options evaluated:

| Option | Verdict |
|--------|---------|
| A. Git pre-receive/update hooks | Rejected — requires per-repo installation, admin access, `lifecycle.yaml` duplication |
| B. Agent-layer validation in `git-orchestration.md` | **Selected** |

**Rationale:**
- `git-orchestration.md` is already the sole branch creation point; no bypass path exists in normal workflow
- Dynamic validation against `lifecycle.yaml` milestone token list is more maintainable
- `validate-branch-name` precondition added to `push` as well as `create-branch`

---

### Decision 5: YAML Schema Migration Pattern

**Decision: Migration descriptors in `lifecycle.yaml` + `/lens-upgrade` command**

Options evaluated:

| Option | Verdict |
|--------|---------|
| A. Helm-style migration descriptors in `lifecycle.yaml` | **Selected** |
| B. Separate migration script per version pair | Rejected — violates single-source-of-truth |
| C. Manual migration instructions only | Rejected — error-prone |

**Rationale:**
- Declarative migration descriptors are versioned alongside the schema they describe
- `/lens-upgrade` reads descriptors and executes them deterministically
- `--dry-run` reduces migration risk

**`migrations` section schema:**

```yaml
migrations:
  - from_version: 2
    to_version: 3
    breaking: true
    changes:
      - type: rename_field
        path: audiences.small
        new_path: audiences.techplan
      - type: rename_field
        path: audiences.medium
        new_path: audiences.devproposal
      - type: rename_field
        path: audiences.large
        new_path: audiences.sprintplan
      - type: rename_field
        path: audiences.base
        new_path: audiences.dev-ready
      - type: add_field
        path: artifact_publication
        value: { governance_root: 'artifacts/', enabled: true }
      - type: add_field
        path: close_states
        value: [completed, abandoned, superseded]
    branch_rename_required: true
    migration_command: '/lens-upgrade --from 2 --to 3'
```

---

### Decision 6: Tombstone Retention Policy

**Decision: Permanent tombstones (no expiry)**

**Rationale:**
- Tombstones are the historical record that an initiative existed and why it ended
- Sensing must distinguish "active" from "closed" indefinitely; expiring tombstones recreates the ghost-work problem v3 is solving
- Storage cost is negligible (markdown files in git)

---

## 5. New Components: Detailed Design

### 5.1 `initiative-state.yaml` (New)

**Location:** `_bmad-output/planning-artifacts/initiatives/{initiative}/initiative-state.yaml`
*(exact path TBD in TechPlan; one file per initiative)*

**Full schema:**

```yaml
# Schema version matches lifecycle.yaml schema_version
schema_version: 3
initiative: foo-bar-auth
milestone: techplan           # current milestone branch token (from lifecycle.yaml audiences)
phase: businessplan           # current phase (from lifecycle.yaml phases list)
phase_status: in-progress     # in-progress | complete
lifecycle_status: active      # active | completed | abandoned | superseded
superseded_by: ~              # initiative slug (set when lifecycle_status == superseded)
lens_version: '3.0.0'        # module version at last write (for drift detection)
created: '2026-03-26'
last_updated: '2026-03-26'
artifacts:                    # committed artifact inventory (updated at each PHASE:COMPLETE)
  preplan:
    product-brief: 'product-brief-foo-bar-auth-2026-03-26.md'
  businessplan:
    prd: 'prd-foo-bar-auth-2026-03-26.md'
    architecture: 'architecture-foo-bar-auth-2026-03-26.md'
```

**Operations on `initiative-state.yaml`:**

| Operation | Trigger | Fields Updated |
|-----------|---------|----------------|
| `create-initiative-state` | First phase start (preplan) | All fields initialized |
| `update-phase-start` | Phase router step-01 | `phase`, `phase_status: in-progress`, `last_updated` |
| `update-phase-complete` | Phase router step-N complete | `phase_status: complete`, `artifacts.{phase}`, `last_updated` |
| `update-milestone-promote` | audience-promotion workflow | `milestone`, `phase`, `phase_status`, `last_updated` |
| `update-close` | `/close` workflow | `lifecycle_status`, `superseded_by` (if applicable), `last_updated` |
| `update-lens-upgrade` | `/lens-upgrade` | `schema_version`, `lens_version`, `last_updated` |

---

### 5.2 `/close` Workflow (New)

**Commands:**
- `/close --completed` — initiative reached its intended end state
- `/close --abandoned` — initiative was dropped without completion
- `/close --superseded-by {initiative}` — initiative replaced by a named successor

**Algorithm:**
1. Validate `initiative-state.yaml` exists and `lifecycle_status == active`
2. Prompt user for close reason (free text, stored in tombstone)
3. Generate tombstone markdown at `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md`
4. Push tombstone to governance repo (direct push)
5. Update `initiative-state.yaml`: set `lifecycle_status`, `superseded_by` (if applicable), `last_updated`
6. Commit `[CLOSE:{VARIANT}] {initiative} — {reason}` with updated state file
7. Push to current milestone branch
8. Output completion summary

**Tombstone format (exact fields deferred to TechPlan):**

```markdown
# Initiative Tombstone: {initiative}

**Closed:** {date}
**Status:** {completed | abandoned | superseded}
**Superseded By:** {initiative or N/A}
**Final Milestone:** {milestone name}
**Reason:** {user-provided reason}

## Artifact Summary
{list of committed artifacts with paths}
```

---

### 5.3 `/lens-upgrade` Workflow (New)

**Commands:**
- `/lens-upgrade` — apply migration from current `LENS_VERSION` to `lifecycle.yaml schema_version`
- `/lens-upgrade --dry-run` — preview all changes without applying

**Algorithm:**
1. Read `LENS_VERSION` from control repo root (current version)
2. Read `schema_version` from `lifecycle.yaml` (target version)
3. If versions match: report "already at current version"
4. Load migration descriptors from `lifecycle.yaml migrations` section for path `current → target`
5. Enumerate changes: field renames, branch renames, new fields
6. If `--dry-run`: display change list and exit
7. Apply field renames to `lifecycle.yaml`
8. Rename audience branches (git branch rename)
9. Update `initiative-state.yaml` files: `schema_version`, `lens_version`, milestone token if renamed
10. Write new `LENS_VERSION`
11. Commit `[LENS:UPGRADE] migrated from v{N} to v{M}` with all modified files

---

### 5.4 `sensing.md` Dual-Read (Updated)

**v3 sensing model:**

```
Pass 1 — Live conflicts (unchanged from v2):
  git branch --list              → active initiative branches
  extract domain/service tokens  → overlap detection

Pass 2 — Historical context (new in v3):
  git show governance:artifacts/{domain}/{service}/
  → list prior completed initiatives in same domain
  → load their artifact summaries if available
  → surface relevant prior decisions in sensing report

Graceful downgrade:
  if governance remote absent or artifacts/ path not found:
    proceed with branch-only sensing
    add note: "Governance artifact history unavailable (remote not configured)"
```

---

## 6. Files Changed in v3

### Modified Files

| File | Changes |
|------|---------|
| `lifecycle.yaml` | Rename audience tokens; add `artifact_publication`, `close_states`, `migrations`, `preflight_tiers` sections; bump `schema_version` to 3 |
| `skills/git-state.md` | Replace branch-suffix parsing and git-log grep with `initiative-state.yaml` YAML read; update `/switch` to enumerate YAML files |
| `skills/git-orchestration.md` | Remove Phase branch creation variant; update audience token validation to `lifecycle.yaml` lookup; add `publish-to-governance`, `update-initiative-state`, `create-initiative-state` operations; add `validate-branch-name` precondition to push |
| `skills/sensing.md` | Add governance dual-read pass; graceful downgrade if remote absent |
| `workflows/router/preplan/steps/*` | Remove create-phase-branch and PR steps; add `[PHASE:PREPLAN:START]` and `[PHASE:PREPLAN:COMPLETE]` commit marker steps |
| `workflows/router/businessplan/steps/*` | Same as preplan; add `initiative-state.yaml` atomic update |
| `workflows/router/techplan/steps/*` | Same pattern |
| `workflows/router/devproposal/steps/*` | Same pattern |
| `workflows/router/sprintplan/steps/*` | Same pattern |
| `workflows/router/audience-promotion/*` | Add `publish-to-governance` step after artifact validation |
| `setup-control-repo.sh` | Add `LENS_VERSION` initialization |
| `setup-control-repo.ps1` | Add `LENS_VERSION` initialization |

### New Files

| File | Purpose |
|------|---------|
| `workflows/router/close/` | `/close` router workflow (completed/abandoned/superseded) |
| `workflows/router/lens-upgrade/` | `/lens-upgrade` router workflow (migration descriptor execution) |
| `LENS_VERSION` (control repo) | Version binding file; written by setup and `/lens-upgrade` |
| `initiative-state.yaml` (per-initiative, control repo) | Runtime state; written by `git-orchestration.md` on every phase transition |

### Deleted Concepts (not files)

| Concept | Replacement |
|---------|-------------|
| Phase branches (`foo-bar-auth-small-preplan`, etc.) | Phase state in `initiative-state.yaml`; commit markers as audit trail |
| Audience-name tokens (`small`/`medium`/`large`/`base`) | Milestone-name tokens (`techplan`/`devproposal`/`sprintplan`/`dev-ready`) |
| Branch-name state parsing in `git-state.md` | `initiative-state.yaml` YAML read |
| `git log --grep` phase derivation | `initiative-state.yaml.phase` field |
| Branch enumeration in `/switch` | `initiative-state.yaml` file enumeration |

---

## 7. Migration Path (v2 → v3)

### Prerequisites

Before running `/lens-upgrade`:
1. All active phase branches should be merged into their audience branch (normal workflow completion)
2. Remnant unmerged phase branches will be listed by `--dry-run` and explicitly cleaned up by the upgrade

### Upgrade Steps

```
User: /lens-upgrade --dry-run
Agent: Shows proposed changes:
  - lifecycle.yaml: small → techplan, medium → devproposal, large → sprintplan, base → dev-ready
  - Branch renames: foo-bar-auth-small → foo-bar-auth-techplan, etc.
  - New fields added: artifact_publication, close_states, migrations
  - LENS_VERSION: "2" → "3.0.0"
  - initiative-state.yaml: created for each active initiative from existing branch state

User: /lens-upgrade
Agent: Applies all changes; commits [LENS:UPGRADE] migrated from v2 to v3.0.0
```

### Breaking Changes

1. All audience branch names change (rename, not recreate — git history preserved)
2. Phase branches eliminated (merged branches cleaned up; unmerged listed in `--dry-run`)
3. `[PHASE:]` commit message format changes from `[PREPLAN]` to `[PHASE:PREPLAN:COMPLETE]`
4. Any script parsing `small/medium/large/base` branch suffixes breaks

---

## 8. Open Decisions (Deferred to TechPlan)

| # | Decision | Options to Evaluate |
|---|----------|---------------------|
| 1 | Exact governance artifact directory structure | Flat per-initiative vs. phase-namespaced sub-dirs; artifact file versioning scheme |
| 2 | `[PHASE:X:COMPLETE]` commit marker artifact inventory format | Inline list in commit body vs. separate `artifact-manifest.yaml` committed alongside |
| 3 | `/close` tombstone file format and required fields | Minimal (initiative, close-type, date, reason) vs. richer (artifact links, superseded-by ref, phase summary) |
| 4 | `initiative-state.yaml` file path within control repo | Alongside planning artifacts vs. dedicated `initiatives/` directory |

---

## 9. Validation Checklist

- [ ] All 5 phase router workflows updated — no new phase branches created after v3
- [ ] `initiative-state.yaml` atomic commit verified: state file always changes in same commit as triggering event
- [ ] `/switch` confirmed to enumerate YAML files, not branch list
- [ ] `/status` confirmed to read `initiative-state.yaml` directly (measure: <1s response)
- [ ] `publish-to-governance` verified: artifacts appear in governance repo after promotion
- [ ] `/close --abandoned` verified: tombstone appears in governance, `lifecycle_status == abandoned`
- [ ] `/lens-upgrade --dry-run` verified: shows all changes without applying
- [ ] `/lens-upgrade` (apply) verified: branch renames + `lifecycle.yaml` field renames + `LENS_VERSION` update committed
- [ ] Preflight version mismatch verified: hard-stop message on `LENS_VERSION != schema_version`
- [ ] `sensing.md` graceful downgrade verified: branch-only mode when governance remote absent
