---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: []
session_topic: 'lens-work BMAD module streamline — structural redesign'
session_goals: 'Surface improvement ideas across state management, branch topology, initiative lifecycle, cross-domain awareness, and versioning'
selected_approach: 'mixed: Assumption Reversal + What If Scenarios + Reversal Inversion'
techniques_used: [assumption-reversal, what-if-scenarios, reversal-inversion]
ideas_generated: 40
context_file: 'lens-module-streamline preplan'
---

# Brainstorming Session Results

**Facilitator:** @lens
**Date:** 2026-03-26
**Initiative:** lens-module-streamline
**Track:** full

---

## Session Topic

Streamlining the `lens-work` BMAD module — addressing 5 structural pain points around state management, branch topology, initiative lifecycle, cross-domain awareness, and versioning.

## Session Goals

- Surface ideas for relocating initiative state to the governance repo
- Simplify phase/audience branch topology
- Define `/close` command semantics
- Design governance-backed cross-domain awareness
- Design a versioning and migration system for lens-work itself

---

## Ideas Generated (40 total)

### Theme 1: Governance Repo as System of Record

**Pattern:** The control repo is doing too much. Governance should own completed/shared artifacts; control repo owns in-flight work only.

- **#1** Governance repo as initiative registry — not just constitutions, but the active initiative index
- **#6** `git show governance:path/to/file` cross-repo reads without checkout — no branch switching needed
- **#11** Sensing reads governance artifacts (not just branch names) for richer context
- **#12** `lens-governance/artifacts/{domain}/{service}/{phase}/` canonical output store
- **#19** Control repo = in-flight only; governance = completed system of record
- **#21** `git-state` as a unified read interface — consumers never know if data is in control repo or governance
- **#26** Promotion side-effects = governance push — awareness requires zero extra work
- **#31** All governance artifacts = plaintext markdown — `git show governance:path` works universally
- **#36** Governance artifacts use a consistent folder contract: `{domain}/{service}/{initiative}/{phase}/`

### Theme 2: Branch Topology Simplification

**Pattern:** Phase branches are noise. Audience branches should encode lifecycle milestone, not audience size.

- **#3** Audience branches = milestone names: `businessplan`, `techplan`, `pbr`, `dev`
- **#4** Phase = conventional commits, not branches
- **#5** `git log --grep="[PHASE]"` for initiative timeline without reading branch names
- **#6** Phase branch reopening handled via new commits, not branch recreation
- **#22** Branch names = semantic milestones enforced by naming validation at creation time
- **#23** `git-orchestration` owns all topology — no raw git commands escape into workflows
- **#28** Audience ≠ phase — explicit conceptual separation: audience = promotion scope, phase = work type
- **#39** Phase commit tags are machine-readable: `[PHASE:TECHPLAN]`
- **#40** Lightweight `/status` reads purely from branch topology — no pulls, instant

### Theme 3: Initiative Close Command

**Pattern:** Closing is a first-class operation with multiple intent modes and governance side-effects.

- **#7** `/close --completed | --abandoned | --superseded-by {initiative}`
- **#8** Close writes retrospective artifact to governance
- **#9** Dead-branch sensing: abandoned territory as a warning signal for future initiatives
- **#25** `/close` as atomic single command — retrospective + governance archival + branch cleanup
- **#37** Retrospective is a first-class artifact type — part of the close schema, not optional
- **#38** Dead initiatives leave a tombstone in governance — sensing reads tombstones

### Theme 4: Cross-Domain Awareness

**Pattern:** Awareness should be a side-effect of normal workflow, not extra ceremony.

- **#10** Governance as living wiki auto-updated by `/promote`
- **#13** Per-phase pushes to governance at promotion time
- **#14** Cross-domain awareness as push model (commit at phase completion) vs. pull model (query at sensing)
- **#20** Sensing dual-reads: governance for history, control for active conflicts
- **#33** Sensing is a hard gate by default — opt-out requires explicit constitution override
- **#27** Artifact commit = phase completion gating — no artifact? phase not closeable

### Theme 5: Versioning and Migration

**Pattern:** lens-work is a versioned system. Mismatches should be detected early and migrations should be automated.

- **#15** `LENS_VERSION` file + preflight mismatch detection
- **#16** `lens upgrade` automated migration command
- **#17** Per-initiative version pinning
- **#18** Breaking changes require governance constitution entry
- **#24** `LENS_VERSION` compatibility assertion in preflight with named migration path surfaced
- **#34** `/lens-upgrade` declarative migration with pre/post validation
- **#35** `lifecycle.yaml` is the single authoritative source — any workflow duplicating lifecycle logic is a bug

### Theme 6: Systemic Architecture Improvements

**Pattern:** Structural simplifications that cut across all themes.

- **#29** Single `initiative.yaml` schema across all scopes — validated on write
- **#30** Tiered preflight: read commands = lightweight, write commands = full pull+validate
- **#32** Initiative identity = config slug (stable), branch name derived from config (rebuildable)
- **#2** `_bmad-output` disappears entirely — no git-ignored runtime state

---

## Breakthrough Concepts

1. **Unified read interface via `git-state`** — callers never care where data lives; governance migration is transparent to workflows
2. **Audience = milestone, not audience size** — `lens-module-streamline-businessplan` not `lens-module-streamline-small`
3. **Tombstones as sensing artifacts** — abandoned initiatives actively inform future work
4. **Tiered preflight** — lightweight for reads, full for writes; removes current friction on status/next commands
5. **Artifact commit as phase gate** — completion is provable by artifact existence, not by state file

---

## Cross-Cutting Insights

- The "control repo does too much" pattern ties problems 1, 2, 4 together
- Version mismatches (problem 5) are detectable at preflight time with zero additional runtime cost
- `/close` (problem 3) is the missing cleanup gate that prevents sensing noise accumulating forever
- Audience-as-milestone (problem 2) makes the branch name self-documenting and removes the phase branch layer entirely

---

## Recommended for Research Phase

**Domain research targets:**
- How does the current lens-work module implement `git-state` and `git-orchestration`? What would need to change?
- What is the current governance repo schema? How far is it from supporting artifact storage?
- What existing `lifecycle.yaml` fields support versioning? What's missing?

**Technical research targets:**
- Cross-repo `git show` patterns and access models (SSH, HTTPS token)
- Conventional commits spec as a model for phase tagging
- Git tag vs. commit message for machine-readable phase markers
- Branch naming convention validation approaches
