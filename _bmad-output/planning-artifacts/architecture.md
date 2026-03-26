---
initiative: lens-module-streamline
phase: techplan
version: '3.0.0'
status: APPROVED
date: '2026-03-26'
author: '@lens'
supersedes: architecture-lens-module-streamline-2026-03-26.md
openDecisionsResolved: [OD-1, OD-2, OD-3, OD-4]
---

# lens-work v3 — Architecture Document (Streamline)

**Author:** @lens
**Date:** 2026-03-26
**Version:** 3.0.0
**Initiative:** lens-module-streamline
**Status:** APPROVED
**Supersedes:** `architecture-lens-module-streamline-2026-03-26.md` (PROPOSAL)
**TechPlan revision:** All deferred open decisions (OD-1 through OD-4) resolved.

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

Total: 10 branches
```

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

Total: 5 branches (50% reduction)
```

**Milestone naming rationale:**
- `techplan` replaces `small` — describes the gate achieved, not the audience size
- `devproposal` replaces `medium` — self-documenting for reviewers
- `sprintplan` replaces `large` — stakeholder-legible
- `dev-ready` replaces `base` — describes the execution-ready state

**Phase tracking:** Phase history is recorded via `[PHASE:X:COMPLETE]` commit markers on the milestone branch (append-only audit trail) and via `initiative-state.yaml` (queryable runtime state). No phase branch is created.

### 2.2 State Model (New)

#### `initiative-state.yaml` — Single Source of Truth

A new committed YAML file, one per initiative, stored at `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml` (see Decision OD-4).

**Schema:**

```yaml
# initiative-state.yaml
schema_version: 3
initiative: foo-bar-auth          # initiative slug
milestone: techplan               # current milestone branch token
phase: businessplan               # current phase within milestone
phase_status: in-progress         # in-progress | complete
lifecycle_status: active          # active | completed | abandoned | superseded
superseded_by: ~                  # initiative slug if lifecycle_status == superseded
last_updated: '2026-03-26'
lens_version: '3.0.0'
created: '2026-03-26'
artifacts:                        # committed artifact inventory (updated at each PHASE:COMPLETE)
  preplan:
    product-brief: 'product-brief-foo-bar-auth-2026-03-26.md'
  businessplan:
    prd: 'prd-foo-bar-auth-2026-03-26.md'
  techplan:
    architecture: 'architecture.md'
    tech-decisions: 'tech-decisions.md'
```

**Read contract:** All state queries are a single `initiative-state.yaml` YAML read. No branch string parsing. No git log scanning. O(1) in all cases.

**Write contract:** `git-orchestration.md` `update-initiative-state` operation writes `initiative-state.yaml` and always includes it in the same commit as the triggering event (phase transition, close, upgrade). State and artifacts are atomically consistent at every commit boundary.

**Lookup contract:** The current git branch name is used as a lookup key to identify which initiative is active and therefore which `initiative-state.yaml` to read. The branch name is NOT parsed for structural state — it is only matched to the `initiative` field in the YAML.

#### `/switch` Discovery Model

`/switch` enumerates `initiative-state.yaml` files under `_bmad-output/lens-work/initiatives/` to list available initiatives. Branch checkout is a side effect of the user selecting an initiative by name — not the discovery mechanism.

#### Commit Markers (Audit Trail)

`[PHASE:{NAME}:{EVENT}]` commit markers remain as an append-only git log audit trail. They are never the state query path.

Format:
```
[PHASE:PREPLAN:COMPLETE] foo-bar-auth — preplan artifacts committed
[PHASE:BUSINESSPLAN:START] foo-bar-auth — businessplan phase started
[PHASE:BUSINESSPLAN:COMPLETE] foo-bar-auth — prd and architecture committed
[CLOSE:ABANDONED] foo-bar-auth — superseded by foo-bar-auth-v2
```

Inline artifact list in commit body (Decision OD-2 resolution — see Section 4):
```
[PHASE:TECHPLAN:COMPLETE] foo-bar-auth — techplan artifacts committed

Artifacts:
- architecture.md
- tech-decisions.md
```

### 2.3 Governance Publication (New)

At every audience promotion (milestone-branch PR merge), `git-orchestration.md` `publish-to-governance` runs a direct push of all phase artifacts to the governance repo.

**Governance artifact path structure (Decision OD-1 resolution — see Section 4):**

```
governance:
└── artifacts/
    └── {domain}/
        └── {service}/
            └── {initiative}/
                ├── product-brief.md
                ├── prd.md
                ├── architecture.md
                ├── tech-decisions.md
                └── _manifest.yaml      ← publication manifest (auto-generated)
```

**Tombstone path (Decision OD-3 resolution — see Section 5.2):**

```
governance:
└── tombstones/
    └── {domain}/
        └── {service}/
            └── {initiative}-tombstone.md
```

**Write model:** Direct push (not PR). Rationale: the artifact review gate is the milestone-branch PR. Once merged, artifacts are locked-in and propagate to governance without additional ceremony.

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
└── _bmad-output/
    ├── lens-work/
    │   └── initiatives/
    │       └── {domain}/
    │           └── {service}/
    │               └── {initiative}/
    │                   └── initiative-state.yaml    ← Per-initiative committed state (OD-4)
    └── planning-artifacts/
        ├── product-brief-{initiative}.md
        ├── prd-{initiative}.md
        ├── architecture.md
        ├── tech-decisions.md
        └── businessplan-questions-{initiative}.md
```

### 3.2 Component Dependencies

```
[phase router steps] → [git-orchestration.md]: commit-artifacts (atomic with YAML update), create-branch (milestone only)
[phase router steps] → [git-state.md]: read current phase, initiative, milestone level from YAML
[audience-promotion workflow] → [git-orchestration.md]: publish-to-governance, create next milestone branch
[/close workflow] → [git-orchestration.md]: publish-to-governance (tombstone), update-initiative-state
[/lens-upgrade workflow] → [lifecycle.yaml]: read migrations section; write updated lifecycle.yaml
[/lens-upgrade workflow] → [git-orchestration.md]: branch rename, LENS_VERSION update commit
[sensing.md] → [git-orchestration.md]: git show governance:artifacts/ (governance read)
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
| Governance repo | Module + user | `artifacts/{domain}/{service}/{initiative}/`, `tombstones/` |

---

## 4. Key Architectural Decisions

### Decision 1: Phase State Storage Model

**Decision: Committed YAML state file (`initiative-state.yaml`)**

| Option | Verdict |
|--------|---------|
| A. Git tags | Rejected — mutable (`git tag -f` replaces without trace) |
| B. Commit message markers | Rejected as primary state — O(N) log scan |
| C. Committed YAML state file | **Selected** |

**Rationale:** O(1) read, explicitly typed, human-readable, diff-able in PRs. Atomic commits via `git-orchestration.md` ensure state/artifact consistency at every commit boundary. Commit markers retained as append-only audit trail only.

---

### Decision 2: Branch Topology Redesign

**Decision: Milestone names + phase branches eliminated**

| Option | Verdict |
|--------|---------|
| A. Keep audience names; reduce phase branches only | Rejected — half-measure |
| B. Milestone names + phase branches eliminated | **Selected** |
| C. Keep current model; add phase-state YAML only | Rejected — does not improve branch topology |

**Rationale:** Milestone names (`techplan`/`devproposal`/`sprintplan`/`dev-ready`) are self-documenting without domain knowledge. 10 → 5 branches is the primary user-visible improvement.

---

### Decision 3: Governance Write Model

**Decision: Direct push (not PR)**

| Option | Verdict |
|--------|---------|
| A. PR-based governance writes | Rejected — redundant review gate |
| B. Direct push | **Selected** |

**Rationale:** The milestone-branch PR is the review gate. Once merged, artifacts are locked-in and propagate to governance without additional ceremony.

---

### Decision 4: Branch Naming Enforcement

**Decision: Agent-layer validation in `git-orchestration.md`**

| Option | Verdict |
|--------|---------|
| A. Git pre-receive/update hooks | Rejected — requires admin access, lifecycle.yaml duplication |
| B. Agent-layer validation in `git-orchestration.md` | **Selected** |

**Rationale:** `git-orchestration.md` is already the sole branch creation point. Dynamic validation against `lifecycle.yaml` milestone token list is maintainable. `validate-branch-name` precondition added to `push` and `create-branch`.

---

### Decision 5: YAML Schema Migration Pattern

**Decision: Migration descriptors in `lifecycle.yaml` + `/lens-upgrade` command**

| Option | Verdict |
|--------|---------|
| A. Helm-style migration descriptors in `lifecycle.yaml` | **Selected** |
| B. Separate migration script per version pair | Rejected — violates single-source-of-truth |
| C. Manual migration instructions only | Rejected — error-prone |

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

**Rationale:** Tombstones are the historical record that an initiative existed and why it ended. Sensing must distinguish "active" from "closed" indefinitely; expiring tombstones recreates the ghost-work problem v3 is solving. Storage cost is negligible.

---

### Decision OD-1 (RESOLVED): Governance Artifact Directory Structure

**Decision: Flat per-initiative directory; artifacts replaced atomically on re-publish**

| Option | Verdict |
|--------|---------|
| A. Flat per-initiative: `artifacts/{domain}/{service}/{initiative}/{artifact}.md` | **Selected** |
| B. Phase-namespaced: `artifacts/{domain}/{service}/{initiative}/{phase}/{artifact}.md` | Rejected |

**Rationale:**
- Governance artifacts represent the current approved state, not a historical archive. Git history on the governance repo is the audit trail for artifact evolution.
- Phase-namespaced subdirectories add two levels of nesting without a query benefit: consumers want "the latest approved architecture for initiative X," not "the techplan-phase architecture."
- A `_manifest.yaml` co-published alongside artifacts provides a lightweight index for tooling without requiring directory enumeration.

**Full path spec:**
```
governance:artifacts/
└── {domain}/
    └── {service}/
        └── {initiative}/
            ├── _manifest.yaml          ← auto-generated at publish time
            ├── product-brief.md
            ├── prd.md
            ├── architecture.md
            ├── tech-decisions.md
            └── ... (any additional phase artifacts)
```

**`_manifest.yaml` schema:**
```yaml
initiative: foo-bar-auth
domain: payments
service: auth
published_at: '2026-03-26T20:00:00Z'
milestone: techplan
lens_version: '3.0.0'
artifacts:
  - product-brief.md
  - prd.md
  - architecture.md
  - tech-decisions.md
```

---

### Decision OD-2 (RESOLVED): `[PHASE:X:COMPLETE]` Commit Marker Artifact Inventory Format

**Decision: Inline artifact list in commit body**

| Option | Verdict |
|--------|---------|
| A. Inline list in commit body | **Selected** |
| B. Separate `artifact-manifest.yaml` committed alongside | Rejected |

**Rationale:**
- The commit marker is an audit trail artifact. The authoritative machine-readable artifact inventory is already carried in `initiative-state.yaml.artifacts`. A second YAML file would be a redundant copy of that data.
- Inline commit body is human-readable without tooling, searchable with `git log --grep`, and adds zero artifact footprint.
- `initiative-state.yaml.artifacts` remains the programmatic read path.

**Commit body format:**
```
[PHASE:TECHPLAN:COMPLETE] {initiative} — techplan artifacts committed

Artifacts:
- architecture.md
- tech-decisions.md
```

---

### Decision OD-3 (RESOLVED): `/close` Tombstone File Format

**Decision: Rich tombstone with artifact summary, reason, and superseded-by reference**

| Option | Verdict |
|--------|---------|
| A. Minimal (initiative, close-type, date, reason) | Rejected — insufficient for cross-initiative sensing |
| B. Rich (+ artifact links, superseded-by ref, phase summary, final milestone) | **Selected** |

**Rationale:**
- Sensing uses tombstones to surface historical context. A minimal tombstone tells sensing "this initiative is closed." A rich tombstone tells sensing "this initiative produced these artifacts at these milestones, and was superseded by X."
- The additional fields (artifact links, final milestone, superseded-by) cost nothing to write at close time and prevent future "what was decided here?" research.

**Tombstone format (canonical):**
```markdown
# Initiative Tombstone: {initiative}

**Domain:** {domain}
**Service:** {service}
**Closed:** {ISO date}
**Status:** {completed | abandoned | superseded}
**Superseded By:** {initiative slug or N/A}
**Final Milestone:** {milestone name}
**Lens Version:** {version at close}
**Reason:** {user-provided reason text}

## Artifact Summary

| Phase | Artifact | Path |
|-------|----------|------|
| preplan | product-brief | product-brief-{initiative}.md |
| businessplan | prd | prd-{initiative}.md |
| techplan | architecture | architecture.md |
| techplan | tech-decisions | tech-decisions.md |

## Phase History

{inline git log excerpt of [PHASE:*] commit markers for this initiative}
```

---

### Decision OD-4 (RESOLVED): `initiative-state.yaml` File Path

**Decision: Dedicated `initiatives/` directory tree under `_bmad-output/lens-work/`**

| Option | Verdict |
|--------|---------|
| A. Alongside planning artifacts: `_bmad-output/planning-artifacts/initiative-state.yaml` | Rejected |
| B. Dedicated initiatives tree: `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml` | **Selected** |

**Rationale:**
- The `_bmad-output/lens-work/initiatives/` directory already exists as the convention for initiative config files (e.g., `initiative.yaml`, `streamline.yaml`). Co-locating `initiative-state.yaml` in the same namespaced directory is consistent and avoids a "root-level file per initiative" proliferation in `planning-artifacts/`.
- The domain/service/initiative path mirrors the governance artifact path, enabling consistent lookup keys across control and governance repos.
- `planning-artifacts/` is for human-readable output artifacts. `lens-work/initiatives/` is for machine-readable initiative metadata. Separation keeps authority domains clean (Axiom A4).

**Full path spec:**
```
_bmad-output/lens-work/initiatives/
└── {domain}/
    └── {service}/
        └── {initiative}/
            └── initiative-state.yaml
```

**Example (this initiative):**
```
_bmad-output/lens-work/initiatives/lens/module/streamline/initiative-state.yaml
```

---

## 5. New Components: Detailed Design

### 5.1 `initiative-state.yaml` (New)

**Location:** `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml`

**Full schema:**

```yaml
schema_version: 3
initiative: foo-bar-auth
domain: payments
service: auth
feature: ~                    # if scope == feature
milestone: techplan           # current milestone branch token
phase: businessplan           # current phase
phase_status: in-progress     # in-progress | complete
lifecycle_status: active      # active | completed | abandoned | superseded
superseded_by: ~
lens_version: '3.0.0'
created: '2026-03-26'
last_updated: '2026-03-26'
artifacts:
  preplan:
    product-brief: 'product-brief-foo-bar-auth-2026-03-26.md'
  businessplan:
    prd: 'prd-foo-bar-auth-2026-03-26.md'
  techplan:
    architecture: 'architecture.md'
    tech-decisions: 'tech-decisions.md'
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
3. Generate tombstone markdown at `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md` using the rich format from Decision OD-3
4. Push tombstone to governance repo (direct push)
5. Update `initiative-state.yaml`: set `lifecycle_status`, `superseded_by`, `last_updated`
6. Commit `[CLOSE:{VARIANT}] {initiative} — {reason}` with updated state file
7. Push to current milestone branch
8. Output completion summary

---

### 5.3 `/lens-upgrade` Workflow (New)

**Commands:**
- `/lens-upgrade` — apply migration from current `LENS_VERSION` to `lifecycle.yaml schema_version`
- `/lens-upgrade --dry-run` — preview all changes without applying

**Algorithm:**
1. Read `LENS_VERSION` from control repo root
2. Read `schema_version` from `lifecycle.yaml`
3. If versions match: report "already at current version"
4. Load migration descriptors from `lifecycle.yaml migrations`
5. If `--dry-run`: display change list and exit
6. Apply field renames to `lifecycle.yaml`
7. Rename audience branches (git rename)
8. Update `initiative-state.yaml` files: `schema_version`, `lens_version`, milestone token if renamed
9. Write new `LENS_VERSION`
10. Commit `[LENS:UPGRADE] migrated from v{N} to v{M}` with all modified files

---

### 5.4 `sensing.md` Dual-Read (Updated)

```
Pass 1 — Live conflicts (unchanged from v2):
  git branch --list              → active initiative branches
  extract domain/service tokens  → overlap detection

Pass 2 — Historical context (new in v3):
  git show governance:artifacts/{domain}/{service}/
  → list prior completed initiatives in same domain/service
  → load _manifest.yaml for each → surface prior decisions in sensing report

Graceful downgrade:
  if governance remote absent or artifacts/ path not found:
    proceed with branch-only sensing
    note: "Governance artifact history unavailable (remote not configured)"
```

---

## 6. Files Changed in v3

### Modified Files

| File | Changes |
|------|---------|
| `lifecycle.yaml` | Rename audience tokens; add `artifact_publication`, `close_states`, `migrations`, `preflight_tiers`; bump `schema_version` to 3 |
| `skills/git-state.md` | Replace branch-suffix parsing with `initiative-state.yaml` YAML read; update `/switch` to enumerate YAML files under `_bmad-output/lens-work/initiatives/` |
| `skills/git-orchestration.md` | Remove phase branch creation variant; add `publish-to-governance`, `update-initiative-state`, `create-initiative-state` ops; add `validate-branch-name` precondition to push |
| `skills/sensing.md` | Add governance dual-read pass; graceful downgrade if remote absent |
| `workflows/router/preplan/steps/*` | Remove create-phase-branch and PR steps; add `[PHASE:PREPLAN:START/COMPLETE]` markers |
| `workflows/router/businessplan/steps/*` | Same; add `initiative-state.yaml` atomic update |
| `workflows/router/techplan/steps/*` | Same pattern |
| `workflows/router/devproposal/steps/*` | Same pattern |
| `workflows/router/sprintplan/steps/*` | Same pattern |
| `workflows/router/audience-promotion/*` | Add `publish-to-governance` step after artifact validation |
| `setup-control-repo.sh` | Add `LENS_VERSION` initialization |
| `setup-control-repo.ps1` | Add `LENS_VERSION` initialization |

### New Files

| File | Purpose |
|------|---------|
| `workflows/router/close/` | `/close` router workflow |
| `workflows/router/lens-upgrade/` | `/lens-upgrade` router workflow |
| `LENS_VERSION` (control repo) | Version binding; written by setup and `/lens-upgrade` |
| `initiative-state.yaml` (per-initiative, control repo) | Runtime state; written by `git-orchestration.md` |
| `governance:artifacts/{domain}/{service}/{initiative}/_manifest.yaml` | Publication manifest; written at promotion |

### Deleted Concepts

| Concept | Replacement |
|---------|-------------|
| Phase branches (`foo-bar-auth-small-preplan`, etc.) | Phase state in `initiative-state.yaml`; commit markers as audit trail |
| Audience-name tokens (`small/medium/large/base`) | Milestone-name tokens (`techplan/devproposal/sprintplan/dev-ready`) |
| Branch-name state parsing | `initiative-state.yaml` YAML read |
| `git log --grep` phase derivation | `initiative-state.yaml.phase` field |
| Branch enumeration in `/switch` | `initiative-state.yaml` file enumeration |

---

## 7. Migration Path (v2 → v3)

### Prerequisites

Before running `/lens-upgrade`:
1. All active phase branches should be merged into their audience branch
2. Remnant unmerged phase branches listed by `--dry-run` and explicitly cleaned up

### Upgrade Steps

```
User: /lens-upgrade --dry-run
Agent: Shows proposed changes:
  - lifecycle.yaml: small → techplan, medium → devproposal, large → sprintplan, base → dev-ready
  - Branch renames: foo-bar-auth-small → foo-bar-auth-techplan, etc.
  - New fields: artifact_publication, close_states, migrations
  - LENS_VERSION: "2" → "3.0.0"
  - initiative-state.yaml: created for each active initiative from existing branch state

User: /lens-upgrade
Agent: Applies all changes; commits [LENS:UPGRADE] migrated from v2 to v3.0.0
```

### Breaking Changes

1. All audience branch names change (rename, not recreate — git history preserved)
2. Phase branches eliminated (merged branches cleaned up; unmerged listed in `--dry-run`)
3. `[PHASE:]` commit message format changes
4. Any script parsing `small/medium/large/base` branch suffixes breaks

---

## 8. Implementation Scope

All 4 previously open decisions are resolved. Implementation is ready to proceed.

| # | Decision | Resolution |
|---|----------|------------|
| OD-1 | Governance artifact directory structure | Flat per-initiative; `_manifest.yaml` co-published |
| OD-2 | Commit marker artifact inventory format | Inline list in commit body |
| OD-3 | `/close` tombstone format | Rich tombstone (artifact links, reason, phase history) |
| OD-4 | `initiative-state.yaml` file path | `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml` |

---

## 9. Validation Checklist

- [ ] All 5 phase router workflows updated — no new phase branches created after v3
- [ ] `initiative-state.yaml` atomic commit verified: state file always changes in same commit as triggering event
- [ ] `/switch` confirmed to enumerate YAML files under `_bmad-output/lens-work/initiatives/`, not branch list
- [ ] `/status` confirmed to read `initiative-state.yaml` directly (measure: <1s response)
- [ ] `publish-to-governance` verified: artifacts appear in `governance:artifacts/{domain}/{service}/{initiative}/` after promotion
- [ ] `_manifest.yaml` verified: generated and pushed at every milestone promotion
- [ ] `/close --abandoned` verified: rich tombstone appears in governance; `lifecycle_status == abandoned`
- [ ] `/lens-upgrade --dry-run` verified: shows all changes without applying
- [ ] `/lens-upgrade` (apply) verified: branch renames + `lifecycle.yaml` field renames + `LENS_VERSION` update committed
- [ ] Preflight version mismatch verified: hard-stop on `LENS_VERSION != schema_version`
- [ ] `sensing.md` graceful downgrade verified: branch-only mode when governance remote absent
- [ ] Rich tombstone query verified: sensing reads `_manifest.yaml` from governance for historical context
