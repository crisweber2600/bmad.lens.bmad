---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-26-001.md'
  - '_bmad-output/planning-artifacts/research/domain-lens-work-architecture-research-2026-03-26.md'
workflowType: research
research_type: technical
research_topic: 'lens-work module v3 redesign — branch topology, governance integration, versioning, and phase tagging'
research_goals: 'Evaluate implementation approaches for the 5 structural improvements identified in brainstorming and domain research, with concrete recommendations on which patterns to adopt'
date: '2026-03-26'
web_research_enabled: false
source_verification: 'codebase-analysis — internal subject only'
---

# Technical Research: lens-work Module v3 Architecture

**Initiative:** lens-module-streamline
**Date:** 2026-03-26
**Research Type:** Technical (codebase-analysis mode — internal subject)

---

## Executive Summary

Six technical questions were surfaced by domain research and brainstorming. This document evaluates each against the existing codebase to produce concrete implementation recommendations. The headline conclusions:

1. **`git show remote:path` is already the primary cross-repo read pattern** — the abstraction exists; extending it to governance artifacts requires only a path contract and auth agreement, not a new mechanism.
2. **Commit message tagging (`[PHASE:X]`) is superior to git tags for phase markers** — tags are mutable and require a separate tag push; commit messages are immutable, already in use via the `[PHASE]` prefix, and `git log --grep` performs a straightforward linear scan over history (O(N)), which is acceptable for our expected repository sizes.
3. **Audience-as-milestone is a complete naming model replacement** — it eliminates the phase-branch layer entirely; `lifecycle.yaml` audience tokens (`small`, `medium`, `large`, `base`) simply get renamed to work-type phase milestones (`techplan`, `devproposal`, `sprintplan`, `dev-ready`).
4. **Branch name validation belongs in `git-orchestration`** — not in hooks; hooks require out-of-band installation; `git-orchestration` is already the sole creation point.
5. **YAML schema migration via `schema_version` in `lifecycle.yaml` is the correct pattern** — `lifecycle.yaml` already has `schema_version: 2`; extending this with migration descriptors follows the same approach used by Helm chartbooks and kustomize manifests.
6. **Governance artifact publication is a side-effect of the existing `commit-artifacts` + `push` pattern** — the path changes; the mechanics do not.

---

## Table of Contents

1. Cross-Repo `git show` Patterns
2. Phase Tagging: Commit Messages vs. Git Tags
3. Audience-as-Milestone: Branch Topology Redesign
4. Branch Naming Enforcement: Hooks vs. Agent Validation
5. YAML Schema Migration for `lifecycle.yaml`
6. Governance Artifact Publication Pattern
7. Implementation Dependency Graph
8. Risk Assessment

---

## 1. Cross-Repo `git show` Patterns

### Current Implementation

`git-state.md` already uses `git show` for cross-branch reads:

```bash
git show "${ROOT}:_bmad-output/lens-work/initiatives/${DOMAIN}/${SERVICE}/${FEATURE}.yaml"
```

`skills/constitution.md` extends this to cross-repo reads:

```bash
git show governance:constitutions/{level}/constitution.yaml
```

`setup-control-repo.sh` currently clones the governance repository as a sibling of the control repo and does not add a `governance` remote by default. To use the `git show governance:…` form, teams should add a `governance` remote in the control repo (for example: `git remote add governance <governance-repo-url>`).

### Extending to Governance Artifacts

The only change required is a **path contract extension**. The current constitution path is:

```
governance:constitutions/{level}/constitution.yaml
```

The proposed artifact path is:

```
governance:artifacts/{domain}/{service}/{initiative}/{phase}/{artifact}.md
```

**Authentication model:** Both SSH and HTTPS work identically for `git show` — it uses the same remote transport that `git fetch` uses. The `governance` remote must have read access from any control repo consumer.

**Performance:** `git show governance:<path>` resolves against locally available refs (for example, `refs/remotes/governance/HEAD`) and does not itself contact the remote. For artifact reads at sensing time, this is O(1) per artifact — no clone, no checkout — assuming the remote-tracking refs are already up to date.

**Caching consideration:** `git show` reads the locally cached view of the remote (such as `governance/HEAD`) at time-of-call, which may be stale if you have not run `git fetch` recently. If stale reads are acceptable (sensing), no additional step is needed. If freshness is critical (phase gate), run `git fetch governance` (or otherwise update the local refs) immediately before the read.

### Technical Verdict

**Extend the existing `git show governance:path` pattern.** No new infrastructure required. Two changes:
1. Add `governance_artifact_root: artifacts/` to `lifecycle.yaml`
2. Add `governance-write` operation to `git-orchestration.md` that writes via `git push governance {artifact_path}`

---

## 2. Phase Tagging: Commit Messages vs. Git Tags

### Conventional Commits Spec Analysis

The Conventional Commits specification defines machine-readable commit messages as:

```
<type>[optional scope]: <description>
[optional body]
[optional footer(s)]
```

This is designed for changelog generation and semantic version bumping. It is well-established but optimized for **incremental change logging**, not **phase milestone marking**.

### Current lens-work Commit Format

`git-orchestration.md` already uses a structured prefix format:

```
[PREPLAN] foo-bar-auth — product brief draft
[TECHPLAN] foo-bar-auth — architecture document complete
[PROMOTE] foo-bar-auth — small→medium promotion artifacts
```

This is not Conventional Commits — it uses `[TYPE]` not `type:`. However it is already machine-parseable.

### Git Tags as Phase Markers

**Option A: Annotated git tags**
```bash
git tag -a "lens/foo-bar-auth/techplan-complete" -m "TechPlan phase complete"
git push origin "lens/foo-bar-auth/techplan-complete"
```

Advantages: Permanent, navigable, don't require log parsing.
Disadvantages: Tags are **mutable** (`git tag -f` replaces without trace), require a separate push step, pollute the global tag namespace, and are difficult to scope per-initiative in a multi-initiative monorepo.

**Option B: Commit message markers (current `[PHASE]` format)**

The existing `[PREPLAN]` prefix already functions as a phase marker. Extending to `[PHASE:TECHPLAN:COMPLETE]` makes the marker machine-parseable at phase completion specifically:

```bash
git log --grep="\[PHASE:TECHPLAN:COMPLETE\]" --oneline foo-bar-auth-small
```

Advantages: Immutable (commits cannot be altered without rebase), already in use, no extra push step needed, naturally scoped to branch (log runs on branch HEAD).
Disadvantages: Requires grep; log must be read for history.

### Technical Verdict

**Extend the existing `[PHASE]` commit message format.** Adopt a 3-part marker for phase completion events:

```
[PHASE:{PHASE_NAME}:{EVENT}] {initiative} — {description}
```

Examples:
```
[PHASE:PREPLAN:COMPLETE] lens-module-streamline — preplan artifacts committed
[PHASE:TECHPLAN:COMPLETE] lens-module-streamline — architecture finalized
[PHASE:PROMOTE:SMALL→BUSINESSPLAN] lens-module-streamline — techplan phase complete, promoting
```

This makes `git log --grep` fully deterministic for phase history reconstruction and preserves the existing format's readability.

---

## 3. Audience-as-Milestone: Branch Topology Redesign

### Current Model Analysis

The current audience model in `lifecycle.yaml`:

```yaml
audiences:
  small:
    role: "IC creation work"
    phases: [preplan, businessplan, techplan]
  medium:
    role: "Lead review"
    phases: [devproposal]
  large:
    role: "Stakeholder approval"
    phases: [sprintplan]
  base:
    role: "Ready for execution"
    phases: []
```

Branch topology generated:
```
foo-bar-auth                 ← root
foo-bar-auth-small           ← audience branch (3 phases here)
foo-bar-auth-small-preplan   ← phase branch
foo-bar-auth-small-businessplan
foo-bar-auth-small-techplan
foo-bar-auth-medium          ← audience branch
foo-bar-auth-medium-devproposal
foo-bar-auth-large           ← audience branch
foo-bar-auth-large-sprintplan
foo-bar-auth-base            ← audience branch
```

Total: **10 branches**

### Proposed Milestone Model

Replace audience name tokens with milestone names. The semantic meaning shifts from "who reviews here" to "what lifecycle gate this branch represents":

```
foo-bar-auth                    ← root
foo-bar-auth-techplan           ← milestone: all work through preplan/businessplan/techplan committed
foo-bar-auth-devproposal        ← milestone: devproposal complete (was "medium")
foo-bar-auth-sprintplan         ← milestone: sprintplan complete (was "large")
foo-bar-auth-dev-ready          ← milestone: ready for execution (was "base")
```

Phase branches are **eliminated entirely**. Phases are now tracked via commit messages on the milestone branch using the `[PHASE:X:COMPLETE]` format above.

**Total branches: 5** (50% reduction)

### Changes Required

| Component | Change |
|---|---|
| `lifecycle.yaml` | Rename `audiences.small/medium/large/base` tokens to milestone names; add `milestone_name` field alongside `role` |
| `git-state.md` | Update branch name parsing regexes from `(small\|medium\|large\|base)` to milestone name list |
| `git-orchestration.md` | Update `create-branch` audience token validation from hardcoded list to `lifecycle.yaml` lookup |
| `git-orchestration.md` | Remove `create-branch` variant for `Phase` type (phase branches no longer exist) |
| `git-state.md` | Update `current-phase` derivation from "parse branch suffix after audience" to "parse git log for most recent `[PHASE:X:COMPLETE]` on current branch" |
| `git-state.md` | Remove `phase-status(phase)` PR query logic (phase branches no longer create PRs) |
| Phase router workflows | Remove "create phase branch" step; add "commit `[PHASE:X:START]` marker" step |
| Phase router workflows | Remove "open PR from phase branch" step; add "commit `[PHASE:X:COMPLETE]` marker" step |

### Migration Path for Existing Initiatives

```bash
# Rename existing audience branches to milestone names
git branch -m foo-bar-auth-small foo-bar-auth-techplan
git branch -m foo-bar-auth-medium foo-bar-auth-devproposal
# Phase branches are merged before migration, so delete post-merge
git branch -d foo-bar-auth-small-preplan  # already merged
```

### Technical Verdict

**Adopt milestone-named audience branches and eliminate phase branches.** The concept separation (audience = who, phase = what work type) was always an internal implementation detail. Milestone names make the branch self-documenting without encoding both concepts into one name.

---

## 4. Branch Naming Enforcement: Hooks vs. Agent Validation

### Option A: Git Pre-Receive / Update Hooks (Server Side)

```bash
# .git/hooks/update
ref=$1
if ! echo "$ref" | grep -qE "^refs/heads/(main|[a-z]+-[a-z]+-[a-z]+(-techplan|-devproposal|-sprintplan|-dev-ready)?)$"; then
  echo "Invalid branch name format"
  exit 1
fi
```

**Advantages:** Enforcement happens at the git layer, preventing any invalid branches from being pushed.
**Disadvantages in this context:**
- Requires installation on a per-repo basis (not declarative)
- GitHub/GitLab server hooks require admin access or custom hook runners
- Lifecycle.yaml milestone names would need to be duplicated in the hook
- Not portable across CI providers without custom infrastructure

### Option B: `git-orchestration` Validation (Current Approach, Strengthened)

`git-orchestration.md` already validates branch names before creation:

```
1. Validate branch name against lifecycle.yaml patterns
2. Check branch doesn't already exist
3. Create from appropriate parent
```

The current implementation validates at agent init time. This needs to be hardened to also validate at any branch push operation.

**Advantages:**
- Already the sole branch creation point — no bypass path exists in normal workflow
- Validation against `lifecycle.yaml` audience/milestone token list is dynamic (not duplicated)
- No infrastructure requirement beyond the agent itself
- `@lens` owns the instruction-following contract; invalid branch names from outside the agent are out-of-scope

### Technical Verdict

**Strengthen `git-orchestration` validation.** Add explicit `validate-branch-name` precondition to the `push` operation in addition to `create-branch`. Server-side hooks are over-engineering for an agent-controlled workflow where all git operations route through `git-orchestration`.

---

## 5. YAML Schema Migration for `lifecycle.yaml`

### Current State

`lifecycle.yaml` already has:
```yaml
schema_version: 2
```

This is the ideal hook point. No new infrastructure needed — just a migration descriptor schema.

### Proposed Migration Pattern (Helm-Inspired)

Add a `migrations` section to `lifecycle.yaml`:

```yaml
schema_version: 3

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

### `LENS_VERSION` File

Add `LENS_VERSION` to the control repo root:
```
3.0.0
```

Preflight detects mismatch:
```bash
LENS_VER=$(cat LENS_VERSION 2>/dev/null || echo "unknown")
EXPECTED_VER=$(grep 'schema_version:' \
  _bmad/lens-work/lifecycle.yaml | awk '{print $2}')
if [[ "$LENS_VER" != "$EXPECTED_VER" ]]; then
  echo "VERSION MISMATCH: control repo is v${LENS_VER}, module expects v${EXPECTED_VER}"
  echo "Run /lens-upgrade to migrate"
  exit 1
fi
```

### `/lens-upgrade` Command Design

```
/lens-upgrade [--from {N}] [--to {M}] [--dry-run]
```

1. Read `LENS_VERSION` (current)
2. Read `lifecycle.yaml` `schema_version` (target)
3. Load migration descriptors from `schema_version.from` to `schema_version.to`
4. For each migration: apply field renames, branch renames, file moves
5. Write `LENS_VERSION` = new version
6. Commit: `[LENS:UPGRADE] {initiative} — migrated from v{N} to v{M}`

### Technical Verdict

**Extend `lifecycle.yaml schema_version` with migration descriptors.** Add `LENS_VERSION` to control repo. Implement preflight version check as a tiered preflight rule (write commands only). `/lens-upgrade` is a new router workflow.

---

## 6. Governance Artifact Publication Pattern

### Current Write Path

`git-orchestration.md` `commit-artifacts`:
```bash
git add "${FILE_PATHS}"
git commit -m "[${PHASE}] ${INITIATIVE} — ${DESCRIPTION}"
git push origin "${CURRENT_BRANCH}"
```

All artifacts live in `_bmad-output/lens-work/initiatives/...` on the current branch.

### Proposed Governance Publication

At phase completion (audience promotion), add a governance push as a side-effect:

```bash
# 1. Copy artifact to governance path
GOVERNANCE_DEST="artifacts/${DOMAIN}/${SERVICE}/${INITIATIVE}/${PHASE}/${ARTIFACT}.md"

# 2. Stage in a temporary worktree or direct push to governance remote
git show CURRENT_BRANCH:${LOCAL_ARTIFACT_PATH} | \
  git -C "${GOVERNANCE_WORKTREE}" hash-object -w --stdin > /tmp/obj

# Or simpler: push via governance remote that has write access:
git push governance HEAD:refs/heads/artifacts-${INITIATIVE}-${PHASE}
```

**Simpler model (preferred):** Use `git worktree` for the governance repo as a sibling directory to the control repo. The governance remote is a full clone, so writes are normal `git add` / `git commit` / `git push`:

```bash
# setup-control-repo.sh already clones governance as a sibling:
git clone git@github.com:org/governance.git ../governance

# At phase completion, @lens writes to the governance worktree:
cp ${LOCAL_ARTIFACT} ../governance/artifacts/${DOMAIN}/${SERVICE}/${INITIATIVE}/${PHASE}/
cd ../governance
git add .
git commit -m "[GOVERNANCE] ${DOMAIN}/${SERVICE}/${INITIATIVE}/${PHASE} — artifact publication"
git push origin main
cd - # return to control repo
```

**New `git-orchestration` operation: `publish-to-governance`**

```yaml
publish-to-governance:
  inputs: [artifact_path, domain, service, initiative, phase]
  algorithm: |
    DEST="${GOVERNANCE_WORKTREE}/artifacts/${domain}/${service}/${initiative}/${phase}/"
    mkdir -p "${DEST}"
    cp "${artifact_path}" "${DEST}"
    cd "${GOVERNANCE_WORKTREE}"
    git add "${DEST}"
    git commit -m "[GOVERNANCE] ${domain}/${service}/${initiative}/${phase} — ${artifact_name}"
    git push origin main
```

### Sensing Integration

`sensing.md` dual-read model at initiative creation:

```bash
# 1. Live conflicts: control repo branch names
active=$(git-state active-initiatives)

# 2. Historical context: governance artifact store
governance_artifacts=$(git show governance:artifacts/${DOMAIN}/ 2>/dev/null || echo "")
```

This gives sensing both real-time overlap detection (branch exists → active) and historical decision context (governance has artifact → completed work, read it for awareness).

### Technical Verdict

**Use governance worktree sibling model with direct push.** Artifacts are considered locked in once the PR merges into the initiative's milestone branch — no separate governance PR review is warranted. Direct push from the control repo to the governance remote is the correct model. Add `publish-to-governance` to `git-orchestration.md`. Update `audience-promotion` workflow to call `publish-to-governance` as a step after artifact validation.

**Tombstone retention:** Permanent. Tombstones are the authoritative record of why a domain/service territory should be treated as having prior history. No expiry logic needed.

---

## 7. Implementation Dependency Graph

```
LENS_VERSION file
    ← preflight version check
        ← tiered preflight (must come first)

lifecycle.yaml v3 schema
    ← milestone-named audiences
        ← git-state branch parsing update
        ← git-orchestration branch creation validation update
        ← phase router step file updates (remove phase branch steps)
        ← close_states field
            ← /close command (new router workflow)

governance artifact path contract
    ← git-orchestration publish-to-governance operation
        ← audience-promotion workflow update
            ← sensing dual-read update

[PHASE:X:EVENT] commit message format
    ← git-orchestration commit-artifacts update (format change)
    ← git-state current-phase derivation update (from log, not branch suffix)
```

**Critical path:** `lifecycle.yaml v3` → all milestone renaming → `git-state` parsing → phase router strip-down

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| In-flight initiatives stranded on old branch names at migration | High | Medium | `/lens-upgrade` applies branch renames; guidance doc for manual cases |
| `git push governance` auth fails in new setup | Medium | High | `setup-control-repo.sh` must add governance remote with write access; test in CI |
| `git log --grep` phase detection misses commits if format changes mid-initiative | Medium | Medium | `git-orchestration` enforces format strictly; if format changes, add `[PHASE:X:COMPLETE-V2]` alias grep |
| Sensing dual-read governance path fails on repos without governance remote | Low | Low | Tiered preflight: sensing gracefully downgrades to branch-only mode if governance remote absent |
| lifecycle.yaml v3 `schema_version` migration descriptors interpreted as live config | Low | High | Add `migrations:` section only at the bottom of lifecycle.yaml; parsers ignore unknown sections |
| Audience token change breaks constitution path resolution | High | Medium | Constitution paths use domain/service/repo levels — not audience names; no conflict |
