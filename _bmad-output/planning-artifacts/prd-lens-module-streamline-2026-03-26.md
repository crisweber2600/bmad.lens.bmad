---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
inputDocuments:
  - '_bmad-output/planning-artifacts/product-brief-lens-module-streamline-2026-03-26.md'
  - '_bmad-output/planning-artifacts/businessplan-questions-lens-module-streamline-2026-03-26.md'
  - '_bmad-output/planning-artifacts/research/technical-lens-work-streamline-research-2026-03-26.md'
  - '_bmad-output/planning-artifacts/research/domain-lens-work-architecture-research-2026-03-26.md'
workflowType: prd
batchMode: true
date: '2026-03-26'
author: '@lens'
initiative: lens-module-streamline
classification:
  projectType: internal_platform_tool
  domain: bmad_module_system
  complexity: medium
  projectContext: ground-up-rebuild
version: '3.0.0'
---

# Product Requirements Document — lens-work Module v3 (Streamline)

**Author:** @lens
**Date:** 2026-03-26
**Version:** 3.0.0
**Initiative:** lens-module-streamline

---

## Executive Summary

lens-work v2 is a working but structurally fragile planning workflow module. A single full-track initiative generates 9–11 git branches, encoding both audience scope and work phase in single branch names that require domain knowledge to decode. Completed phase artifacts are never published to the governance repo. Abandoned initiatives leave no trace — their branches register as active conflicts indefinitely. No `/close` command exists. No version protection exists: a v2 control repo running against a v3 module produces silent failures. These five structural problems compound as adoption grows.

lens-work v3 ("Streamline") resolves all five by replacing the audience-name branch tokens (`small`/`medium`/`large`/`base`) with semantic milestone names (`techplan`/`devproposal`/`sprintplan`/`dev-ready`), eliminating phase branches entirely in favor of a committed YAML state file (`initiative-state.yaml`) as the single source of truth for all runtime initiative state, introducing a `/close` command with permanent governance tombstone publication, adding `LENS_VERSION` preflight mismatch detection, and establishing automatic governance artifact publication at every audience promotion.

The result is 50% fewer branches, sub-second state reads (YAML file read replaces git-log scanning), richer cross-initiative awareness, and safe module upgrades via a declarative `/lens-upgrade` command with `--dry-run` support.

---

## Project Classification

- **Project Type:** Internal Platform / Infrastructure Tool (BMAD module)
- **Domain:** BMAD module system — lens-work planning workflow infrastructure
- **Complexity:** Medium — git topology, agent instruction-file architecture, migration path
- **Project Context:** Ground-up rebuild — architectural model fully replaced; files updated in-place

---

## Problem Statement

The lens-work v2 module suffers from five structural problems that compound as teams adopt it:

**1. Branch topology proliferation.** A single `full`-track initiative generates 9–11 branches. Developers regularly hit confusion about which branch is current and what each branch represents. Branch names (e.g., `foo-bar-auth-small-techplan`) dual-encode audience size (`small`) and work type (`techplan`) in one string, with no machine-readable schema separating the two.

**2. Governance repo underutilization.** The governance repo holds only constitutions. Completed phase artifacts — product briefs, architecture documents, PRDs — are never published there. The governance repo cannot answer "what did the payments-billing initiative decide for its tech stack?" without checking out the control repo.

**3. No initiative close command.** Abandoned initiatives leave branches forever. Sensing reads branch names to detect conflicts, so a ghost branch from 6 months ago reads as an "active" conflict for a new initiative in the same domain. There is no retrospective artifact, no tombstone, no audit trail of why the initiative ended.

**4. Zero version protection.** `lifecycle.yaml` has `schema_version: 2` but no consumption check exists. A v2 control repo running against a v3 module produces silent failures or corrupt state. There is no `/lens-upgrade` path.

**5. Slow, brittle state reads.** `git-state.md` derives current phase from branch name suffix parsing (brittle string split) or `git log --grep` scanning (O(N) across commit history). Both fail as branch names evolve or initiative history grows.

---

## Proposed Solution

Replace the v2 architectural model on three axes:

**Axis 1 — Branch topology.** Replace audience-name tokens with milestone names. Eliminate phase branches entirely. `foo-bar-auth-small-techplan` (branch) becomes `foo-bar-auth-techplan` (branch, self-describing) with phase history carried in `initiative-state.yaml` and `[PHASE:X:COMPLETE]` commit markers (audit trail only).

**Axis 2 — State model.** Introduce `initiative-state.yaml` as the single source of truth for all runtime initiative state. All state reads are a single YAML file read. The git branch name is a lookup key only — it identifies which YAML file to load; no state is parsed from the branch string itself.

**Axis 3 — Lifecycle completeness.** Add `/close` (completed/abandoned/superseded), governance artifact publication at every promotion, `LENS_VERSION` preflight, and `/lens-upgrade` with declarative migration descriptors.

---

## Target Users

### Primary: Solo IC Planner ("Alex")

**Role:** Engineer or tech lead who runs `@lens` planning independently before team review. Runs full-track initiatives frequently.

**Current pain:** 8+ confusing branches per initiative; can't distinguish active from abandoned; no historical context from sensing; accidentally continues on stale branches after fetch; `/status` requires reading branch names and PR state.

**v3 outcome:** 4 branches per initiative; `/status` reads `initiative-state.yaml` in milliseconds; `/switch` lists initiatives by name from YAML files, not by parsing branches; sensing surfaces prior governance artifacts on domain re-entry.

---

### Secondary: Team Lead / Adversarial Reviewer ("Jordan")

**Role:** Reviews initiatives at the `devproposal` stage. Pulls PRs, reads artifacts, approves or requests revisions.

**Current pain:** Branch names require domain knowledge to decode; no way to look up prior domain decisions without checking out a separate repo.

**v3 outcome:** PR from `foo-bar-auth-techplan` → `foo-bar-auth-devproposal` is self-describing. Governance artifacts from prior related initiatives surfaced at sensing time without a separate research step.

---

### Tertiary: Module Maintainer ("@lens module team")

**Role:** Evolves the `lens-work` module itself — adds phases, renames tokens, updates schemas.

**Current pain:** Any structural `lifecycle.yaml` change can silently break active initiatives. No migration tooling. Relies on out-of-band communication to notify teams.

**v3 outcome:** `/lens-upgrade --dry-run` previews all changes; control repos receive hard preflight errors on version mismatch; `/lens-upgrade` applies declarative migration descriptors automatically.

---

## User Journey Map

### Discovery to First Value (Alex)

| Step | Experience |
|------|------------|
| **Discovery** | Reads v3 release notes; sees branch count drops from 10 → 4. |
| **Onboarding** | Runs `/lens-upgrade --dry-run` on existing control repo; reviews proposed branch renames. Confirms; `LENS_VERSION` updated; branches renamed. |
| **First use** | Creates new initiative; sees 4 branches instead of 10 in `git branch`. `/status` reads `initiative-state.yaml` — instant response, no log scanning. |
| **Regular use** | At each promotion, governance artifacts publish automatically. Closes a stale initiative with `/close --abandoned`; tombstone written. Starts new initiative in same domain; sensing reads prior governance artifacts. |
| **Mastery** | Uses `git show governance:artifacts/{domain}/` to query prior decisions without checkout. Runs `/lens-upgrade --dry-run` ahead of module releases to preview impact. |

### Key Interaction Patterns

- All planning commands route through `@lens`; no direct git manipulation
- Phase state read from `initiative-state.yaml` (not branch names, not git log)
- Governance artifacts published at promotion without user ceremony
- `/switch` lists initiative options from YAML filenames; branch checkout is a side-effect of selection
- `/close` used when initiative completes, is abandoned, or is superseded by another

---

## Success Metrics

### User Success

| Metric | v2 Baseline | v3 Target |
|--------|-------------|-----------|
| Branches per full-track initiative | 9–11 | 4–5 |
| Time to determine current phase via `/status` | 30–60s (read branches + PR state) | <1s (YAML file read) |
| Historical decisions surfaced at sensing | 0 (branch names only) | Governance artifacts readable if published |
| Abandoned initiatives visible as distinct from active | 0% (no tombstones) | 100% (via `/close` + tombstone) |
| Version mismatch detection | 0% (undetected) | 100% at next write operation |

### Milestone Metrics (v3 rollout)

| Milestone | Signal |
|-----------|--------|
| Milestone naming adopted | `lifecycle.yaml` v3 merged; all audience tokens renamed |
| Phase branches eliminated | All phase router workflows updated; no new phase branches created |
| State model migrated | `initiative-state.yaml` written on every phase transition; `git-state.md` reads YAML |
| Governance publication enabled | First initiative completes a promotion with artifact in governance repo |
| `/close` command shipped | First initiative successfully closed with tombstone in governance |
| `/lens-upgrade` validated | At least one control repo successfully migrated from v2 to v3 |

---

## MVP Scope

### In Scope for v3.0

**1. `lifecycle.yaml` v3**
- Rename audience tokens: `small → techplan`, `medium → devproposal`, `large → sprintplan`, `base → dev-ready`
- Add `artifact_publication` section (governance root, enabled flag)
- Add `close_states` section (`completed`, `abandoned`, `superseded`)
- Add `migrations` section with v2→v3 migration descriptors
- Add `preflight_tiers` section (read-tier vs. write-tier commands)

**2. `initiative-state.yaml` — new committed state file**
- Created per-initiative on first phase start
- Fields: `initiative`, `milestone`, `phase`, `phase_status`, `lifecycle_status`, `superseded_by`, `last_updated`
- Updated atomically with every phase transition commit
- All state queries read this file; no branch-name parsing or git-log scanning

**3. `LENS_VERSION` file in control repo**
- Added to `setup-control-repo.sh` and `setup-control-repo.ps1`
- Preflight write-tier check validates `LENS_VERSION` against `lifecycle.yaml schema_version`

**4. `git-state.md` updates**
- Replace branch-suffix parsing and `git log --grep` state derivation with `initiative-state.yaml` YAML read
- `/switch`: enumerates `initiative-state.yaml` files (not branches) to list available initiatives
- Branch name is lookup key only — identifies which YAML file to load

**5. `git-orchestration.md` updates**
- Remove `Phase` branch creation variant entirely
- Update audience token validation to `lifecycle.yaml` lookup (not hardcoded)
- Add `publish-to-governance` operation (direct push)
- Add `update-initiative-state` operation (atomic YAML update on every phase transition)
- Update `commit-artifacts` to always include `initiative-state.yaml` in the commit

**6. Phase router step file updates (all 5 phases)**
- Remove "create phase branch" step
- Remove "open PR from phase branch → audience branch" step
- Add `[PHASE:X:START]` commit marker step (audit trail only) at phase start
- Add `[PHASE:X:COMPLETE]` commit marker + `initiative-state.yaml` atomic update at phase end

**7. `/close` command (new router workflow)**
- Variants: `--completed`, `--abandoned`, `--superseded-by {initiative}`
- Writes permanent tombstone to governance repo
- Updates `initiative-state.yaml` lifecycle_status field
- Commits `[CLOSE:{VARIANT}]` marker

**8. `audience-promotion` workflow update**
- After artifact validation: calls `publish-to-governance` for all phase artifacts
- PR source/target updated to milestone branch names

**9. `/lens-upgrade` command (new router workflow)**
- Reads current `LENS_VERSION`, targets `lifecycle.yaml schema_version`
- Applies migration descriptors (field renames, branch renames)
- Supports `--dry-run`
- Writes updated `LENS_VERSION` and commits

**10. `sensing.md` dual-read update**
- Live conflicts: branch topology (unchanged)
- Historical context: `git show governance:artifacts/{domain}/` (new)
- Graceful downgrade if governance remote absent

### Out of Scope for v3.0

| Feature | Rationale |
|---------|-----------|
| Per-initiative version pinning | Complexity vs. value unclear — defer to v3.1 |
| `/lens-upgrade` interactive conflict resolution | `--dry-run` + apply is sufficient |
| PR-based governance writes | Review gate is the milestone PR; direct push post-merge is appropriate |
| Multi-remote governance | Single governance remote assumed |
| Automated retrospective generation in `/close` | Template provided; content is user-generated |
| Audience promotion timeline visualizer | UX nice-to-have, not blocking |

---

## Functional Requirements

### Command / Interaction Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | `/close` command with `--completed`, `--abandoned`, `--superseded-by {initiative}` variants | Must-Have |
| FR-002 | `/lens-upgrade` command with `--dry-run` support and migration descriptor execution | Must-Have |
| FR-003 | `/status` reads phase and state directly from `initiative-state.yaml` — no branch suffix parsing, no git log grep | Must-Have |
| FR-004 | All planning write commands run preflight version check before execution | Must-Have |
| FR-005 | `/switch` lists available initiatives by enumerating `initiative-state.yaml` files; branch checkout is a side effect of selection, not the discovery mechanism | Must-Have |
| FR-006 | `/discover` and `/switch` are read-only; no preflight pull required | Should-Have |

### State & Data Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-010 | `initiative-state.yaml` created per-initiative on first phase start; updated atomically with every phase transition commit | Must-Have |
| FR-011 | `initiative-state.yaml` is the single source of truth for all runtime initiative state (milestone, phase, phase_status, lifecycle_status) | Must-Have |
| FR-012 | `[PHASE:{NAME}:{EVENT}]` commit markers retained as append-only audit trail; not the query path for current state | Must-Have |
| FR-013 | `LENS_VERSION` file in control repo root; value matches `lifecycle.yaml schema_version` | Must-Have |
| FR-014 | `lifecycle.yaml` v3 includes `schema_version`, `migrations`, `preflight_tiers`, `artifact_publication`, `close_states` sections | Must-Have |
| FR-015 | Tombstones are permanent — no expiry mechanism | Must-Have |

### Integration Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-020 | `publish-to-governance`: direct push to governance repo (not PR) | Must-Have |
| FR-021 | `sensing.md` reads `governance:artifacts/` for historical context via `git show` | Must-Have |
| FR-022 | `sensing.md` gracefully downgrades if governance remote is absent (informational note, no error) | Should-Have |
| FR-023 | `git-orchestration.md` `validate-branch-name` precondition on push (not just on create) | Should-Have |

### Governance / Compliance Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-030 | All phase artifacts published to governance at audience promotion | Must-Have |
| FR-031 | `/close` tombstone written to governance for all termination variants | Must-Have |
| FR-032 | `[PHASE:X:COMPLETE]` marker committed with artifact inventory at phase end (audit trail) | Must-Have |
| FR-033 | `git-orchestration.md` audience token validation sourced from `lifecycle.yaml` (not hardcoded) | Must-Have |

---

## Non-Functional Requirements

### Reliability

- **Availability:** N/A — local git-native tool; no service availability requirement
- **Error handling:** Preflight hard-stops on version mismatch. `publish-to-governance` fails loudly if governance remote absent. `/lens-upgrade --dry-run` must succeed before `--apply` is permitted.
- **Recovery:** All state is git-native and committed. Any interrupted operation can be retried or rolled back via standard git commands.

### Performance

- **State read:** `/status` and all state queries complete in <1s via `initiative-state.yaml` YAML read (not git log scanning)
- **Sensing latency:** Dual-read mode adds <2s latency over branch-only mode for governance artifact read
- **Throughput:** Per-initiative (no concurrency requirement)

### Security

- **Authentication:** Inherits git remote auth (SSH keys / HTTPS tokens); no new auth surface introduced
- **Authorization:** Governance write access controlled by git remote permissions (direct push model)
- **Secret management:** No secrets in artifacts; `LENS_VERSION` and `initiative-state.yaml` are non-sensitive
- **Data sensitivity:** Planning artifacts may contain internal design decisions; governance repo access should mirror control repo access policies

### Maintainability

- **Upgrade mechanism:** `/lens-upgrade` with migration descriptors in `lifecycle.yaml`
- **Config management:** `lifecycle.yaml` is the single config source; `schema_version` gates all reads
- **Observability:** `[PHASE:X:EVENT]` commit markers serve as the structured audit log; `git log --grep` is the history query interface

### Compatibility

- **Platforms:** Any environment with git; no OS-specific requirements
- **Version compatibility:** v3 module detects v2 control repos via `LENS_VERSION` mismatch; does not silently continue
- **Migration:** `/lens-upgrade` applies `lifecycle.yaml` migration descriptors; branch renames executed automatically; phase branches expected to be merged before migration

### Scalability

- **Scale model:** Multi-initiative, multi-team; governance repo is shared artifact store with no per-initiative storage limits
- **Multi-tenancy:** Each initiative is independent; governance artifacts namespaced under `artifacts/{domain}/{service}/` to prevent collision

---

## Feature Roadmap

| Phase | Features |
|-------|---------|
| **v3.0 — Streamline** | Milestone branches, `initiative-state.yaml` state model, phase commit markers (audit), governance publication, `/close`, `LENS_VERSION`, `/lens-upgrade`, `sensing` dual-read |
| **v3.1 — Cross-Initiative Query** | `/discover-context {domain}/{service}` synthesizes governance artifacts across completed initiatives; per-initiative version pinning (`lens_version:` in initiative YAML) |
| **v3.2 — Version Pinning** | Per-initiative `lens_version:` field; rolling upgrades across teams at different paces |
| **v3.3 — Governance Registry** | `governance:registry/initiatives.yaml` — machine-readable cross-repo initiative index; org-wide dashboards without control repo checkout |

---

## Open Questions

All architectural questions are resolved. The following items are deferred to /techplan for detailed specification:

1. Exact governance artifact directory structure under `artifacts/{domain}/{service}/` (flat vs. phase-namespaced; artifact file versioning)
2. Exact `[PHASE:X:COMPLETE]` commit marker format for artifact inventory (inline list in commit body vs. separate manifest file committed alongside)
3. `/close` tombstone file format and required fields (minimal: initiative, close-type, date, reason; or richer with artifact links and superseded-by ref)
