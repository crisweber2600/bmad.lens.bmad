---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/tech-decisions.md'
initiative: lens-module-streamline
phase: devproposal
date: 2026-03-26
author: '@lens'
status: APPROVED
---

# lens-work v3 Streamline — Epic & Story Breakdown

## Overview

This document provides the complete epic and story breakdown for the **lens-module-streamline** initiative — the v2→v3 streamline of the lens-work module. It decomposes all PRD requirements and v3 architecture decisions into implementable stories organized by user value.

---

## Requirements Inventory

### Functional Requirements

```
FR1:  @lens routes phase commands (/preplan through /dev) to the correct workflow via lifecycle.yaml
FR2:  @lens creates initiative branch structures following lifecycle.yaml naming conventions
FR3:  @lens creates phase branches within initiatives following lifecycle-defined phase sequence
FR4:  @lens detects the current initiative and phase from the checked-out branch name
FR5:  @lens enforces phase ordering — a phase cannot start until its predecessor PR is merged
FR6:  @lens creates named branches in the control repo following lifecycle naming conventions
FR7:  @lens commits initiative artifacts to the current branch
FR8:  @lens pushes branches to the remote
FR9:  @lens creates pull requests from phase branches to audience branches with auto-populated descriptions
FR10: @lens creates promotion pull requests from one audience tier to the next with constitution compliance and sensing
FR11: @lens derives the current phase and audience of any initiative from branch topology
FR12: @lens derives pending actions from PR metadata (open PRs, review status, approval state)
FR13: @lens produces a consolidated status report across all active initiatives
FR14: @lens determines the next actionable task based on branch state, PR state, and role
FR15: @lens resolves the effective constitution by merging the 4-level hierarchy (org → domain → service → repo)
FR16: [POST-MVP] @lens applies language-specific constitution variants
FR17: @lens checks artifact compliance against the resolved constitution at PR creation time
FR18: @lens includes constitution compliance status in PR descriptions
FR19: @lens scans all active initiative branches to identify domain/service overlaps
FR20: @lens generates a sensing report listing overlapping initiatives with phase and artifacts
FR21: @lens attaches sensing reports to promotion PRs automatically
FR22: @lens switches the working tree to a different initiative's branch via /switch
FR23: @lens lists all active initiatives with current phase and audience via /status
FR24: @lens recommends the next action for the user via /next based on git-derived state
FR25: @lens detects the configured PR provider (GitHub or Azure DevOps)
FR26: @lens validates provider authentication without writing secrets to git
FR27: @lens verifies or clones the governance repo to the configured path
FR28: @lens creates a user profile with role, domain assignment, and question-mode preference
FR29: @lens executes preplan phase workflows producing product brief, research, and brainstorm artifacts
FR30: @lens executes businessplan phase workflows producing PRD and UX design artifacts
FR31: @lens executes techplan phase workflows producing architecture and technical decision artifacts
FR32: @lens executes devproposal phase workflows producing implementation proposal artifacts
FR33: @lens executes sprintplan phase workflows producing sprint plans and user stories
FR34: @lens executes dev phase workflows managing story implementation and code review cycles
FR35: @lens blocks writes to the release module directory during initiative work
FR36: @lens blocks writes to the governance repo during initiative work (except governance PRs)
FR37: @lens blocks initiative artifact writes outside the control repo's initiative directory
FR38: @lens reads the module version from the release repo and reports it
FR39: @lens detects when a newer module version is available
FR40: @lens guides the user through a self-service module update
```

### Non-Functional Requirements

```
NFR1:  All shared workflow state derived from git; zero git-ignored secondary state stores
NFR2:  /switch produces consistent working tree state on every execution; no partial state
NFR3:  Constitution resolution is deterministic for identical 4-level hierarchy inputs
NFR4:  User credentials stored exclusively in OS credential store or provider CLI login state
NFR5:  Authority domain boundaries enforced; release module and governance repo immutable to initiative workflows
NFR6:  Constitution compliance checks execute locally; no sensitive data sent externally
NFR7:  Git operations work across GitHub and Azure DevOps via provider adapters behind a common interface
NFR8:  Only declarative file formats (YAML, Markdown, CSV); no OS-specific dependencies
NFR9:  Standard .github/ conventions used as defined by VS Code Copilot
NFR10: Module surface ≤16 workflows, ≤13 prompts, ≤5 skills behind ~11 user touchpoints
NFR11: No runtime code (JS, Python, etc.) — all capabilities expressed as declarative instructions
NFR12: Independent skill updates without requiring workflow changes
NFR13: lifecycle.yaml is the single contract for branch naming, phase ordering, audiences, constitution schema
```

### Additional Requirements (from Architecture v3)

```
ARCH1: Replace git-state branch-suffix parsing with initiative-state.yaml YAML read (O(1) state queries)
ARCH2: Replace audience-name tokens (small/medium/large/base) with milestone-name tokens (techplan/devproposal/sprintplan/dev-ready)
ARCH3: Eliminate phase branches entirely; phase history tracked in commit markers and initiative-state.yaml
ARCH4: initiative-state.yaml committed atomically with phase-transition commits; one per initiative
ARCH5: LENS_VERSION file in control repo root; preflight hard-stops on version mismatch
ARCH6: publish-to-governance operation: direct push to governance repo at milestone promotion; no additional PR
ARCH7: _manifest.yaml generated and co-published with artifacts to governance
ARCH8: /close workflow: rich tombstone (artifact summary, reason, superseded-by) + initiative-state.yaml update
ARCH9: Tombstones published to governance:tombstones/{domain}/{service}/{initiative}-tombstone.md; permanent
ARCH10: sensing.md dual-read: Pass 1 = live branch conflicts; Pass 2 = governance:artifacts/ historical context
ARCH11: sensing graceful downgrade: if governance remote absent, branch-only sensing with advisory note
ARCH12: migrations section in lifecycle.yaml; /lens-upgrade applies descriptors, renames branches, updates YAML
ARCH13: validate-branch-name precondition in git-orchestration push / create-branch
ARCH14: /switch enumerates initiative-state.yaml files under _bmad-output/lens-work/initiatives/ (YAML, not branch scan)
```

### UX Design Requirements

None applicable — lens-work v3 is a CLI/agent module with no visual UI. All user interaction is via slash commands in the IDE chat interface.

### FR Coverage Map

| FR | Epic(s) | Story/Stories |
|----|---------|--------------|
| FR1 | Epic 2 | 2.1–2.5 (phase routers reference lifecycle.yaml milestone tokens) |
| FR2 | Epic 1, 2 | 1.1 (lifecycle.yaml v3), 2.6 (milestone branch creation) |
| FR3 | Epic 2 | 2.1–2.5 (phase branches eliminated; commit markers replace phase tracking) |
| FR4 | Epic 1 | 1.4 (git-state YAML-first: branch = lookup key only) |
| FR5 | Epic 1, 2 | 1.3 (phase ordering in YAML state), 2.1–2.5 (phase gate checks) |
| FR6 | Epic 1, 2 | 1.1 (lifecycle contract), 2.6 (milestone branch creation op) |
| FR7 | Epic 1, 2 | 1.3 (commit-artifacts includes YAML update), 2.1–2.5 (artifact commits) |
| FR8 | Epic 1, 2 | 1.5 (push with validate-branch-name), 2.6 |
| FR9 | Epic 2 | 2.1–2.5 (milestone-branch PRs replacing phase-branch PRs) |
| FR10 | Epic 2, 3 | 2.6 (promotion PR), 3.1–3.2 (governance publication at promotion) |
| FR11 | Epic 1 | 1.4 (git-state reads initiative-state.yaml) |
| FR12 | Epic 1 | 1.4 (PR metadata + YAML state) |
| FR13 | Epic 1 | 1.4 (/status via YAML file enumeration) |
| FR14 | Epic 1 | 1.4 (/next from YAML state) |
| FR15 | Existing | Constitution skill unchanged in v3 |
| FR16 | POST-MVP | Out of scope for this initiative |
| FR17 | Existing | Constitution compliance checks unchanged in v3 |
| FR18 | Existing | PR descriptions with compliance status unchanged in v3 |
| FR19 | Epic 3, 5 | 3.3 (sensing reads governance), 5.1 (dual-read sensing) |
| FR20 | Epic 5 | 5.1–5.2 (enhanced sensing with historical context) |
| FR21 | Epic 3, 5 | 3.2 (sensing attached at promotion), 5.1 (historical context in sensing) |
| FR22 | Epic 1 | 1.4 (/switch YAML file enumeration) |
| FR23 | Epic 1 | 1.4 (/status via YAML enumeration) |
| FR24 | Epic 1 | 1.4 (/next directive from YAML state) |
| FR25 | Existing | /onboard provider detection unchanged |
| FR26 | Existing | /onboard auth validation unchanged |
| FR27 | Existing | /onboard governance clone unchanged |
| FR28 | Existing | /onboard profile creation unchanged |
| FR29 | Epic 2 | 2.1 (preplan workflow update) |
| FR30 | Epic 2 | 2.2 (businessplan workflow update) |
| FR31 | Epic 2 | 2.3 (techplan workflow update) |
| FR32 | Epic 2 | 2.4 (devproposal workflow update) |
| FR33 | Epic 2 | 2.5 (sprintplan workflow update) |
| FR34 | Existing | dev workflow unchanged in v3 scope |
| FR35 | Existing | Authority enforcement unchanged |
| FR36 | Existing | Authority enforcement unchanged |
| FR37 | Existing | Authority enforcement unchanged |
| FR38 | Epic 6 | 6.1 (LENS_VERSION + lifecycle.yaml schema_version) |
| FR39 | Epic 6 | 6.2 (/lens-upgrade version check) |
| FR40 | Epic 6 | 6.2–6.3 (/lens-upgrade self-service migration) |

---

## Epic List

| # | Epic | User Value | Standalone? |
|---|------|------------|-------------|
| 1 | Reliable Initiative State (initiative-state.yaml + LENS_VERSION) | O(1) state queries; /status, /switch, /next never break; version mismatch caught before corruption | Yes — foundational |
| 2 | Streamlined Branch Topology (Milestone branches; no phase branches) | 5 readable branches instead of 10; no wrong-branch work; self-documenting milestone names | Needs Epic 1 (YAML state) |
| 3 | Governance Artifact Publication (Publish at milestone promotion) | Artifacts visible from governance repo; historical sensing has artifact context without control repo checkout | Needs Epic 1+2 |
| 4 | Initiative Lifecycle Closure (/close + tombstones) | No ghost work in sensing; formal closure record; sensing distinguishes active vs. closed | Needs Epic 1+3 |
| 5 | Enhanced Cross-Initiative Sensing (Dual-read: live + governance history) | Live conflict detection + historical prior-decision context in sensing reports | Needs Epic 3+4 |
| 6 | Self-Service Module Upgrade (/lens-upgrade + LENS_VERSION safety) | v2→v3 migration without author; version mismatch hard-stopped; automated branch renames | Needs Epic 1+2 |

---

## Epic 1: Reliable Initiative State

**Goal:** Replace all branch-name-parsing state derivation with O(1) YAML reads from `initiative-state.yaml`. Add `LENS_VERSION` to control repo and preflight version-mismatch guard. This epic is the foundation all other v3 changes build on.

### Story 1.1: Create lifecycle.yaml v3 Schema

As a module dev agent,
I want to update `lifecycle.yaml` to schema_version 3 with milestone tokens, close_states, artifact_publication, and migrations section,
So that the v3 contract is established and all downstream skills and workflows have a valid schema to reference.

**Acceptance Criteria:**

**Given** `lifecycle.yaml` currently has schema_version 2 with audience tokens small/medium/large/base
**When** the lifecycle.yaml v3 schema update is applied
**Then** `schema_version` is `3`, milestone tokens `techplan/devproposal/sprintplan/dev-ready` replace audience tokens, `close_states: [completed, abandoned, superseded]` is present, `artifact_publication: { governance_root: 'artifacts/', enabled: true }` is present, and a `migrations` section with the v2→v3 descriptor exists
**And** the file validates as valid YAML with no structural errors
**And** all existing field references (phases, tracks, constitution schema) remain intact

### Story 1.2: Create `initiative-state.yaml` Schema and `create-initiative-state` Operation

As a module dev agent,
I want `initiative-state.yaml` schema documented in `git-orchestration.md` with a `create-initiative-state` operation,
So that the first phase start for any initiative produces a valid, committed state file.

**Acceptance Criteria:**

**Given** a new initiative runs its first phase command
**When** `create-initiative-state` is invoked in git-orchestration
**Then** `initiative-state.yaml` is created at `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml` with all required v3 fields (schema_version, initiative, domain, service, milestone, phase, phase_status, lifecycle_status, lens_version, created, last_updated, artifacts)
**And** the file is committed atomically with the first phase-start commit
**And** `lifecycle_status` is `active`, `phase_status` is `in-progress`

### Story 1.3: Add `update-initiative-state` Family of Operations

As a module dev agent,
I want `git-orchestration.md` to include `update-phase-start`, `update-phase-complete`, `update-milestone-promote`, `update-close`, and `update-lens-upgrade` operations,
So that every phase event atomically updates the YAML state and no event is ever unrecorded.

**Acceptance Criteria:**

**Given** any phase lifecycle event (start, complete, promote, close, upgrade)
**When** the corresponding update operation is invoked
**Then** the correct fields are updated in `initiative-state.yaml` (per the architecture Operations table: milestone, phase, phase_status, lifecycle_status, artifacts, lens_version, last_updated as appropriate)
**And** the YAML update is staged and committed in the same git commit as the triggering event (atomic guarantee)
**And** `last_updated` is always refreshed to the current ISO date

### Story 1.4: Update `git-state.md` to YAML-First State Reads

As a module dev agent,
I want `git-state.md` to read all state from `initiative-state.yaml` instead of parsing branch name strings,
So that `/status`, `/next`, `/switch`, and all state queries are O(1), reliable, and branch-rename safe.

**Acceptance Criteria:**

**Given** an active initiative with a committed `initiative-state.yaml`
**When** any state query operation (current-initiative, list-initiatives, switch, next-action) is invoked
**Then** the result is derived entirely from YAML reads — no branch name substring parsing, no `git log --grep` scanning
**And** `/switch` enumerates `initiative-state.yaml` files under `_bmad-output/lens-work/initiatives/` and presents them by initiative name, not by branch scan
**And** the branch name is used only as a lookup key to locate the correct YAML file — never split or parsed for structural state
**And** if `initiative-state.yaml` is missing on a branch, git-state falls back to branch-suffix detection and warns the user to run `/lens-upgrade`

### Story 1.5: Add `LENS_VERSION` File and Preflight Version Guard

As a module dev agent,
I want `LENS_VERSION` written by setup scripts and checked in preflight for write-tier commands,
So that running a v3 module against a v2 control repo is caught immediately with a clear error.

**Acceptance Criteria:**

**Given** the setup scripts (`setup-control-repo.sh` and `setup-control-repo.ps1`)
**When** they initialize a new control repo
**Then** a `LENS_VERSION` file is written to the control repo root containing the current version string (e.g., `3.0.0`)

**Given** preflight runs before any write-tier workflow (phase commands, promote, close)
**When** `LENS_VERSION` content does not match `lifecycle.yaml schema_version`
**Then** preflight HARD STOPs with message: `"VERSION MISMATCH: control repo is v{LENS_VERSION}, module expects v{schema_version}. Run /lens-upgrade."`
**And** no workflow execution proceeds past preflight on a version mismatch

---

## Epic 2: Streamlined Branch Topology

**Goal:** Eliminate phase branches entirely. Replace audience-name tokens with milestone-name tokens. Phase history is recorded via `[PHASE:X:COMPLETE]` commit markers and `initiative-state.yaml` — not via branch existence. Milestone branches are created only at phase closeout events.

### Story 2.1: Update Preplan Workflow to Milestone Model

As a module dev agent,
I want the preplan router steps updated to add `[PHASE:PREPLAN:START]` and `[PHASE:PREPLAN:COMPLETE]` commit markers and update `initiative-state.yaml`, without creating a separate preplan phase branch,
So that preplan artifacts are committed directly to the initiative root branch with a clean, auditable marker.

**Acceptance Criteria:**

**Given** a user runs `/preplan` on an initiative root branch
**When** preplan workflow executes
**Then** a `[PHASE:PREPLAN:START]` commit marker is added to the initiative root branch, no separate preplan branch is created, and a `[PHASE:PREPLAN:COMPLETE]` marker with artifact list in the commit body is added on completion
**And** `initiative-state.yaml` is atomically updated: `phase: preplan`, `phase_status: complete`, `artifacts.preplan` populated
**And** the commit body for PHASE:PREPLAN:COMPLETE includes an inline artifact list (per Decision OD-2)

### Story 2.2: Update BusinessPlan Workflow to Milestone Model

As a module dev agent,
I want the businessplan router steps updated to use commit markers and YAML state (no businessplan phase branch),
So that businessplan artifacts are committed to the initiative branch with the same milestone-model pattern.

**Acceptance Criteria:**

**Given** a user runs `/businessplan` on an initiative branch after preplan is complete
**When** businessplan workflow executes
**Then** `[PHASE:BUSINESSPLAN:START]` and `[PHASE:BUSINESSPLAN:COMPLETE]` markers are committed, no businessplan branch is created
**And** `initiative-state.yaml` is updated: `phase: businessplan`, `phase_status: complete`, `artifacts.businessplan` populated
**And** the existing businessplan phase-start prerequisite check (preplan:complete) uses `initiative-state.yaml.phase_status` instead of checking for a closed preplan branch PR

### Story 2.3: Update TechPlan Workflow to Milestone Model

As a module dev agent,
I want the techplan router steps updated to use commit markers and YAML state, and to create the `{initiative}-techplan` milestone branch at phase closeout,
So that the techplan milestone branch signals readiness for the devproposal phase.

**Acceptance Criteria:**

**Given** a user runs `/techplan` on an initiative branch after businessplan is complete
**When** techplan workflow executes and artifacts are committed
**Then** `[PHASE:TECHPLAN:START]` and `[PHASE:TECHPLAN:COMPLETE]` markers are committed, no separate techplan phase branch is created mid-workflow
**And** at closeout, the `{initiative_root}-techplan` milestone branch is created from the current branch state and pushed to remote
**And** `initiative-state.yaml` is updated: `milestone: techplan`, `phase: techplan`, `phase_status: complete`
**And** a PR is created from `{initiative_root}-techplan` to `main` (or governance-configured base) with constitution compliance status and sensing report

### Story 2.4: Update DevProposal Workflow to Milestone Model

As a module dev agent,
I want the devproposal router steps updated to commit markers and YAML state, and to create the `{initiative}-devproposal` milestone branch at phase closeout,
So that the devproposal milestone branch signals readiness for the sprintplan phase.

**Acceptance Criteria:**

**Given** a user runs `/devproposal` on the `{initiative_root}-techplan` milestone branch after devproposal work
**When** devproposal workflow executes and artifacts are committed
**Then** `[PHASE:DEVPROPOSAL:START]` and `[PHASE:DEVPROPOSAL:COMPLETE]` markers are committed
**And** at closeout, the `{initiative_root}-devproposal` milestone branch is created and pushed
**And** `initiative-state.yaml` is updated: `milestone: devproposal`, `phase: devproposal`, `phase_status: complete`
**And** a PR is created with constitution compliance and sensing report

### Story 2.5: Update SprintPlan Workflow to Milestone Model

As a module dev agent,
I want the sprintplan router steps updated to the milestone model, creating the `{initiative}-sprintplan` milestone branch at closeout,
So that the full phase sequence (preplan → businessplan → techplan → devproposal → sprintplan) is committed-marker-tracked without any phase branches.

**Acceptance Criteria:**

**Given** a user runs `/sprintplan` on the `{initiative_root}-devproposal` milestone branch
**When** sprintplan workflow executes
**Then** `[PHASE:SPRINTPLAN:START]` and `[PHASE:SPRINTPLAN:COMPLETE]` markers are committed
**And** at closeout, `{initiative_root}-sprintplan` milestone branch is created and pushed
**And** `initiative-state.yaml` is updated: `milestone: sprintplan`, `phase: sprintplan`, `phase_status: complete`

### Story 2.6: Update `git-orchestration.md` for Milestone Branch Operations

As a module dev agent,
I want `git-orchestration.md` updated to add `create-milestone-branch` operation (replacing `start-phase`) and `validate-branch-name` precondition to push/create-branch,
So that all branch creation follows the milestone model and non-conforming branches are rejected at the agent layer.

**Acceptance Criteria:**

**Given** a milestone closeout event triggers branch creation
**When** `create-milestone-branch` is invoked with `{initiative_root}-{milestone_token}` as the branch name
**Then** the branch is created from the current HEAD, pushed to remote, and `initiative-state.yaml` is updated with the new milestone token
**And** the `validate-branch-name` precondition checks the proposed branch name against `lifecycle.yaml` milestone token list and FAILS with a clear error if the name is non-conforming
**And** the old `start-phase` operation is marked deprecated (retained for backward compat but documented as deprecated)

---

## Epic 3: Governance Artifact Publication

**Goal:** At every milestone promotion (PR merge), publish all phase artifacts and a `_manifest.yaml` directly to the governance repo — no ceremony, no additional PR. Artifacts are queryable by consumers and by the enhanced sensing pass.

### Story 3.1: Add `publish-to-governance` Operation to `git-orchestration.md`

As a module dev agent,
I want a `publish-to-governance` operation in `git-orchestration.md` that direct-pushes all initiative artifacts to `governance:artifacts/{domain}/{service}/{initiative}/` and generates `_manifest.yaml`,
So that initiative artifacts land in governance at every milestone promotion without a redundant review gate.

**Acceptance Criteria:**

**Given** a milestone promotion event (milestone-branch PR merged)
**When** `publish-to-governance` is invoked with initiative domain/service/slug and artifact list
**Then** all listed artifacts are pushed to `governance:artifacts/{domain}/{service}/{initiative}/` via direct push (not PR)
**And** a `_manifest.yaml` is generated and included in the push with initiative metadata: initiative, domain, service, published_at, milestone, lens_version, and artifact file list
**And** artifacts from prior publications are replaced atomically (no stale files from earlier phases)
**And** if the governance remote is not configured, the operation logs a clear warning and continues without hard-failing

### Story 3.2: Add Governance Publication Step to Audience-Promotion Workflow

As a module dev agent,
I want the audience-promotion workflow (milestone-branch PR closeout) to invoke `publish-to-governance` after artifact validation,
So that every merged milestone PR automatically propagates artifacts to governance without an extra manual step.

**Acceptance Criteria:**

**Given** a milestone-branch PR (e.g., `foo-bar-auth-techplan` → main) is merged
**When** the promotion workflow closeout logic runs
**Then** `publish-to-governance` is called with all artifacts from `initiative-state.yaml.artifacts`
**And** after the push, governance repo has `artifacts/{domain}/{service}/{initiative}/` with all phase artifacts and `_manifest.yaml`
**And** `initiative-state.yaml` is updated: `last_updated` refreshed, `mileston` confirmed

### Story 3.3: Add Governance Dual-Read Bootstrapping to `sensing.md`

As a module dev agent,
I want `sensing.md` updated to include the governance:artifacts/ read as a second pass with graceful downgrade,
So that sensing surfaces historical completed-initiative context when governance is available, and operates identically to current behavior when it isn't.

**Acceptance Criteria:**

**Given** sensing is invoked at a promotion gate with governance remote configured
**When** the sensing scan runs
**Then** Pass 1 (live branch conflicts) runs identically to current behavior
**And** Pass 2 reads `governance:artifacts/{domain}/{service}/` for completed initiatives in the same domain/service, loads their `_manifest.yaml` files, and appends a "Historical Context" section to the sensing report

**Given** governance remote is absent or `artifacts/` path is not found
**When** sensing runs
**Then** only Pass 1 (branch-only) executes
**And** the sensing report notes: `"Governance artifact history unavailable (remote not configured)"`

---

## Epic 4: Initiative Lifecycle Closure

**Goal:** Provide a `/close` command that formally ends an initiative in one of three states (completed, abandoned, superseded-by). Publishes a rich tombstone to governance. Updates `initiative-state.yaml`. Eliminates ghost-work false positives from sensing.

### Story 4.1: Create `/close` Router Workflow

As a @lens agent,
I want a `/close` router workflow with three variants (`--completed`, `--abandoned`, `--superseded-by {initiative}`),
So that project managers can formally end an initiative with the appropriate close state.

**Acceptance Criteria:**

**Given** a user invokes `/close --completed` (or `--abandoned` or `--superseded-by foo`)
**When** the close workflow runs
**Then** the workflow validates `initiative-state.yaml` exists and `lifecycle_status == active`, prompts for close reason text, generates the rich tombstone markdown (per Decision OD-3 format: domain, service, closed date, status, superseded-by, final milestone, lens version, reason, artifact summary table, phase history excerpt), and publishes it to `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md` via direct push
**And** `initiative-state.yaml` is updated: `lifecycle_status` set to completed/abandoned/superseded, `superseded_by` set (if applicable), `last_updated` refreshed
**And** a `[CLOSE:{VARIANT}] {initiative} — {reason}` commit marker is committed with the updated YAML
**And** the workflow outputs a completion summary with tombstone path and next steps

### Story 4.2: Add `update-close` and Tombstone Operations to `git-orchestration.md`

As a module dev agent,
I want `git-orchestration.md` to include `update-close` (YAML update) and `publish-tombstone` (governance direct push) operations,
So that `/close` has clean, reusable operations for its two main writes.

**Acceptance Criteria:**

**Given** the `/close` workflow invokes `update-close`
**When** the operation runs
**Then** `initiative-state.yaml` fields `lifecycle_status`, `superseded_by`, and `last_updated` are updated and committed atomically with the CLOSE: marker
**And** `publish-tombstone` pushes the generated tombstone markdown to `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md` via direct push (mirroring publish-to-governance pattern)

### Story 4.3: Filter Closed Initiatives from Live Sensing Conflict Detection

As a module dev agent,
I want `sensing.md` Pass 1 (live branch conflicts) updated to exclude initiatives with `lifecycle_status != active` in their `initiative-state.yaml`,
So that abandoned, completed, or superseded initiatives no longer generate false-positive conflict alerts.

**Acceptance Criteria:**

**Given** two initiatives share a domain/service, but one has `lifecycle_status: abandoned`
**When** sensing scans for live conflicts
**Then** the abandoned initiative is NOT listed as an active conflict
**And** it may appear in the Pass 2 historical section (from governance) with its tombstone context
**Given** an initiative has no `initiative-state.yaml` (legacy v2)
**When** sensing encounters it
**Then** it is treated as active (conservative fallback) and a note suggests running `/lens-upgrade`

---

## Epic 5: Enhanced Cross-Initiative Sensing

**Goal:** Upgrade sensing to a dual-read that surfaces not only live branch conflicts but also historical prior-initiative decisions from governance artifacts. This gives reviewers full context at promotion gates — what was decided here before, not just what's active now.

### Story 5.1: Implement Governance Historical Context Pass in `sensing.md`

As a module dev agent,
I want `sensing.md` to implement Pass 2 — reading `governance:artifacts/{domain}/{service}/` for completed/closed initiatives and their `_manifest.yaml` files — and appending a "Historical Context" section to sensing reports,
So that tech leads and reviewers see prior decisions from the same domain/service alongside current live conflicts.

**Acceptance Criteria:**

**Given** a promotion gate sensing scan runs with governance remote configured and initiatives exist in `governance:artifacts/{domain}/{service}/`
**When** Pass 2 executes
**Then** for each prior initiative found, the sensing report's Historical Context section lists: initiative name, final milestone, published_at, and a link to its artifact path in governance
**And** the historical section is clearly labeled and separated from the live conflict section
**And** sensing report structure is: [Live Conflicts] → [Historical Context] → [Summary]
**And** Pass 2 never fails the gate — all errors are advisory (no governance access = no historical section + note)

### Story 5.2: Verify Sensing Graceful Downgrade Works End-to-End

As a module dev agent,
I want the sensing workflow to be tested end-to-end with governance remote absent, present-but-empty, and present-with-data,
So that all three configurations produce the correct sensing report format without errors.

**Acceptance Criteria:**

**Given** governance remote is absent (remote not configured)
**When** sensing runs
**Then** only Pass 1 runs, the report notes "Governance artifact history unavailable (remote not configured)", no error is thrown

**Given** governance remote is configured but `artifacts/{domain}/{service}/` directory does not exist
**When** Pass 2 runs
**Then** the Historical Context section says "No prior initiatives found in governance for {domain}/{service}", no error

**Given** governance remote is configured and `artifacts/{domain}/{service}/foo-bar/` contains `_manifest.yaml`
**When** Pass 2 runs
**Then** Historical Context section lists foo-bar with its manifest data (initiative, milestone, published_at)

---

## Epic 6: Self-Service Module Upgrade

**Goal:** Enable v2→v3 migration via a `/lens-upgrade` command that reads migration descriptors from `lifecycle.yaml`, renames milestone branches, updates all `initiative-state.yaml` files, and writes the new `LENS_VERSION`. No manual intervention required.

### Story 6.1: Add `migrations` Section to `lifecycle.yaml`

As a module dev agent,
I want a `migrations` section in `lifecycle.yaml` with a complete v2→v3 migration descriptor (field renames, new fields, close_states, branch_rename_required),
So that `/lens-upgrade` has a machine-readable specification of every change needed to migrate a control repo.

**Acceptance Criteria:**

**Given** the `lifecycle.yaml` v3 schema (from Story 1.1) is in place
**When** the `migrations` section is added
**Then** it contains a migration entry with `from_version: 2`, `to_version: 3`, `breaking: true`, and a `changes` array that includes: audience-to-milestone field renames (small→techplan, medium→devproposal, large→sprintplan, base→dev-ready), `add_field: artifact_publication` with value, `add_field: close_states`, `add_field: initiative_state_schema`, and `branch_rename_required: true`
**And** the `migration_command` field is set to `'/lens-upgrade --from 2 --to 3'`

### Story 6.2: Create `/lens-upgrade` Router Workflow

As a @lens agent,
I want a `/lens-upgrade` router workflow that reads migration descriptors and applies them in sequence with a `--dry-run` option,
So that users can preview and execute the v2→v3 migration without manual file editing or branch coordination.

**Acceptance Criteria:**

**Given** a user invokes `/lens-upgrade --dry-run` on a v2 control repo (LENS_VERSION = 2.x.x or missing)
**When** the dry-run executes
**Then** a complete change list is displayed: field renames, branches to rename (e.g., `foo-bar-auth-small` → `foo-bar-auth-techplan`), YAML files to update, LENS_VERSION to write — no changes applied

**Given** a user invokes `/lens-upgrade` (without --dry-run)
**When** the upgrade executes
**Then** all field renames are applied to `lifecycle.yaml`, all active initiative audience branches are renamed to milestone token names (git rename + push), all `initiative-state.yaml` files are created or updated with `schema_version: 3` and `lens_version` set, and `LENS_VERSION` is written to the control repo root
**And** a `[LENS:UPGRADE] migrated from v{N} to v{M}` commit marker is created with all modified files
**And** if versions already match, the workflow reports "Already at current version" and exits cleanly

### Story 6.3: Add `validate-branch-name` Precondition to `git-orchestration.md` Push

As a module dev agent,
I want `git-orchestration.md`'s `push` and `create-branch` operations to include a `validate-branch-name` precondition that checks against `lifecycle.yaml` milestone token list,
So that non-conforming branch names are caught at the agent layer before reaching the remote.

**Acceptance Criteria:**

**Given** a push or create-branch operation is invoked with a branch name containing initiative-topology tokens (e.g., `foo-bar-techXYZ`)
**When** `validate-branch-name` runs
**Then** it checks that the token suffix matches a recognized milestone token from `lifecycle.yaml` (techplan, devproposal, sprintplan, dev-ready) or that the branch is an initiative root (no token suffix)
**And** if invalid, it FAILS with: `"Invalid branch token '{token}'. Expected one of: {lifecycle.yaml milestone tokens}. Run /lens-upgrade to migrate."`
**And** if valid, it proceeds silently

---

## NFR Coverage Summary

| NFR | Covered By |
|-----|-----------|
| NFR1 | Epic 1 (initiative-state.yaml eliminates all non-git secondary state; LENS_VERSION is committed) |
| NFR2 | Epic 1 (Story 1.4: /switch via YAML enumeration; deterministic, no partial state) |
| NFR3 | Existing (constitution skill; no changes in v3) |
| NFR4 | Existing (auth in OS credential store; no changes in v3) |
| NFR5 | Existing + Story 1.5 (LENS_VERSION mismatch hard-stop prevents data corruption) |
| NFR6 | Existing (local compliance checks; no changes in v3) |
| NFR7 | Existing (provider adapters; GitHub MVP; Azure DevOps post-MVP) |
| NFR8 | All epics (only YAML/Markdown/PS/sh files authored) |
| NFR9 | Existing (.github/ conventions; no changes in v3) |
| NFR10 | Epic 2 (phase workflow updates consolidate; total stays ≤16 workflows) |
| NFR11 | All epics (all outputs are YAML/Markdown declarative files) |
| NFR12 | All epics (skill updates are isolated file changes; no workflow modifications needed) |
| NFR13 | Epic 1 (lifecycle.yaml v3 remains single contract) |
