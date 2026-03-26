---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments: ['_bmad-output/brainstorming/brainstorming-session-2026-03-26-001.md']
workflowType: research
research_type: domain
research_topic: 'lens-work BMAD module internal architecture'
research_goals: 'Understand current state management, branch topology, governance integration, and versioning capabilities to inform lens-module-streamline redesign'
date: '2026-03-26'
---

# Domain Research: lens-work BMAD Module Internal Architecture

**Initiative:** lens-module-streamline
**Date:** 2026-03-26
**Researcher:** @lens (codebase-sourced — no web search required; subject is internal)

---

## 1. Current Architecture Overview

`lens-work` is a BMAD module that wraps a git-based initiative lifecycle management system. It governs planning work (preplan → businessplan → techplan → devproposal → sprintplan) across multiple audiences (small → medium → large → base) using branch topology as state, with constitutions in a governance repo providing authority rules.

**Core components:**
| Component | File | Role |
|---|---|---|
| Lifecycle contract | `lifecycle.yaml` | Single source of truth for phases, audiences, tracks, gates |
| Read skill | `skills/git-state.md` | All state derived from git — no runtime files |
| Write skill | `skills/git-orchestration.md` | All git topology operations |
| Sensing skill | `skills/sensing.md` | Cross-initiative overlap detection |
| Constitution skill | `skills/constitution.md` | 4-level governance hierarchy resolution |
| Phase routers | `workflows/router/*/` | One workflow per phase |
| Core workflows | `workflows/core/*/` | Phase-lifecycle, audience-promotion |
| Utility workflows | `workflows/utility/*/` | switch, onboard, discover, status, next |

---

## 2. State Management: Current Model

### Design Axiom
> "Git is the only source of truth. No git-ignored runtime state. No `event-log.jsonl`."

Current state derivation:

| State Query | How Derived |
|---|---|
| Current initiative | Parse HEAD branch name (strip `-{audience}(-{phase})?$`) |
| Current phase | Parse phase suffix from branch name |
| Current audience | Parse audience token from branch name |
| Phase status | PR state: phase branch → audience branch (merged = complete) |
| Promotion status | PR state: source audience → target audience (merged = complete) |
| Active initiatives | `git branch -a` output, unique initiative roots |

### Pain Point Identified
Initiative config (`initiative.yaml`) lives in `_bmad-output/lens-work/initiatives/{path}` — **in the control repo**. This means:
- Config is per-user, not shared across teams
- No cross-repo visibility without checking out the control repo
- Sensing reads branch names, not rich config data from a shared location

---

## 3. Branch Topology: Current Model

```
{initiative-root}                          ← root (created at init)
{initiative-root}-small                    ← audience branch (created at init)
{initiative-root}-small-preplan            ← phase branch (created at /preplan)
{initiative-root}-small-businessplan       ← phase branch (created at /businessplan)
{initiative-root}-small-techplan           ← phase branch
{initiative-root}-medium                   ← audience branch (created lazily at promote)
{initiative-root}-medium-devproposal       ← phase branch
{initiative-root}-large                    ← audience branch (created lazily)
{initiative-root}-large-sprintplan         ← phase branch
{initiative-root}-base                     ← audience branch (created lazily)
```

**Phase completion model:** Phase branch exists + PR from phase branch → audience branch is merged = phase complete.

### Pain Points Identified
1. **Branch explosion**: A single `full`-track initiative generates 9–11 branches
2. **Phase branch names mix audience + phase** — `lens-module-streamline-small-preplan` encodes two pieces of state in one name
3. **No semantic milestone in branch name** — a branch named `-small` doesn't communicate "this is where preplan/businessplan/techplan happened"
4. **Phase branch deletion** requires verifying merged PR before deletion — creates cleanup debt
5. **PR-as-gate requires GitHub/provider** — no offline or lightweight alternative

---

## 4. Governance Repo: Current Model

```
bmad.lens.bmad.governance/
  constitutions/
    org/
    {domain}/
    {domain}/{service}/
    {domain}/{service}/{repo}/
```

Currently the governance repo holds **only constitutions**. It does NOT hold:
- Initiative registry or index
- Phase artifacts or completed outputs
- Cross-initiative awareness data
- Version information

The governance repo is read-only from the `@lens` agent perspective — all writes are done via PRs in the governance repo itself. `constitution.md` skill reads constitutions cross-repo using `git show`.

### Pain Points Identified
1. Governance repo is underutilized — should be the system of record for completed work
2. No artifact publication model at phase completion
3. Sensing reads only branch topology — can't query "what architectural decisions did domain X make?"
4. No initiative registry means no auditability of what has been planned historically

---

## 5. Lifecycle.yaml: Coverage and Gaps

### What it covers
- Phase definitions (name, display_name, agent, artifacts, audience, auto_advance)
- Audience definitions (role, description, phases, entry_gates)
- Track profiles (phases included, start_phase)
- Phase ordering (canonical sequence)
- Adversarial review configuration

### What it does NOT cover
- **Version field**: No `version:` or `schema_version:` field for lens-work itself
- **Migration paths**: No declared migration rules between lifecycle versions
- **Artifact output locations**: No canonical governance artifact path contract
- **Close/archive semantics**: No `close_states:` (completed, abandoned, superseded)
- **Tombstone definition**: No spec for what a closed initiative leaves behind
- **Tiered preflight rules**: Preflight weight is not declared per command type

---

## 6. Existing Versioning Capability

**Current state:** `bmadconfig.yaml` has no version field. `lifecycle.yaml` has no `version:` or `schema_version:`. No `LENS_VERSION` file exists in control repos or release repos.

**What exists:**
- `bmad.lens.release` uses git branches (`alpha`, `beta`, `stable`) for release channel management
- The release repo's `alpha` vs `stable` branch distinction implies versioning is intended but not formalized at the artifact/config schema level

**Gap:** Zero version detection at preflight time. A control repo initialized with v1 configs would run v2 workflows without any warning.

---

## 7. Close/Archive: Current State

**No `/close` command exists.** Initiatives are "closed" implicitly by:
- Abandoning the branch (no commits, no PR)
- Or never — dead branches persist indefinitely

This means:
- Sensing has no way to distinguish "active" from "abandoned" without reading commit timestamps
- The governance repo never learns about abandoned work
- No retrospective artifacts are ever produced

---

## 8. Cross-Initiative Awareness: Current Model

Sensing (`skills/sensing.md`) works by:
1. `git branch -r` to list all remote branches
2. Parse branch names to extract initiative root, domain, service, audience, phase
3. Compare against current initiative to find overlaps
4. Classify: same-feature (high), same-service (medium), same-domain (low)

**Limitations:**
- Only reads branch names — can't read "what did initiative X decide for its architecture?"
- Runs at initiative creation and on-demand only
- Cannot inform cross-domain decisions beyond "conflict exists"
- No history — once a branch is deleted (promotion cleanup), the initiative disappears from sensing

---

## 9. Workflow Count and Complexity

| Category | Workflow Count | Notes |
|---|---|---|
| Phase routers | 6 (preplan, businessplan, techplan, devproposal, sprintplan, dev) | Each has 4–5 steps |
| Core | 2 (phase-lifecycle, audience-promotion) | Shared by all phase routers |
| Governance | 3 (compliance-check, cross-initiative, resolve-constitution) | |
| Utility | 6+ (switch, onboard, discover, status, next, promote) | |
| Includes | 2 (preflight, promotion-check) | Shared includes |

Total: ~19 workflows × avg 4 steps = **~76 step files**. Each step is a markdown file with embedded YAML-like pseudocode.

---

## 10. Key Domain Findings for Redesign

### Finding 1: Git-state is already abstracted
`git-state.md` is a pure read interface — callers don't know where data lives. This is the right abstraction point for transparently migrating initiative config to the governance repo without breaking all callers.

### Finding 2: Branch names are the bottleneck
The current model encodes audience + phase in branch name. Moving to milestone-named audience branches (`-businessplan`, `-techplan`) is a naming convention change that touches `git-state`, `git-orchestration`, branch pattern validation in `lifecycle.yaml`, and all phase router step files.

### Finding 3: Governance repo is git-show-compatible today
Constitution reads already use `git show governance:path`. The same pattern can be extended to initiative config reads and artifact reads without any new infrastructure.

### Finding 4: lifecycle.yaml needs 4 new sections
- `version:` / `schema_version:`
- `artifact_publication:` (governance folder contract)
- `close_states:` (completed, abandoned, superseded)
- `preflight_tiers:` (read vs. write command weight)

### Finding 5: The phase branch → audience branch PR model creates cleanup debt
Every phase creates a branch that must be explicitly deleted after merge. Switching to commit-tagged phases on a milestone branch eliminates this debt entirely — phases become navigable via `git log --grep="[PHASE:TECHPLAN]"` without extra branches.

### Finding 6: No versioning = no safe upgrades
There is no mechanism today to prevent a v2 module running against a v1 control repo config. This is a significant operational risk as the module evolves.

---

## 11. Recommended Research Handoff to Technical Research

For technical research, investigate:
- `git show remote:path` patterns for cross-repo reads at scale (authentication, performance, caching)
- Conventional commits spec as a model for machine-readable phase tagging
- Git tag vs. commit-message for phase markers (tradeoffs: tags are mutable; messages are immutable but require grep)
- Branch naming constraint enforcement in git hooks vs. @lens validation
- Schema migration patterns for YAML config files (e.g., how Helm, kustomize handle schema_version bumps)
