---
initiative: lens-module-streamline
phase: techplan
version: '3.0.0'
status: APPROVED
date: '2026-03-26'
author: '@lens'
---

# Technical Decisions — lens-work v3 (Streamline)

**Author:** @lens
**Date:** 2026-03-26
**Version:** 3.0.0
**Initiative:** lens-module-streamline
**Status:** APPROVED

This document records the binding technical decisions for the lens-work v3 Streamline initiative. Each decision follows the ADR (Architecture Decision Record) format: context, options evaluated, selection, and consequences.

---

## TD-01: Runtime State Storage

**Status:** APPROVED
**Supersedes:** v2 design (branch-name suffix parsing + `git log --grep`)

### Context

v2 derives all runtime lifecycle state from two brittle sources:
- Branch name suffix parsing (e.g., `-small-techplan` split by hyphens)
- `git log --grep` scanning for `[PHASE:X]` commit messages (O(N))

Both fail silently on non-standard branch names and degrade as initiative history grows.

### Decision

Use a committed YAML file (`initiative-state.yaml`) as the single runtime state store.
- Location: `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml`
- All state fields explicitly typed in YAML schema
- Written atomically by `git-orchestration.md` on every phase transition
- Read path: direct YAML file read (O(1), no git log access)

### Consequences

- **Positive:** O(1) state reads, explicit schema, diff-able in PRs, no parse brittleness
- **Positive:** `/switch`, `/status`, `/next` all read from YAML — response time is sub-second
- **Negative:** A new committed file per initiative (negligible storage cost)
- **Mitigation:** `git-orchestration.md` enforces atomic writes — state cannot drift from artifact reality

---

## TD-02: Branch Topology

**Status:** APPROVED
**Supersedes:** v2 10-branch topology (audience × phase matrix)

### Context

v2 creates 9–11 branches per full-track initiative: one root, multiple audience branches (`small`/`medium`/`large`/`base`), and one phase branch per phase per audience. Developers frequently work on the wrong branch; branch lists are unreadable; audience-name tokens (`small`, `medium`) require domain knowledge.

### Decision

Replace all audience-name tokens with semantic milestone names. Eliminate phase branches entirely.

**v3 branch topology per full-track initiative:**
- `{initiative-root}` — root branch (PR target for initial setup)
- `{initiative-root}-techplan` — milestone branch (preplan + businessplan + techplan)
- `{initiative-root}-devproposal` — milestone branch (devproposal)
- `{initiative-root}-sprintplan` — milestone branch (sprintplan)
- `{initiative-root}-dev-ready` — milestone branch (execution-ready)

Total: **5 branches** (reduced from 10).

Phase progress tracked via `initiative-state.yaml.phase` + `[PHASE:X:COMPLETE]` commit markers.

### Consequences

- **Positive:** 50% branch reduction; self-documenting names; no audience-size decoding required
- **Positive:** Branch list is human-readable without domain knowledge
- **Negative:** `lifecycle.yaml schema_version` must bump to 3; migration required for existing v2 repos
- **Mitigation:** `/lens-upgrade` command applies migration declaratively with `--dry-run` preview

---

## TD-03: Governance Artifact Publication

**Status:** APPROVED

### Context

v2's governance repo holds only constitutions. Planning artifacts — PRDs, architecture docs, tech decisions — are never published. Teams wanting to query prior domain decisions must check out the control repo for each initiative of interest. Sensing cannot surface historical context for new initiatives entering a previously-worked domain.

### Decision

Publish all phase artifacts to the governance repo at every milestone-branch PR merge, via `git-orchestration.md` `publish-to-governance` operation.

**Path structure:**
```
governance:artifacts/{domain}/{service}/{initiative}/
├── _manifest.yaml        ← auto-generated publication manifest
├── product-brief.md
├── prd.md
├── architecture.md
├── tech-decisions.md
└── ... (any additional artifacts)
```

Write model: **direct push** (not PR). The milestone-branch PR is the review gate; governance publication is a consequence of merge, not a separate review step.

**`_manifest.yaml`** is auto-generated at publish time and contains: initiative, domain, service, published_at, milestone, lens_version, artifact list.

### Consequences

- **Positive:** Governance repo becomes queryable for historical artifact context
- **Positive:** Sensing gains a historical pass (dual-read architecture)
- **Positive:** Teams can query "what was the architecture for {X}" from governance without cloning control repo
- **Negative:** Direct push architecture requires `publish-to-governance` authority to be strictly controlled in `git-orchestration.md`
- **Mitigation:** `publish-to-governance` is a dedicated operation with explicit path validation; it writes only to `governance:artifacts/` and `governance:tombstones/`

---

## TD-04: Initiative Close Command

**Status:** APPROVED

### Context

v2 has no `/close` command. Abandoned initiatives leave branches permanently. `sensing.md` reads branch names to detect conflicts, so an abandoned branch from months ago registers as an "active" conflict for new initiatives in the same domain/service. There is no retrospective artifact and no audit trail for why an initiative ended.

### Decision

Introduce `/close` with three variants: `--completed`, `--abandoned`, `--superseded-by {initiative}`.

**Algorithm:**
1. Validate `initiative-state.yaml` exists with `lifecycle_status == active`
2. Prompt user for reason text
3. Generate rich tombstone at `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md`
4. Push tombstone directly to governance repo
5. Update `initiative-state.yaml`: `lifecycle_status`, `superseded_by`, `last_updated`
6. Commit `[CLOSE:{VARIANT}] {initiative} — {reason}` atomically with state file

**Rich tombstone includes:** domain, service, final milestone, reason, artifact summary table, phase history (git log excerpt of `[PHASE:*]` markers).

### Consequences

- **Positive:** Sensing can distinguish active from closed initiatives without ghost-work false positives
- **Positive:** Historical record of initiative lifecycle for every domain/service
- **Positive:** `/close --superseded-by` creates explicit successor chain
- **Negative:** User must call `/close` explicitly; dead branches from pre-v3 work still exist until upgrade
- **Mitigation:** `/lens-upgrade` reports unmerged phase branches as part of its dry-run output

---

## TD-05: Version Safety and Module Upgrade Path

**Status:** APPROVED

### Context

v2 has no `LENS_VERSION` file and no preflight version check. A v2 control repo running against a v3 module fails silently (renamed fields produce undefined behavior). No assisted migration path exists.

### Decision

**Part A — `LENS_VERSION` file:** A `LENS_VERSION` file in the control repo root (e.g., `3.0.0`). Written by `setup-control-repo.sh`/`.ps1` and by `/lens-upgrade`.

**Part B — Preflight version check (write-tier commands):** All write-tier commands (phase routers, `/promote`, `/close`) check `LENS_VERSION` against `lifecycle.yaml schema_version`. Mismatch → HARD STOP with message: `"VERSION MISMATCH: control repo is v{X}, module expects v{Y}. Run /lens-upgrade."`

**Part C — `/lens-upgrade` command:** Reads migration descriptors from `lifecycle.yaml migrations` section and applies them declaratively. Supports `--dry-run`. Commits `[LENS:UPGRADE] migrated from v{N} to v{M}`.

**Migration descriptor schema** (`lifecycle.yaml`):
```yaml
migrations:
  - from_version: 2
    to_version: 3
    breaking: true
    changes:
      - type: rename_field   # rename audience token keys
      - type: add_field      # add artifact_publication, close_states
    branch_rename_required: true
    migration_command: '/lens-upgrade --from 2 --to 3'
```

### Consequences

- **Positive:** Module updates can no longer silently corrupt control repos
- **Positive:** `/lens-upgrade --dry-run` gives a safe preview before applying
- **Negative:** v2 control repos hitting v3 module get a hard stop instead of proceeding; users must run the upgrade
- **Mitigation:** Error message is explicit and actionable; `--dry-run` removes fear of running the upgrade

---

## TD-06: State Read Performance

**Status:** APPROVED

### Context

`git-state.md` in v2 uses two performance-degrading read patterns:
1. `git branch --list` + hyphen-split to extract audience/phase tokens
2. `git log --grep "[PHASE:X]"` to find the most recent phase event (O(N) with history)

As initiative history grows, `/status` response degrades.

### Decision

Replace all state reads with a direct `initiative-state.yaml` YAML file read. The state file is always at a known path (derived from `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml`). No git operations required for state queries.

**Lookup chain:**
1. Read current branch name (O(1))
2. Match branch name to initiative root (strip milestone suffix)
3. Derive YAML path from initiative root name
4. Load and return YAML fields

**Read-tier commands** (`/status`, `/discover`, `/next`, `/switch`) require no git pull — they read committed YAML directly.

### Consequences

- **Positive:** Sub-second `/status` regardless of initiative history length
- **Positive:** All state fields explicitly typed and human-readable
- **Negative:** State reads require a correct `initiative-state.yaml` to be present (enforced by write-tier commands at phase start)
- **Mitigation:** Missing `initiative-state.yaml` produces a clear error: `"No initiative-state.yaml found. Run /preplan to start a new initiative."`

---

## TD-07: Sensing Architecture (Dual-Read)

**Status:** APPROVED

### Context

v2 sensing scans only live branches for domain/service conflicts. It has no awareness of closed initiatives (ghost-work) and no access to historical artifacts from prior completed initiatives working in the same domain.

### Decision

Upgrade sensing to a dual-read model:

**Pass 1 — Live conflicts (unchanged):**
- `git branch --list` → active milestone branches
- Extract domain/service from `initiative-state.yaml` for each active branch
- Report overlap conflicts

**Pass 2 — Historical context (new in v3):**
- `git show governance:artifacts/{domain}/{service}/` → list prior initiatives in same domain/service
- Load `_manifest.yaml` for each → surface artifact metadata in sensing report
- Graceful downgrade: if governance remote absent, proceed with branch-only mode

**Sensing report output:**
```
Active conflicts: [list]
Historical context:
  - {prior-initiative}: {milestone}, closed {date}, artifacts: [prd.md, architecture.md]
Governance note: Prior architecture at governance:artifacts/{domain}/{service}/{initiative}/architecture.md
```

### Consequences

- **Positive:** Teams entering a domain with prior initiative history see relevant decisions surfaced automatically
- **Positive:** Ghost-work false positives eliminated (closed initiatives write tombstones; branches remain but `lifecycle_status != active` is checked)
- **Negative:** Pass 2 requires governance remote to be configured; absent remote produces advisory note, not failure
- **Mitigation:** Graceful downgrade is implemented in `sensing.md`; no hard dependency on governance remote for Pass 1

---

## TD-08: Agent Architecture (No Change)

**Status:** APPROVED — no architectural change from v2

### Context

v2's `@lens` agent architecture — single agent, 5 skills, step-file router workflows — is well-designed and does not need replacement.

### Decision

Retain the v2 agent architecture. All v3 changes are confined to:
- `lifecycle.yaml` updates (schema, migrations, preflight tiers)
- Skill updates (`git-state.md`, `git-orchestration.md`, `sensing.md`)
- Phase router step file updates (remove phase-branch creation; add YAML state writes)
- Two new router workflows (`/close`, `/lens-upgrade`)

No changes to agent personas, skill count, command surface, or step-file architecture pattern.

### Consequences

- **Positive:** No retraining or reconceptualizing of the agent layer
- **Positive:** v3 changes are incremental; no "replace everything" risk
- **Positive:** Existing `batch-process.md` skill applies without modification to v3 phases

---

## Decision Index

| ID | Title | Status |
|----|-------|--------|
| TD-01 | Runtime State Storage | APPROVED |
| TD-02 | Branch Topology | APPROVED |
| TD-03 | Governance Artifact Publication | APPROVED |
| TD-04 | Initiative Close Command | APPROVED |
| TD-05 | Version Safety and Module Upgrade Path | APPROVED |
| TD-06 | State Read Performance | APPROVED |
| TD-07 | Sensing Architecture (Dual-Read) | APPROVED |
| TD-08 | Agent Architecture (No Change) | APPROVED |
