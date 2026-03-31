---
initiative: lens-module-streamline
phase: devproposal
date: 2026-03-26
author: '@lens'
status: APPROVED
epicsSource: '_bmad-output/planning-artifacts/epics.md'
totalEpics: 6
totalStories: 22
---

# lens-work v3 Streamline — Story Backlog

> **Developer Backlog.** All stories extracted from [epics.md](./epics.md). Each story is self-contained, independently completable, and sized for a single dev agent session. Epic order = recommended implementation order (Epic 1 is foundational).

---

## Quick Reference

| Story | Title | Epic | Depends On |
|-------|-------|------|------------|
| 1.1 | Update lifecycle.yaml to Schema v3 | Epic 1 | — |
| 1.2 | Create `initiative-state.yaml` Schema + `create-initiative-state` Op | Epic 1 | 1.1 |
| 1.3 | Add `update-initiative-state` Family of Ops | Epic 1 | 1.2 |
| 1.4 | Update `git-state.md` to YAML-First State Reads | Epic 1 | 1.2, 1.3 |
| 1.5 | Add `LENS_VERSION` File and Preflight Version Guard | Epic 1 | 1.1 |
| 2.1 | Update Preplan Workflow to Milestone Model | Epic 2 | 1.1–1.3 |
| 2.2 | Update BusinessPlan Workflow to Milestone Model | Epic 2 | 1.1–1.3 |
| 2.3 | Update TechPlan Workflow to Milestone Model | Epic 2 | 1.1–1.3 |
| 2.4 | Update DevProposal Workflow to Milestone Model | Epic 2 | 1.1–1.3 |
| 2.5 | Update SprintPlan Workflow to Milestone Model | Epic 2 | 1.1–1.3 |
| 2.6 | Update `git-orchestration.md` for Milestone Branch Ops | Epic 2 | 1.1–1.3 |
| 2.7 | Update SprintPlan to Batch Dev-Story Creation | Epic 2 | 2.5 |
| 3.1 | Add `publish-to-governance` Op | Epic 3 | 1.2–1.3, 2.6 |
| 3.2 | Add Governance Publication Step to Promotion Workflow | Epic 3 | 3.1 |
| 3.3 | Add Governance Dual-Read Bootstrapping to `sensing.md` | Epic 3 | 3.1 |
| 4.1 | Create `/close` Router Workflow | Epic 4 | 1.2–1.3, 3.1 |
| 4.2 | Add `update-close` and Tombstone Ops to `git-orchestration.md` | Epic 4 | 3.1 |
| 4.3 | Filter Closed Initiatives from Live Sensing | Epic 4 | 4.1–4.2 |
| 5.1 | Implement Governance Historical Context Pass in `sensing.md` | Epic 5 | 3.1–3.2, 4.1–4.2 |
| 5.2 | Verify Sensing Graceful Downgrade End-to-End | Epic 5 | 5.1 |
| 6.1 | Add `migrations` Section to `lifecycle.yaml` | Epic 6 | 1.1 |
| 6.2 | Create `/lens-upgrade` Router Workflow | Epic 6 | 1.1–1.5, 2.6, 6.1 |
| 6.3 | Add `validate-branch-name` Precondition to `git-orchestration.md` Push | Epic 6 | 2.6 |

---

## Epic 1 Stories — Reliable Initiative State

### Story 1.1: Update lifecycle.yaml to Schema v3

As a module dev agent,
I want to update `lifecycle.yaml` to schema_version 3 with milestone tokens, close_states, artifact_publication, and migrations section,
So that the v3 contract is established and all downstream skills and workflows have a valid schema to reference.

**Acceptance Criteria:**

**Given** `lifecycle.yaml` currently has schema_version 2 with audience tokens small/medium/large/base
**When** the lifecycle.yaml v3 schema update is applied
**Then** `schema_version` is `3`
**And** milestone tokens `techplan/devproposal/sprintplan/dev-ready` replace audience tokens
**And** `close_states: [completed, abandoned, superseded]` is present
**And** `artifact_publication: { governance_root: 'artifacts/', enabled: true }` is present
**And** a `migrations` section with the v2→v3 descriptor exists
**And** the file validates as valid YAML with no structural errors
**And** all existing field references (phases, tracks, constitution schema) remain intact

---

### Story 1.2: Create `initiative-state.yaml` Schema and `create-initiative-state` Operation

As a module dev agent,
I want `initiative-state.yaml` schema documented in `git-orchestration.md` with a `create-initiative-state` operation,
So that the first phase start for any initiative produces a valid, committed state file.

**Acceptance Criteria:**

**Given** a new initiative runs its first phase command
**When** `create-initiative-state` is invoked in git-orchestration
**Then** `initiative-state.yaml` is created at `_bmad-output/lens-work/initiatives/{domain}/{service}/{initiative}/initiative-state.yaml` with all required v3 fields: schema_version, initiative, domain, service, milestone, phase, phase_status, lifecycle_status, lens_version, created, last_updated, artifacts
**And** the file is committed atomically with the first phase-start commit
**And** `lifecycle_status` is `active`, `phase_status` is `in-progress`

---

### Story 1.3: Add `update-initiative-state` Family of Operations

As a module dev agent,
I want `git-orchestration.md` to include `update-phase-start`, `update-phase-complete`, `update-milestone-promote`, `update-close`, and `update-lens-upgrade` operations,
So that every phase event atomically updates the YAML state and no event is ever unrecorded.

**Acceptance Criteria:**

**Given** any phase lifecycle event (start, complete, promote, close, upgrade)
**When** the corresponding update operation is invoked
**Then** the correct fields are updated in `initiative-state.yaml` per the architecture Operations table (milestone, phase, phase_status, lifecycle_status, artifacts, lens_version, last_updated as appropriate)
**And** the YAML update is staged and committed in the same git commit as the triggering event (atomic guarantee)
**And** `last_updated` is always refreshed to the current ISO date

---

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

---

### Story 1.5: Add `LENS_VERSION` File and Preflight Version Guard

As a module dev agent,
I want `LENS_VERSION` written by setup scripts and checked in preflight for write-tier commands,
So that running a v3 module against a v2 control repo is caught immediately with a clear error.

**Acceptance Criteria:**

**Given** the setup scripts (`setup-control-repo.sh` and `setup-control-repo.ps1`)
**When** they initialize a new control repo
**Then** a `LENS_VERSION` file is written to the control repo root containing the current version string (e.g., `3.0.0`)

**Given** preflight runs before any write-tier workflow
**When** `LENS_VERSION` content does not match `lifecycle.yaml schema_version`
**Then** preflight HARD STOPs with message: `"VERSION MISMATCH: control repo is v{LENS_VERSION}, module expects v{schema_version}. Run /lens-upgrade."`
**And** no workflow execution proceeds past preflight on a version mismatch

---

## Epic 2 Stories — Streamlined Branch Topology

### Story 2.1: Update Preplan Workflow to Milestone Model

As a module dev agent,
I want the preplan router steps updated to add `[PHASE:PREPLAN:START]` and `[PHASE:PREPLAN:COMPLETE]` commit markers and update `initiative-state.yaml`, without creating a separate preplan phase branch,
So that preplan artifacts are committed directly to the initiative root branch with a clean, auditable marker.

**Acceptance Criteria:**

**Given** a user runs `/preplan` on an initiative root branch
**When** preplan workflow executes
**Then** a `[PHASE:PREPLAN:START]` commit marker is added to the initiative root branch, no separate preplan branch is created
**And** a `[PHASE:PREPLAN:COMPLETE]` marker with artifact list in the commit body is added on completion
**And** `initiative-state.yaml` is atomically updated: `phase: preplan`, `phase_status: complete`, `artifacts.preplan` populated
**And** the commit body for PHASE:PREPLAN:COMPLETE includes an inline artifact list (per Decision OD-2)

---

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

---

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
**And** a PR is created from `{initiative_root}-techplan` to `main` with constitution compliance status and sensing report

---

### Story 2.4: Update DevProposal Workflow to Milestone Model

As a module dev agent,
I want the devproposal router steps updated to commit markers and YAML state, and to create the `{initiative}-devproposal` milestone branch at phase closeout,
So that the devproposal milestone branch signals readiness for the sprintplan phase.

**Acceptance Criteria:**

**Given** a user runs `/devproposal` on the `{initiative_root}-techplan` milestone branch
**When** devproposal workflow executes and artifacts are committed
**Then** `[PHASE:DEVPROPOSAL:START]` and `[PHASE:DEVPROPOSAL:COMPLETE]` markers are committed
**And** at closeout, the `{initiative_root}-devproposal` milestone branch is created and pushed
**And** `initiative-state.yaml` is updated: `milestone: devproposal`, `phase: devproposal`, `phase_status: complete`
**And** a PR is created with constitution compliance and sensing report

---

### Story 2.5: Update SprintPlan Workflow to Milestone Model

As a module dev agent,
I want the sprintplan router steps updated to the milestone model, creating the `{initiative}-sprintplan` milestone branch at closeout,
So that the full phase sequence is committed-marker-tracked without any phase branches.

**Acceptance Criteria:**

**Given** a user runs `/sprintplan` on the `{initiative_root}-devproposal` milestone branch
**When** sprintplan workflow executes
**Then** `[PHASE:SPRINTPLAN:START]` and `[PHASE:SPRINTPLAN:COMPLETE]` markers are committed
**And** at closeout, `{initiative_root}-sprintplan` milestone branch is created and pushed
**And** `initiative-state.yaml` is updated: `milestone: sprintplan`, `phase: sprintplan`, `phase_status: complete`

---

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

### Story 2.7: Update SprintPlan to Batch-Create All Dev-Story Artifacts Per Epic

As a module dev agent,
I want `/sprintplan` step-04 to loop over ALL stories in the sprint backlog for the target epic and create dev-story artifacts for each,
So that `/dev` can discover and implement the complete story set for the epic in a single session.

**Acceptance Criteria:**

**Given** sprint planning (step-03) has produced a sprint backlog for an epic
**When** step-04 (dev-story creation) executes
**Then** the dev-story workflow is invoked once per story in the sprint backlog for the target epic
**And** each story artifact is written to `{bmad_docs}` with the standard dev-story naming pattern
**And** the sprint-status is updated to mark ALL created stories as `ready-for-dev`
**And** closeout (step-05) reports the count of dev-story artifacts created

**Given** the sprint backlog contains stories that already have dev-story artifacts
**When** step-04 iterates the backlog
**Then** existing artifacts are skipped with a note (no overwrite)

---

## Epic 3 Stories — Governance Artifact Publication

### Story 3.1: Add `publish-to-governance` Operation to `git-orchestration.md`

As a module dev agent,
I want a `publish-to-governance` operation in `git-orchestration.md` that direct-pushes all initiative artifacts to `governance:artifacts/{domain}/{service}/{initiative}/` and generates `_manifest.yaml`,
So that initiative artifacts land in governance at every milestone promotion without a redundant review gate.

**Acceptance Criteria:**

**Given** a milestone promotion event (milestone-branch PR merged)
**When** `publish-to-governance` is invoked with initiative domain/service/slug and artifact list
**Then** all listed artifacts are pushed to `governance:artifacts/{domain}/{service}/{initiative}/` via direct push (not PR)
**And** a `_manifest.yaml` is generated and included in the push with: initiative, domain, service, published_at, milestone, lens_version, and artifact file list
**And** artifacts from prior publications are replaced atomically (no stale files from earlier phases)
**And** if the governance remote is not configured, the operation logs a clear warning and continues without hard-failing

---

### Story 3.2: Add Governance Publication Step to Audience-Promotion Workflow

As a module dev agent,
I want the audience-promotion workflow (milestone-branch PR closeout) to invoke `publish-to-governance` after artifact validation,
So that every merged milestone PR automatically propagates artifacts to governance without an extra manual step.

**Acceptance Criteria:**

**Given** a milestone-branch PR (e.g., `foo-bar-auth-techplan` → main) is merged
**When** the promotion workflow closeout logic runs
**Then** `publish-to-governance` is called with all artifacts from `initiative-state.yaml.artifacts`
**And** after the push, governance repo has `artifacts/{domain}/{service}/{initiative}/` with all phase artifacts and `_manifest.yaml`
**And** `initiative-state.yaml` is updated: `last_updated` refreshed, `milestone` confirmed

---

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

## Epic 4 Stories — Initiative Lifecycle Closure

### Story 4.1: Create `/close` Router Workflow

As a @lens agent,
I want a `/close` router workflow with three variants (`--completed`, `--abandoned`, `--superseded-by {initiative}`),
So that project managers can formally end an initiative with the appropriate close state.

**Acceptance Criteria:**

**Given** a user invokes `/close --completed` (or `--abandoned` or `--superseded-by foo`)
**When** the close workflow runs
**Then** the workflow validates `initiative-state.yaml` exists and `lifecycle_status == active`, prompts for close reason text
**And** generates the rich tombstone markdown (domain, service, closed date, status, superseded-by, final milestone, lens version, reason, artifact summary table, phase history excerpt)
**And** publishes the tombstone to `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md` via direct push
**And** `initiative-state.yaml` is updated: `lifecycle_status` set to completed/abandoned/superseded, `superseded_by` set (if applicable), `last_updated` refreshed
**And** a `[CLOSE:{VARIANT}] {initiative} — {reason}` commit marker is committed with the updated YAML

---

### Story 4.2: Add `update-close` and Tombstone Operations to `git-orchestration.md`

As a module dev agent,
I want `git-orchestration.md` to include `update-close` (YAML update) and `publish-tombstone` (governance direct push) operations,
So that `/close` has clean, reusable operations for its two main writes.

**Acceptance Criteria:**

**Given** the `/close` workflow invokes `update-close`
**When** the operation runs
**Then** `initiative-state.yaml` fields `lifecycle_status`, `superseded_by`, and `last_updated` are updated and committed atomically with the CLOSE: marker
**And** `publish-tombstone` pushes the generated tombstone markdown to `governance:tombstones/{domain}/{service}/{initiative}-tombstone.md` via direct push (mirroring publish-to-governance pattern)

---

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

## Epic 5 Stories — Enhanced Cross-Initiative Sensing

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
**And** Pass 2 never fails the gate — all errors are advisory

---

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

## Epic 6 Stories — Self-Service Module Upgrade

### Story 6.1: Add `migrations` Section to `lifecycle.yaml`

As a module dev agent,
I want a `migrations` section in `lifecycle.yaml` with a complete v2→v3 migration descriptor (field renames, new fields, close_states, branch_rename_required),
So that `/lens-upgrade` has a machine-readable specification of every change needed to migrate a control repo.

**Acceptance Criteria:**

**Given** the `lifecycle.yaml` v3 schema is in place
**When** the `migrations` section is added
**Then** it contains a migration entry with `from_version: 2`, `to_version: 3`, `breaking: true`, and a `changes` array including: audience-to-milestone field renames (small→techplan, medium→devproposal, large→sprintplan, base→dev-ready), `add_field: artifact_publication`, `add_field: close_states`, `add_field: initiative_state_schema`, and `branch_rename_required: true`
**And** the `migration_command` field is set to `'/lens-upgrade --from 2 --to 3'`

---

### Story 6.2: Create `/lens-upgrade` Router Workflow

As a @lens agent,
I want a `/lens-upgrade` router workflow that reads migration descriptors and applies them in sequence with a `--dry-run` option,
So that users can preview and execute the v2→v3 migration without manual file editing or branch coordination.

**Acceptance Criteria:**

**Given** a user invokes `/lens-upgrade --dry-run` on a v2 control repo
**When** the dry-run executes
**Then** a complete change list is displayed: field renames, branches to rename, YAML files to update, LENS_VERSION to write — no changes applied

**Given** a user invokes `/lens-upgrade` (without --dry-run)
**When** the upgrade executes
**Then** all field renames are applied to `lifecycle.yaml`, all active initiative audience branches are renamed to milestone token names (git rename + push), all `initiative-state.yaml` files are created or updated with `schema_version: 3`, and `LENS_VERSION` is written to the control repo root
**And** a `[LENS:UPGRADE] migrated from v{N} to v{M}` commit marker is created with all modified files
**And** if versions already match, the workflow reports "Already at current version" and exits cleanly

---

### Story 6.3: Add `validate-branch-name` Precondition to `git-orchestration.md` Push

As a module dev agent,
I want `git-orchestration.md`'s `push` and `create-branch` operations to include a `validate-branch-name` precondition that checks against `lifecycle.yaml` milestone token list,
So that non-conforming branch names are caught at the agent layer before reaching the remote.

**Acceptance Criteria:**

**Given** a push or create-branch operation is invoked with a branch name containing initiative-topology tokens
**When** `validate-branch-name` runs
**Then** it checks that the token suffix matches a recognized milestone token from `lifecycle.yaml` (techplan, devproposal, sprintplan, dev-ready) or that the branch is an initiative root (no token suffix)
**And** if invalid, it FAILS with: `"Invalid branch token '{token}'. Expected one of: {lifecycle.yaml milestone tokens}. Run /lens-upgrade to migrate."`
**And** if valid, it proceeds silently
