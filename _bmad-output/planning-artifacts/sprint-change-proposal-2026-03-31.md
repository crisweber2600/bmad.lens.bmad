---
title: "Sprint Change Proposal: Batch Dev-Story Creation Before /dev"
initiative: lens-module-streamline
date: 2026-03-31
author: '@lens'
trigger_story: 1-1-create-lifecycle-yaml-v3-schema
status: PROPOSED
scope: Minor
---

# Sprint Change Proposal: Batch Dev-Story Creation Before /dev

## Section 1: Issue Summary

**Problem:** `/dev` is designed as an epic-level loop that discovers and iterates ALL story artifacts for a given epic. However, `/sprintplan` step-04 creates only ONE dev-story artifact per run. This means `/dev` can never complete an epic in a single session — it stops after each story because the remaining stories have no artifacts.

**Discovery:** During the first `/dev` run for Epic 1, the story discovery step found only Story 1.1 (`ready-for-dev`). Stories 1.2–1.5 were in `backlog` with no dev-story artifacts. After implementing Story 1.1, `/dev` correctly stopped at the epic completion gate since only 1 of 5 stories was done — but the remaining 4 stories couldn't be worked without separate `/sprintplan` runs for each.

**Evidence:**
- `/sprintplan` step-04 references `{selected_story}` (singular) and creates one dev-story artifact
- `/dev` step-02 discovers stories by glob pattern and expects multiple artifacts per epic
- Sprint-status comment confirms: *"SM typically creates next story after previous one is 'done' to incorporate learnings"*
- The epic-level loop architecture in `/dev` conflicts with the one-at-a-time story creation model

## Section 2: Impact Analysis

### Epic Impact
- **Epic 1 (Reliable Initiative State):** No change to existing stories 1.1–1.5. The gap affects the WORKFLOW that creates story artifacts, not the stories themselves.
- **Epic 2 (Streamlined Branch Topology):** Story 2.5 (Update SprintPlan) naturally touches `/sprintplan`, but its acceptance criteria focus on milestone-model branch changes, not batch story creation.
- **Epics 3–6:** No impact.

### Story Impact
- **Existing stories:** No acceptance criteria changes needed for any current story.
- **New story required:** One new story to update `/sprintplan` step-04 from single-story creation to batch creation for all stories in the target epic.

### Artifact Conflicts
- **PRD:** No conflict — PRD does not specify one-vs-batch story creation cadence.
- **Architecture:** No conflict — architecture defines the `/dev` epic loop but is silent on story creation batching.
- **Sprint-status workflow notes:** The comment *"SM typically creates next story after previous one is 'done'"* must be updated to reflect batch creation.

### Technical Impact
- `/sprintplan` `step-04-dev-story.md`: Must be updated to loop over all stories from the sprint backlog for the selected epic, invoking the `dev-story` workflow for each.
- No code changes — this is a workflow document update (markdown).

## Section 3: Recommended Approach

**Selected path:** Direct Adjustment — add a new story.

**Rationale:**
- The fix is a workflow-document-only change (no code)
- It does not affect any existing story's scope or acceptance criteria
- It aligns `/sprintplan` output with `/dev` input expectations
- It removes the multi-run friction that blocks epic completion in a single `/dev` session

**Effort:** Low (single workflow step modification)
**Risk:** Low (no existing behavior changes; additive loop around existing single-story logic)
**Timeline impact:** None — adds one small story to Epic 2

## Section 4: Detailed Change Proposals

### New Story: 2.7 — Update SprintPlan to Batch-Create All Dev-Story Artifacts Per Epic

**Placement:** Epic 2 (Streamlined Branch Topology), after Story 2.5 which updates SprintPlan to the milestone model. This story builds on 2.5's updated SprintPlan.

**Depends on:** 2.5 (SprintPlan milestone model update)

```markdown
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
```

### Sprint-Status Workflow Notes Update

```
OLD:
# - SM typically creates next story after previous one is 'done' to incorporate learnings

NEW:
# - SM creates all dev-story artifacts for the epic in a single /sprintplan run
# - /dev then iterates the full story set as an epic-level loop
```

### Quick Reference Table Update (stories.md)

Add row to the Quick Reference table:

```
| 2.7 | Update SprintPlan to Batch Dev-Story Creation | Epic 2 | 2.5 |
```

### Epics Update

Add Story 2.7 to Epic 2's story list in `epics.md`.

### Sprint-Status Update

Add the following line under Epic 2 in `sprint-status.yaml`:

```yaml
2-7-update-sprintplan-batch-dev-story-creation: backlog
```

## Section 5: Implementation Handoff

**Change scope:** Minor — single story addition, no existing stories modified.

**Handoff:** Development team (SM creates the dev-story artifact; dev implements the workflow step update).

**Success criteria:**
- Story 2.7 appears in stories.md, epics.md, and sprint-status.yaml
- After Story 2.7 is implemented, `/sprintplan` creates all dev-story artifacts for the target epic in one run
- `/dev` can discover and iterate the full epic story set without stopping for missing artifacts
