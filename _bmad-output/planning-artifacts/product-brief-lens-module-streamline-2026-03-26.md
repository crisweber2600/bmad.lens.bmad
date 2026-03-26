---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-26-001.md'
  - '_bmad-output/planning-artifacts/research/domain-lens-work-architecture-research-2026-03-26.md'
  - '_bmad-output/planning-artifacts/research/technical-lens-work-streamline-research-2026-03-26.md'
date: '2026-03-26'
author: '@lens'
---

# Product Brief: lens-work Module v3 — Streamline

**Initiative:** lens-module-streamline
**Track:** full
**Phase:** PrePlan
**Date:** 2026-03-26

---

## Executive Summary

The `lens-work` BMAD module today has a working but fragile v2 architecture where too much state is encoded in branch names, phase completion creates up to 11 branches per initiative, no `/close` command exists, and the governance repo is nearly empty despite being the intended system of record. Initiatives can run for months and leave no trace when abandoned. Version mismatches between control repos and the module go undetected.

`lens-module-streamline` (v3) replaces the audience-name branch tokens with semantic milestone names, eliminates phase branches entirely in favor of commit-tagged phase markers, introduces a `/close` command with governance tombstone publication, adds `LENS_VERSION` preflight mismatch detection, and establishes a governance artifact publication path at every phase promotion. The result is 50% fewer branches, richer cross-initiative awareness, and safe module upgrades.

---

## Core Vision

### The Problem

The lens-work v2 module suffers from five structural problems that compound as more teams adopt it:

**1. Branch topology proliferation.** A single `full`-track initiative generates 9–11 branches. Developers routinely hit confusion about which branch is "current" and what each branch represents. Phase branches (e.g., `foo-bar-auth-small-techplan`) have a dual-encoding problem: `small` (audience size) and `techplan` (work type) are both encoded in one branch name without clear semantics.

**2. Governance repo underutilization.** The governance repo holds only constitutions. Completed phase artifacts — product briefs, architecture documents, PRDs — are never published there. The governance repo cannot answer "what did the payments-billing initiative decide for its tech stack?" without checkout of the control repo.

**3. No initiative close command.** Abandoned initiatives leave branches forever. Sensing reads branch names to detect conflicts, so an abandoned branch from 6 months ago reads as an "active" conflict for a new initiative in the same domain. There is no retrospective artifact, no tombstone, no audit trail.

**4. Zero version protection.** `lifecycle.yaml` has `schema_version: 2` but no consumption check exists. A control repo initialized with v2 configs running against a v3 module would produce silent failures or corrupt state. There is no `/lens-upgrade` path.

**5. Sensing reads branches only.** Cross-initiative awareness is limited to branch name overlap detection. A new initiative in the same service has no way to learn what architectural decisions a previously-completed initiative made. Governance artifacts would enable this, but none are published.

### The Solution

Replace two architectural concepts:

**Old:** Audiences encode review scope (small/medium/large/base) and phases branch off audience branches.
**New:** Milestone branches encode lifecycle gates achieved (techplan/devproposal/sprintplan/dev-ready) and phases are commit events on the milestone branch.

Combine with:
- Governance artifact publication at every audience promotion
- `/close` command (completed / abandoned / superseded) that writes a tombstone to governance
- `LENS_VERSION` file in control repo + preflight mismatch detection
- `/lens-upgrade` declarative migration command

### Unique Value Proposition

`lens-work v3` is the first version where:
- **The branch name tells you what lifecycle gate was achieved**, not just "who was reviewing"
- **An initiative's history is readable from one branch** via `git log --grep=[PHASE:`
- **The governance repo is a live artifact store**, queryable by any agent without checking out the control repo
- **Abandoned work leaves a trace**, preventing future initiatives from conflicting with ghost work
- **Module upgrades are safe and announced** — the preflight catches version mismatches before damage occurs

---

## Target Users

### Primary: The Solo IC Planner ("Alex")

**Context:** Alex is an engineer or tech lead who uses `@lens` to do planning work on their own before bringing it to the team. They run `full`-track initiatives from preplan through techplan frequently.

**Current experience:** Alex regularly has 8+ branches in their control repo from multiple in-flight initiatives. They can't tell which branches are active vs. abandoned without reading git log. They've accidentally continued work on a stale branch after a fetch. When starting a new initiative in a domain they've worked in before, sensing gives no historical context — just "branch exists" warnings.

**v3 experience:** Alex's control repo has 4 branches per initiative instead of 10. `git branch` output is readable. `@lens /status` shows phase history from commit log without needing to trace PR state. When a new initiative starts in a domain with governance artifacts, sensing reads them and surfaces relevant prior decisions.

---

### Secondary: The Team Lead / Adversarial Reviewer ("Jordan")

**Context:** Jordan reviews initiatives at the `devproposal` (was: medium) stage. They pull PRs, read artifacts, and either approve or send back for revision.

**Current experience:** Jordan often can't tell what phase an initiative is in without reading branch names carefully. `foo-bar-auth-medium-devproposal` tells them audience and phase but requires knowledge that `medium` means "adversarial review stage." Jordan has no tool to check "what related work has been done in this domain before?"

**v3 experience:** The PR from `foo-bar-auth-techplan` → `foo-bar-auth-devproposal` is self-describing. Governance artifacts from prior related initiatives are queryable at sensing time, giving Jordan context without a separate research step.

---

### Tertiary: The Module Maintainer ("@lens module team")

**Context:** The team who maintains `lens-work` itself needs to safely evolve the module — add new phases, rename audiences, add fields — without breaking control repos in mid-flight.

**Current experience:** Any structural change to `lifecycle.yaml` risks breaking active initiatives silently. No migration tooling exists. The team has to rely on communication (Slack, docs) to tell teams "please re-initialize your control repo."

**v3 experience:** The module ships with `schema_version: 3`, migration descriptors, and preflight checks. Any control repo running a v2 config gets a clear error at the next write command and is directed to `/lens-upgrade`. Dry-run mode shows exactly what `/lens-upgrade` would change.

---

## Success Metrics

### User Success Metrics

| Metric | Baseline (v2) | Target (v3) |
|---|---|---|
| Branches per full-track initiative | 9–11 | 4–5 |
| Time to answer "what phase is this initiative in?" | 30–60s (read branch names, check PR state) | <5s (`git log --grep=[PHASE:` one-liner or `/status`) |
| Historical decisions surfaced at sensing | 0 (branch names only) | Governance artifacts readable if published |
| Abandoned initiatives visible as distinct from active | 0% (no tombstones) | 100% (close command + tombstone) |
| Version mismatch detection | 0% (undetected) | 100% at next write operation |

### Milestone Metrics (v3 rollout)

| Milestone | Signal |
|---|---|
| Milestone naming adopted | `lifecycle.yaml` v3 merged, all audience tokens renamed |
| Phase branches eliminated | All phase router workflows updated; no new phase branches created |
| Governance publication enabled | First initiative completes a promotion with artifact in governance repo |
| `/close` command shipped | First initiative successfully closed with tombstone in governance |
| `/lens-upgrade` validated | At least one control repo successfully migrated from v2 to v3 using the command |

---

## MVP Scope

### In Scope for v3.0

**1. `lifecycle.yaml` v3**
- Rename audience tokens: `small → techplan`, `medium → devproposal`, `large → sprintplan`, `base → dev-ready`
- Add `artifact_publication` section (governance root, enabled flag)
- Add `close_states` section (`completed`, `abandoned`, `superseded`)
- Add `migrations` section with v2→v3 migration descriptors
- Add `preflight_tiers` section (read vs. write weight)
  - **Read (lightweight — no pull required):** `/status`, `/discover`, `/next`, `/switch`
  - **Write (full — pull + validate):** `/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/promote`, `/close`, `/lens-upgrade`

**2. `LENS_VERSION` file in control repo**
- Add to `setup-control-repo.sh` and `setup-control-repo.ps1`
- Preflight write-tier check reads and validates against `lifecycle.yaml schema_version`

**3. `git-state.md` updates**
- Update branch name parsing from `(small|medium|large|base)` to milestone name list (lifecycle.yaml-sourced)
- Update `current-phase` derivation: from branch suffix parsing → `git log --grep=[PHASE:` scan on current branch
- Remove `phase-status(phase)` PR query (phase branches no longer exist)

**4. `git-orchestration.md` updates**
- Remove `Phase` branch creation variant entirely
- Update audience token validation to lifecycle.yaml lookup
- Add `publish-to-governance` operation
- Update `commit-artifacts` commit message format to `[PHASE:{NAME}:{EVENT}]`

**5. Phase router step file updates (all 5 phases)**
- Remove "create phase branch" step
- Add "`[PHASE:X:START]` commit marker" step at phase start
- Remove "open PR from phase branch → audience branch" step
- Add "`[PHASE:X:COMPLETE]` commit marker + artifact inventory" step at phase end

**6. `/close` command (new router workflow)**
- Variants: `--completed`, `--abandoned`, `--superseded-by {root}`
- Side effects: tombstone written to governance (permanent — no expiry), phase branches cleaned up (if any remnant from v2), audience branches retained for archival reads, `CLOSE` marker committed

**7. `audience-promotion` workflow update**
- After artifact validation: call `publish-to-governance` for all phase artifacts
- Update PR source/target to milestone branch names

**8. `/lens-upgrade` command (new router workflow)**
- Reads current `LENS_VERSION`, targets `lifecycle.yaml schema_version`
- Applies migration descriptors (field renames, branch renames)
- Supports `--dry-run`
- Writes updated `LENS_VERSION` and commits

**9. `sensing.md` dual-read update**
- Live conflicts: branch topology (unchanged)
- Historical context: `git show governance:artifacts/{domain}/` (new)
- Graceful downgrade if governance remote absent

---

### Out of Scope for v3.0

- **Per-initiative version pinning** (complexity vs. value unclear; defer to v3.1)
- **`/lens-upgrade` interactive conflict resolution** (dry-run + apply is sufficient for v3.0)
- **PR-based governance writes** — governance publication uses direct push by design; the artifact review gate is the PR that merges phases into the initiative's milestone branch. Once merged, artifacts are considered locked in and propagate to governance without further review ceremony.
- **Multi-remote governance** (single governance remote assumed)
- **Audience promotion timeline visualizer** (nice to have UX, not blocking)
- **Automated retrospective generation in `/close`** (retrospective template provided; content is user-generated)

---

## Future Vision

**v3.1 — Cross-Initiative Artifact Query**
`@lens /discover-context {domain}/{service}` synthesizes governance artifacts across all completed initiatives in a domain/service, giving the current initiative a pre-populated architectural context brief.

**v3.2 — Per-Initiative Version Pinning**
`initiative.yaml` gains a `lens_version:` field. Initiatives in-flight are pinned to their creation version until explicitly upgraded. Enables rolling upgrades across teams at different paces.

**v3.3 — Governance-Native Initiative Registry**
`governance:registry/initiatives.yaml` as a machine-readable index of all initiatives across all control repos — their domain, service, status, and artifact anchors. Enables org-wide initiative dashboards without reading every control repo's branches.

**v4.0 — Phase-as-Workflow Detachment**
Phases become independently versioned workflow definitions, allowing a `techplan` phase to be updated without touching `preplan`. Each phase workflow version is declared in `lifecycle.yaml` and validated at phase start.

---

## Resolved Decisions

| # | Question | Decision | Rationale |
|---|---|---|---|
| 1 | Milestone naming | **Work-type names** (`devproposal`, `sprintplan`) | Names should match the phase completed at that milestone, making branches self-documenting without audience-size semantics |
| 2 | Governance write access | **Direct push** | The PR that merges into the initiative's milestone branch is the review gate; once merged, artifacts are locked in and propagate to governance automatically. No separate governance PR review needed. |
| 3 | Tombstone retention | **Permanent** | Abandoned-territory signaling must persist indefinitely; tombstones are the authoritative record for why future initiatives in the same space should proceed with caution |
| 4 | `/switch` tier | **Read (lightweight)** | Switch is a state-read + checkout; it does not produce artifacts or mutate initiative state |
