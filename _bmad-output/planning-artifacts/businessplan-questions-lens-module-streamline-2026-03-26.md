---
phase: businessplan
initiative: lens-module-streamline
date: '2026-03-26'
status: pre-populated — awaiting user review
---

# BusinessPlan Batch Questions — lens-work Module v3 Streamline

> **Batch Mode Instructions:** This template is pre-populated by the AI agent from your available context documents. Review each section. Sections marked `[derived]` were inferred from your product brief or research. Sections marked `[needs confirmation]` have partial information. Sections marked `[needs input]` require your direct answer. Correct anything that's wrong and fill any blanks, then confirm to proceed.

---

## PART A: PRD FOUNDATION

### A1. Project Identity

| Field | Answer |
|-------|--------|
| **Project Name** | lens-work Module v3 — Streamline `[derived]` |
| **Project Short Name / Codename** | lens-module-streamline `[derived]` |
| **Version** | 3.0.0 `[derived]` |
| **Primary Author** | @lens `[derived]` |
| **Document Date** | 2026-03-26 `[derived]` |

---

### A2. Project Classification

**Project Type** (select one):

- [ ] Web Application / SPA
- [ ] Mobile Application
- [ ] API / Backend Service
- [ ] Developer Tool / CLI
- [x] Internal Platform / Infrastructure Tool `[derived]`
- [ ] Data Pipeline / Analytics Platform
- [ ] Library / SDK / Framework
- [ ] Other: ___________

**Domain** (the business/technical domain this lives in):

```
Domain: BMAD module system — lens-work planning workflow infrastructure [derived]
```

**Project Context:**

- [ ] Greenfield (new product, starting from zero)
- [ ] Brownfield (existing system being enhanced or replaced)
- [x] Ground-up Rebuild (existing system fully replaced with new design) `[derived — architectural model fully replaced, files updated in-place]`

**If Brownfield/Rebuild — describe the existing system being replaced or enhanced:**

```
Existing System Description: [derived]
lens-work v2 — a BMAD module implementing a planning workflow system with:
- 9–11 branches per full-track initiative (root + audience branches + phase branches)
- Audience-named branches: small, medium, large, base encoding review scope
- Phase branches: `{initiative}-small-preplan`, `{initiative}-small-businessplan`, etc.
- Phase gating via PRs from phase branches into audience branches
- Governance repo holding constitutions only (artifacts never published)
- No /close command or tombstone mechanism
- No LENS_VERSION file or schema mismatch detection
- Cross-initiative sensing limited to branch name overlap
```

**Domain Complexity:**

- [ ] Low — well-understood domain, standard patterns apply
- [x] Medium — some domain-specific complexity or regulatory requirements `[derived — git topology, agent instruction-file architecture, migration path]`
- [ ] High — complex domain rules, multi-stakeholder governance, or tightly constrained design space

---

### A3. Executive Summary

**One-paragraph problem statement** (what problem exists and who it affects):

```
Problem Statement: [derived]
The lens-work v2 module generates 9–11 branches per full-track initiative, encoding
both audience and phase in single branch names with unclear semantics. Completed phase
artifacts are never published to the governance repo, leaving it nearly empty and unable
to answer cross-initiative questions. Abandoned initiatives leave no trace — their branches
read as "active" conflicts to sensing, poisoning conflict detection. No /close command
exists. No version protection exists: a control repo running v2 config against a v3 module
produces silent failures. These five structural problems compound as adoption grows.
```

**One-paragraph proposed solution** (what the product does and how it solves the problem):

```
Proposed Solution: [derived]
lens-work v3 replaces audience-name branch tokens (small/medium/large/base) with semantic
milestone names (techplan/devproposal/sprintplan/dev-ready) and eliminates phase branches
entirely, replacing phase-branch PRs with [PHASE:X:COMPLETE] commit markers on the milestone
branch. Governance artifact publication runs at every audience promotion. A /close command
(completed/abandoned/superseded) writes a permanent tombstone to governance. LENS_VERSION in
the control repo and a preflight mismatch check catch version drift before it causes damage.
A /lens-upgrade command with migration descriptors and --dry-run support enables safe module
upgrades. The result is 50% fewer branches, richer cross-initiative awareness, and an auditable
initiative lifecycle.
```

**Key Differentiators** (what makes this distinct from existing approaches):

```
Differentiators: [derived]
1. Branch names encode lifecycle gate achieved (not review audience) — self-documenting topology
2. Full initiative history readable from one branch via git log --grep=[PHASE: — no PR traversal needed
3. Governance repo is a live artifact store queryable without control repo checkout
4. Abandoned work leaves permanent tombstone — sensing distinguishes live from closed initiatives
5. Module upgrades are safe and announced — preflight catches version mismatch before any write
```

**Why Existing Solutions Fall Short:**

```
Gap Analysis: [derived]
v2 encodes two orthogonal concepts (audience, phase) in one branch name, making branch
topology non-self-documenting and generating unnecessary branches. Governance is writable
but unused, creating a structural gap between "where artifacts live" and "where decisions
are recorded." There is no close lifecycle, so git topology never decreases. No upgrade path
means breaking module changes can only be communicated out-of-band.
```

---

### A4. Product Vision

**Vision Statement** (single sentence — the aspirational outcome):

```
Vision: [derived]
A lean, self-documenting planning workflow where any agent can reconstruct
initiative history from a single branch and governance artifacts, with no ghost
work, no version drift, and no branch proliferation.
```

**Mission Statement** (what this product does to achieve the vision):

```
Mission: [derived]
lens-work v3 restructures the branch topology, formalizes artifact publication,
adds a close lifecycle, and introduces version-safe upgrade tooling — making the
module maintainable and queryable at any scale of adoption.
```

**Strategic Alignment** (how this fits into the broader organizational strategy):

```
Strategic Context: [derived]
lens-work v3 is the foundational release that makes the module production-ready
for multi-team adoption. v3.1–v3.3 (cross-initiative query, per-initiative version
pinning, governance registry) can only be built on v3's artifact publication and
closed-lifecycle foundations.
```

---

### A5. Target Users

#### Primary User 1

| Field | Answer |
|-------|--------|
| **Role/Persona Name** | Alex — Solo IC Planner `[derived]` |
| **Context / Role Description** | Engineer or tech lead who runs @lens planning independently before team review; runs full-track initiatives frequently `[derived]` |
| **Primary Phase/Workflow** | All phases: preplan → businessplan → techplan → devproposal `[derived]` |
| **Current Pain Points** | 8+ confusing branches per initiative; can't tell active from abandoned; no historical context from sensing; stale branch confusion after fetch `[derived]` |
| **Success Moment** | 4 branches per initiative; /status shows phase history instantly; sensing surfaces prior governance artifacts on re-entry to a domain `[derived]` |

#### Primary User 2

| Field | Answer |
|-------|--------|
| **Role/Persona Name** | Jordan — Team Lead / Adversarial Reviewer `[derived]` |
| **Context / Role Description** | Reviewer at devproposal stage; pulls PRs, reads artifacts, approves or sends back `[derived]` |
| **Primary Phase/Workflow** | devproposal review `[derived]` |
| **Current Pain Points** | Branch names (foo-bar-auth-medium-devproposal) require domain knowledge to decode; no way to look up prior domain decisions `[derived]` |
| **Success Moment** | PR from foo-bar-auth-techplan → foo-bar-auth-devproposal is self-describing; governance artifacts surface prior decisions without separate research step `[derived]` |

#### Primary User 3

| Field | Answer |
|-------|--------|
| **Role/Persona Name** | Module Maintainer — @lens module team `[derived]` |
| **Context / Role Description** | Team evolving lens-work itself — adding phases, renaming tokens, updating schemas `[derived]` |
| **Primary Phase/Workflow** | Module release, /lens-upgrade execution `[derived]` |
| **Current Pain Points** | Any structural lifecycle.yaml change risks breaking active initiatives silently; no migration tooling; relies on out-of-band communication `[derived]` |
| **Success Moment** | /lens-upgrade with --dry-run previews all changes; control repos get hard preflight errors on version mismatch instead of silent failures `[derived]` |

**Secondary Users** (if any — users who benefit but are not primary drivers):

```
Secondary Users: [derived]
- Future agents reading governance artifacts (v3.1+ cross-initiative query)
- Org-level tooling reading governance registry (v3.3 initiative registry)
```

---

### A6. User Journey Map

**Discovery to First Value Journey:**

```
Step 1 — Discovery: [derived]
  Engineer reads lens-work v3 release notes; sees branch count drops from 10→4.

Step 2 — Onboarding: [derived]
  Runs /lens-upgrade --dry-run on existing control repo; reviews proposed renames.
  Confirms; LENS_VERSION updated; existing audience branches renamed to milestone names.

Step 3 — First Use: [derived]
  Creates new initiative on v3; sees 4 branches instead of 10 in `git branch` output.
  /status reads [PHASE:PREPLAN:COMPLETE] from git log — no PR state querying needed.

Step 4 — Regular Use: [derived]
  At each promotion, governance artifacts are published automatically.
  Closes a stale initiative with /close --abandoned; governance tombstone written.
  New initiative in same domain: sensing reads governance artifacts from prior work.

Step 5 — Mastery: [derived]
  Uses git show governance:artifacts/{domain}/ to query prior decisions without
  checkout. Runs /lens-upgrade --dry-run ahead of module releases to preview impact.
```

**Key Interaction Patterns** (how different users interact day-to-day):

```
Primary interaction patterns: [derived]
- All planning commands routed through @lens agent; no direct git manipulation by users
- Phase state read from git log (not branch names or PR state)
- Governance artifacts published on promotion without user ceremony
- /close used when initiative completes, is abandoned, or is superseded
- Preflight runs on every write command; version mismatch blocks before damage occurs
```

---

### A7. Success Metrics

**User Success Metrics:**

| Metric | Description | Current Baseline | Target |
|--------|-------------|-----------------|--------|
| Branches per full-track initiative | Count of git branches created | 9–11 `[derived]` | 4–5 `[derived]` |
| Time to determine current phase | How long to answer "what phase is this?" | 30–60s (read branches + PR state) `[derived]` | <5s (git log --grep or /status) `[derived]` |
| Historical decisions at sensing | Governance artifacts surfaced when entering a previously-worked domain | 0 (branch names only) `[derived]` | Governance artifacts readable if previously published `[derived]` |
| Abandoned initiative visibility | Percentage of abandonments with tombstone | 0% `[derived]` | 100% via /close `[derived]` |

**Operational/System Metrics:**

| Metric | Description | Current Baseline | Target |
|--------|-------------|-----------------|--------|
| Version mismatch detection rate | % of v-mismatch cases caught before write | 0% `[derived]` | 100% at next write `[derived]` |
| Governance artifact coverage | % of promoted initiatives with artifacts in governance | 0% `[derived]` | 100% on first promotion after v3 `[derived]` |

**Business/Adoption Metrics:**

| Metric | Description | Target |
|--------|-------------|--------|
| /lens-upgrade success rate | % of v2→v3 migrations completing without manual intervention | >90% `[derived]` |
| Control repos on v3 | Adoption count | All new repos from v3 release date `[derived]` |

**Key Performance Indicators (top 3-5):**

```
1. Branch count per initiative: ≤5 [derived]
2. /status phase resolution: <5s [derived]
3. Governance artifact published at every promotion: 100% [derived]
4. /close command used for all initiative terminations: tracked via tombstone count [derived]
5. No silent version mismatch failures: 0 undetected mismatches [derived]
```

---

### A8. MVP Scope

**MVP Philosophy** (select one):
- [ ] Problem-solving MVP — minimum to solve the core problem
- [ ] Experience MVP — minimum to deliver a complete user experience
- [x] Platform MVP — minimum foundation for future extension `[derived — v3.1–v3.3 depend on v3 foundations]`
- [ ] Revenue MVP — minimum to generate/validate revenue

**In-Scope for MVP** (features/capabilities that MUST ship):

```
In scope: [derived]
1. lifecycle.yaml v3 — rename audiences to milestones, add artifact_publication, close_states,
   migrations, preflight_tiers sections
2. LENS_VERSION file in control repo + setup scripts + preflight write-tier check
3. git-state.md — milestone branch name parsing, [PHASE:X] log-based phase derivation,
   remove phase-branch PR query logic
4. git-orchestration.md — remove Phase branch creation, milestone token validation,
   publish-to-governance operation, updated commit message format
5. Phase router step file updates (all 5 phases) — remove create/merge phase branch steps,
   add [PHASE:X:START] and [PHASE:X:COMPLETE] commit markers
6. /close command (new router workflow) — completed/abandoned/superseded variants,
   governance tombstone, cleanup
7. audience-promotion workflow update — publish-to-governance after validation
8. /lens-upgrade command (new router workflow) — migration descriptor execution, --dry-run
9. sensing.md dual-read — live: branch topology; historical: git show governance:artifacts/
```

**Out-of-Scope for MVP** (explicitly deferred with rationale):

| Feature | Rationale for Deferral |
|---------|----------------------|
| Per-initiative version pinning | Complexity vs. value unclear — defer to v3.1 `[derived]` |
| /lens-upgrade interactive conflict resolution | dry-run + apply is sufficient for v3.0 `[derived]` |
| PR-based governance writes | Artifact review gate is the PR merging phases into milestone branch; direct push post-merge is appropriate `[derived]` |
| Multi-remote governance | Single governance remote assumed for v3.0 `[derived]` |
| Automated retrospective generation in /close | Retrospective template provided; content is user-generated `[derived]` |
| Audience promotion timeline visualizer | UX nice-to-have, not blocking `[derived]` |

**MVP Success Criteria** (measurable conditions that define MVP success):

```
Success Criteria: [derived]
1. lifecycle.yaml v3 merged with all milestone renames, artifact_publication, close_states,
   migrations, and preflight_tiers sections present
2. At least one full-track initiative completes preplan→techplan on v3 producing ≤5 branches
3. At least one initiative closure with tombstone published to governance
4. /lens-upgrade successfully migrates at least one v2 control repo to v3 via --dry-run + apply
5. All 5 phase routers updated — no new phase branches created in v3 operation
```

**Feature Roadmap:**

| Phase | Features |
|-------|---------|
| Phase 1 — MVP (v3.0) | Milestone branches, phase commit markers, governance publication, /close, LENS_VERSION, /lens-upgrade, sensing dual-read `[derived]` |
| Phase 2 — Growth (v3.1) | Cross-initiative artifact query (/discover-context), per-initiative version pinning `[derived]` |
| Phase 3 — Vision/Expansion (v3.2–v3.3) | Per-initiative version pinning (v3.2), governance-native initiative registry (v3.3) `[derived]` |

---

### A9. Functional Requirements

**Command / Interaction Requirements:**

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-001 | /close command with --completed, --abandoned, --superseded-by variants | Must-Have | `[derived]` |
| FR-002 | /lens-upgrade command with --dry-run support and migration descriptor execution | Must-Have | `[derived]` |
| FR-003 | /status command reads phase and state directly from initiative-state.yaml (not branch suffix, not git log) | Must-Have | `[derived]` |
| FR-004 | All planning write commands run preflight version check before execution | Must-Have | `[derived]` |
| FR-005 | /switch lists available initiatives by enumerating initiative-state.yaml files, not by parsing branch names; /switch and /discover are read-only with no preflight pull required | Should-Have | `[derived]` |

**State & Data Requirements:**

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-010 | Phase state stored in initiative-state.yaml (committed, YAML-native); [PHASE:{NAME}:{EVENT}] commit markers retained as append-only audit trail only | Must-Have | `[derived]` |
| FR-011 | LENS_VERSION file in control repo root; matches lifecycle.yaml schema_version | Must-Have | `[derived]` |
| FR-012 | lifecycle.yaml v3 includes schema_version, migrations, preflight_tiers, artifact_publication, close_states | Must-Have | `[derived]` |
| FR-013 | Tombstones are permanent — no expiry mechanism | Must-Have | Per user decision `[derived]` |

**Integration Requirements:**

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-020 | publish-to-governance: direct push to governance repo (not PR) | Must-Have | `[derived]` |
| FR-021 | sensing.md reads governance:artifacts/ for historical context via git show | Must-Have | `[derived]` |
| FR-022 | sensing.md gracefully downgrades if governance remote is absent | Should-Have | `[derived]` |
| FR-023 | git-orchestration.md validate-branch-name precondition on push (not just create) | Should-Have | `[derived]` |

**Governance / Compliance Requirements:**

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-030 | All phase artifacts published to governance at audience promotion | Must-Have | `[derived]` |
| FR-031 | /close tombstone written to governance for all termination variants | Must-Have | `[derived]` |
| FR-032 | [PHASE:X:COMPLETE] marker committed with artifact inventory at phase end | Must-Have | `[derived]` |
| FR-033 | git-orchestration.md audience token validation sourced from lifecycle.yaml (not hardcoded) | Must-Have | `[derived]` |

---

### A10. Non-Functional Requirements

**Reliability:**

```
Reliability Requirements: [derived]
- Availability target: N/A — local git-native tool; no service availability requirement
- Error handling approach: Preflight hard-stops on version mismatch; publish-to-governance
  fails loudly (not silently) if governance remote absent; /lens-upgrade --dry-run must
  succeed before --apply is permitted
- Recovery model: All state is git-native; any interrupted operation can be retried or
  rolled back via standard git commands
```

**Performance:**

```
Performance Requirements: [derived]
- Response time targets: /status phase resolution <5s; sensing dual-read adds <2s latency
- Throughput expectations: Per-initiative (not concurrent); no concurrency requirement
- Concurrency model: Single-agent-per-initiative; no concurrent writer assumption needed
```

**Security:**

```
Security Requirements: [derived]
- Authentication model: Inherits git remote auth (SSH keys / HTTPS tokens) — no new auth surface
- Authorization approach: Governance write is direct push; access control is git remote permissions
- Secret management: No secrets in artifacts; LENS_VERSION and lifecycle.yaml are non-sensitive
- Data sensitivity: Planning artifacts (PRDs, architecture docs) may contain internal design
  decisions; governance repo access should mirror control repo access policies
```

**Maintainability:**

```
Maintainability Requirements: [derived]
- Update/upgrade mechanism: /lens-upgrade command with migration descriptors in lifecycle.yaml
- Configuration management: lifecycle.yaml is single config source; schema_version gates all reads
- Logging / observability: [PHASE:X:EVENT] commit markers serve as structured audit log;
  git log --grep is the observability interface
```

**Compatibility:**

```
Compatibility Requirements: [derived]
- Supported platforms/environments: Any environment with git; no OS-specific requirements
- Version compatibility: v3 module supports detection of v2 control repos via LENS_VERSION
  mismatch; does not silently continue with v2 configs
- Migration/upgrade path from previous version: /lens-upgrade applies lifecycle.yaml migration
  descriptors; branch renames executed by the command; phase branches expected to be
  merged before migration (v2 cleanup step in migration descriptor)
```

**Scalability:**

```
Scalability Requirements: [derived]
- Scale model: Designed for multi-initiative, multi-team use; governance repo is shared artifact
  store; no per-initiative storage limits
- Independence / multi-tenancy constraints: Each initiative is independent; governance artifacts
  namespaced under artifacts/{domain}/{service}/ to prevent collision
```

---

## PART B: ARCHITECTURE FOUNDATIONS

### B1. Existing Technical Landscape

**Current Technology Stack** (if brownfield/rebuild — what's being replaced):

```
Current Stack: [derived]
- Language(s): Markdown (agent instruction files), YAML (lifecycle.yaml, bmadconfig.yaml),
  Bash/PowerShell (setup scripts)
- Key frameworks/libraries: BMAD module system; git (all state management)
- Infrastructure: Git repos (control repo, governance repo); no deployed service
- Known technical debt:
  - audience-name branch tokens hardcoded in git-state.md and git-orchestration.md
  - Phase branch creation embedded in all 5 phase router workflows
  - git-state.md derives current-phase from branch name suffix (brittle)
  - sensing.md is branch-name-only (no artifact reads)
  - No version file; no migration tooling
```

**Kept vs Replaced:**

| Component | Keep | Replace | Notes |
|-----------|------|---------|-------|
| lifecycle.yaml (structure) | ✓ | | Add fields; rename audience tokens `[derived]` |
| git-orchestration.md | ✓ | | Remove Phase branch creation; add publish-to-governance `[derived]` |
| git-state.md | ✓ | | Update parsers; add log-grep phase derivation `[derived]` |
| Phase router step files (all 5) | ✓ | | Remove phase branch steps; add commit marker steps `[derived]` |
| audience-promotion workflow | ✓ | | Add governance publication step `[derived]` |
| sensing.md | ✓ | | Add governance dual-read `[derived]` |
| Phase branches | | ✓ | Eliminated entirely — replaced by commit markers `[derived]` |
| Audience-name tokens (small/medium/large/base) | | ✓ | Replaced by milestone names `[derived]` |

---

### B2. Technology Preferences

**Preferred Language(s):**

```
Language preferences: [derived]
- Markdown: agent instruction files (skills, tasks, workflows, steps)
- YAML: lifecycle.yaml, bmadconfig.yaml, module configuration
- Bash/PowerShell: setup scripts only (no new scripting introduced in v3 core)
- No new languages introduced
```

**Preferred Frameworks / Libraries:**

```
Framework preferences: [derived]
- BMAD module system conventions (step-file workflow architecture)
- git CLI (via git-orchestration.md abstraction)
- No external libraries — all behavior is agent instruction-driven
```

**Technology Constraints** (things that MUST or MUST NOT be used):

```
Hard constraints: [derived]
- Must use: YAML state file (initiative-state.yaml) as single source of truth for all initiative runtime state; lifecycle.yaml as module config source-of-truth
- Must NOT use: git hooks for branch enforcement (agent validation is the enforcement layer)
- Must NOT use: external services, databases, or network calls beyond git remotes
- Must NOT use: PR-based governance writes (direct push is the design decision)
- Organizational standards: BMAD module file layout and naming conventions
```

**Build / Package Management Preferences:**

```
Build tooling preferences: [derived]
- No build step; module is a collection of markdown/YAML files
- Setup scripts (sh/ps1) for control repo initialization
- Module distributed as a directory structure; no package manager
```

---

### B3. Deployment & Infrastructure

**Deployment Target:**

- [x] Not applicable (no deployed service — local/git-native tool) `[derived]`
- [ ] Cloud (specify provider): ___________
- [ ] On-premise
- [ ] Hybrid
- [ ] Embedded in existing system

**If deployed — Infrastructure approach:**

- N/A `[derived]`

**CI/CD Approach:**

```
CI/CD: [derived]
Not applicable in the traditional sense. Module release process:
- Module files are updated in the release repo
- Control repos pull updates via /lens-upgrade or manual setup script rerun
- No automated deployment pipeline for the module itself
```

**Environment strategy (dev / staging / prod):**

```
Environments: [derived]
- Module development occurs in the bmad.lens.src repo
- Releases are published to bmad.lens.release repo
- Control repos consume the release version
- No staging/prod distinction at the module level
```

---

### B4. Data & State Architecture

**Primary Data Storage:**

- [x] Git (branches, commits, committed files) — git-native state `[derived]`
- [ ] Relational database (specify): ___________
- [ ] Document store (specify): ___________
- [ ] Key-value store (specify): ___________
- [ ] File system
- [ ] External API / SaaS
- [ ] No persistent state

**State Model:**

```
State derivation approach: [derived]
How is application state determined?
  Step 1 — Identify initiative: the current git branch name is used as a lookup key
    to find the correct initiative-state.yaml. The branch name is NOT parsed for
    structural state (no milestone/phase extraction from the branch string).
  Step 2 — Read state: ALL initiative config and runtime state comes from
    initiative-state.yaml. A single YAML read answers every state question.

  Fields in initiative-state.yaml:
      initiative: foo-bar-auth
      milestone: techplan
      phase: businessplan
      phase_status: in-progress   # in-progress | complete
      lifecycle_status: active     # active | completed | abandoned | superseded
      superseded_by: ~             # initiative name if superseded
      last_updated: 2026-03-26

  initiative-state.yaml is updated by git-orchestration.md at every phase transition
  and committed atomically with any artifact changes in that transition.

/switch behavior:
  - Does NOT enumerate branches to discover available initiatives.
  - Enumerates initiative-state.yaml files in the control repo to list options.
  - User selects by initiative name; agent checks out the corresponding branch.
  - This means /switch works correctly even if branch names are opaque or renamed.

What is the single source of truth?
  - initiative-state.yaml in control repo (all runtime initiative state and config)
  - lifecycle.yaml in module (schema version, milestone names, preflight tiers)
  - LENS_VERSION in control repo (current version binding)
  - Governance repo (published artifacts, tombstones)

Audit trail (not queried for current state):
  - [PHASE:X:COMPLETE] commit markers remain as an append-only git log audit trail
    but are NOT the state query mechanism — initiative-state.yaml is.

What is explicitly NOT stored in state?
  - Phase, milestone, or lifecycle status in branch names (branch = lookup key only)
  - Phase state in PR status or branch existence (eliminated)
  - Any state requiring git-log scanning or branch-name parsing for normal operation
```

**Data Sensitivity / Classification:**

```
Data classification: [derived]
- PII involved: No
- Secret/credential handling: None in module artifacts; git remote auth is external
- Data residency requirements: None — artifacts are planning documents, not user data
```

---

### B5. Integration & API Surface

**External Integrations Required:**

| Integration | Type | Required/Optional | Notes |
|-------------|------|------------------|-------|
| Governance git remote | git push/show | Required | Direct push for artifact publication `[derived]` |
| Control repo git remote | git push/pull | Required | Existing integration `[derived]` |
| lifecycle.yaml | YAML read | Required | Config source for all token and version lookups `[derived]` |

**API Surface (if this product exposes APIs):**

```
API approach: [derived]
- No external API; all interaction is via @lens agent commands
- Internal "API" is the set of agent skill/workflow invocations
- No versioning strategy needed (no external consumers)
```

**Provider Adapter Pattern:**

```
Provider abstraction approach: [derived]
Not applicable. Single git remote model with graceful downgrade if governance remote absent.
```

---

### B6. Key Architectural Decisions

#### Decision 1: Phase State Storage Model

```
Context: [derived]
Phase completion used to be encoded in branch existence (phase branch open = in-progress,
merged = complete). Eliminating phase branches requires a new phase state storage mechanism.

Options Considered:
  A. Git tags (e.g., lens/foo-bar-auth/techplan-complete)
  B. Commit message markers ([PHASE:TECHPLAN:COMPLETE] on milestone branch)
  C. Committed YAML state file (initiative-state.yaml tracking current phase)

Decision: C — Committed YAML state file

Rationale:
- Branch name parsing is brittle and slow — requires string splitting with no schema
- git log --grep scanning is O(N) across commit history; slow for long-lived initiatives
  and requires the caller to interpret the most-recent-event from a log stream
- initiative-state.yaml is a single file read (O(1)), explicitly typed, human-readable,
  and diff-able in PRs — the state change is visible exactly like any other artifact change
- Tags are mutable (git tag -f); commit markers are immutable audit trail but not a clean
  query interface — they require log parsing to reconstruct current state
- YAML is already the config language of the module; no new tooling needed to read it
- The inconsistency risk of option C is mitigated by atomic commits: git-orchestration.md
  updates initiative-state.yaml in the same commit as any artifact or marker change,
  so state and artifacts are always in sync at any commit boundary
- The git branch is still used as a lookup key to identify which initiative is active,
  but no state is derived from parsing the branch name itself — it points to the YAML

Consequences:
- initiative-state.yaml added as a committed file in the control repo per initiative
- git-state.md state derivation: branch name → identify initiative → read YAML;
  no branch-suffix parsing; no git log scanning in normal operation
- /switch enumerates initiative-state.yaml files (not branches) to list options;
  checking out the branch is a side effect of selecting an initiative, not the lookup
- [PHASE:X:COMPLETE] commit markers are retained as append-only audit trail in git log
  but are not the query path for current state
- /status and preflight read YAML; no git log scanning in the hot path
- initiative-state.yaml must be committed atomically with each phase transition
```

#### Decision 2: Branch Topology Redesign

```
Context: [derived]
v2 encodes two concepts (audience = who reviews, phase = work type) in one branch name,
producing 9–11 branches and requiring domain knowledge to decode.

Options Considered:
  A. Keep audience names; reduce phase branches only
  B. Replace audience names with milestone names; eliminate phase branches
  C. Keep current model; add a phase-state YAML file only

Decision: B — Milestone names + phase branches eliminated [derived]

Rationale: [derived]
- Milestone names (techplan/devproposal/sprintplan/dev-ready) are self-documenting
  without domain knowledge of the audience model
- Reducing from 10 to 4–5 branches is the primary user-visible improvement
- Option A is half-measure; still requires understanding small/medium/large/base
- Option C does not improve branch topology at all

Consequences: [derived]
- lifecycle.yaml audience tokens renamed
- git-state.md and git-orchestration.md parsers updated to milestone token list
- All 5 phase router workflows updated to remove phase branch create/merge steps
- Existing v2 control repos require branch rename via /lens-upgrade
```

#### Decision 3: Governance Write Model

```
Context: [derived]
Governance artifacts need to be published at audience promotions. Two models:
PR-based (artifact goes through review gate in governance) vs. direct push (artifact
published after the milestone branch PR has already been reviewed and merged).

Options Considered:
  A. PR-based governance writes — each artifact publication creates a governance PR
  B. Direct push to governance — artifacts published directly after milestone PR approval

Decision: B — Direct push [derived]

Rationale: [derived]
- The artifact review gate is the PR that merges phase work into the milestone branch.
  Once merged, artifacts are locked-in and propagate to governance without additional ceremony.
- PR-based governance writes would add a second review step for content already reviewed.
- Direct push is simpler, faster, and removes friction from the governance publication path.

Consequences: [derived]
- git-orchestration.md publish-to-governance is a push operation (not PR creation)
- Governance repo write access required for the agent identity performing promotions
- Trust model: governance artifacts are as-reviewed in the milestone PR; no separate governance review
```

#### Decision 4: Branch Naming Enforcement

```
Context: [derived]
With milestone names replacing hardcoded audience tokens, branch name validation needs to
be dynamic (sourced from lifecycle.yaml). Options: server-side git hooks vs. agent-layer validation.

Options Considered:
  A. Git pre-receive/update hooks on the remote
  B. agent-layer validation in git-orchestration.md (current approach, strengthened)

Decision: B — Strengthen git-orchestration validation [derived]

Rationale: [derived]
- git-orchestration.md is already the sole branch creation point; no bypass path exists
  in normal workflow
- Server-side hooks require per-repo installation, admin access, and lifecycle.yaml duplication
- Dynamic validation against lifecycle.yaml milestone token list is more maintainable
- Out-of-band branch creation (bypassing @lens) is out-of-scope for v3 enforcement

Consequences: [derived]
- validate-branch-name precondition added to push operation as well as create-branch
- Validation looks up milestone token list from lifecycle.yaml at runtime
- Server-side enforcement is explicitly deferred as over-engineering
```

#### Decision 5: YAML Schema Migration Pattern

```
Context: [derived]
lifecycle.yaml has schema_version: 2. v3 renames fields. Control repos need a safe upgrade
path that doesn't require manual edits.

Options Considered:
  A. Helm-style migration descriptors in lifecycle.yaml (migrations section)
  B. Separate migration script per version pair
  C. Manual migration instructions in release notes only

Decision: A — Migration descriptors in lifecycle.yaml + /lens-upgrade command [derived]

Rationale: [derived]
- Declarative migration descriptors are versioned alongside the schema they describe
- /lens-upgrade reads descriptors and executes them deterministically
- --dry-run reduces migration risk
- Option B (separate scripts) violates single-source-of-truth; option C is error-prone

Consequences: [derived]
- lifecycle.yaml v3 gains migrations section with from_version, to_version, breaking flag,
  and change descriptors
- /lens-upgrade is a new router workflow that reads and applies migration descriptors
- LENS_VERSION in control repo tracks current version binding
```

#### Decision 6: Tombstone Retention Policy

```
Context: [derived]
When an initiative is closed, a tombstone is written to governance. Should tombstones expire?

Options Considered:
  A. Permanent tombstones — never removed from governance
  B. Time-bounded tombstones — auto-expire after N months
  C. Manual cleanup — maintainer removes tombstones manually

Decision: A — Permanent tombstones [derived — per explicit user decision]

Rationale: [derived]
- Tombstones are the historical record that an initiative existed, was worked on, and why it ended.
- Sensing needs to distinguish "active" from "closed" indefinitely; expiring tombstones recreates
  the ghost-work problem v3 is solving.
- Permanent storage cost is negligible (markdown files in git).

Consequences: [derived]
- Governance repo tombstone count grows monotonically
- /close --superseded-by cross-references the superseding initiative; tombstone is still permanent
- No tombstone cleanup mechanism implemented in v3
```

---

### B7. Architecture Patterns & Principles

**Primary Architectural Pattern:**

- [ ] Modular Monolith
- [ ] Microservices
- [ ] Event-driven
- [x] Plugin / Extension architecture `[derived — BMAD module system]`
- [ ] Pipe-and-filter
- [ ] Layered / N-tier
- [ ] Other: ___________

**Key Design Principles for this system:**

```
Principles (in priority order): [derived]
1. YAML as single source of truth — initiative-state.yaml owns all runtime state;
   lifecycle.yaml owns all module config; no state encoded in branch names or log grep
2. Git-native durability — all state files are committed in git; no external databases;
   any state is reproducible from a git checkout alone
3. Self-documenting topology — branch names encode what was achieved, not who reviewed it
4. Explicit over silent — version mismatches, governance errors, and phase transitions are
   announced loudly; silent failure is not acceptable
5. Minimal ceremony — governance publication happens automatically at promotion;
   users do not add extra steps
```

**Cross-Cutting Concerns:**

```
Error handling approach: [derived]
  Hard failures: preflight version mismatch, invalid branch name, governance push failure
  — all should stop execution and surface a clear error message with remediation steps.
  Graceful downgrade: governance remote absent → sensing falls back to branch-only mode
  (no error, informational note only).

Logging / observability approach: [derived]
  [PHASE:X:EVENT] and [CLOSE:*] commit markers are the structured audit log.
  git log --grep is the query interface. No external logging.

Security boundary enforcement: [derived]
  Git remote permissions govern governance write access.
  No role-based enforcement at the module layer (out of scope).

Configuration management: [derived]
  lifecycle.yaml is the single config file. schema_version gates all config reads.
  LENS_VERSION in control repo is the version binding.
```

---

### B8. Module / Component Structure

**High-Level Component Map:**

```
[derived]
[lifecycle.yaml v3] — schema, milestone names, preflight tiers, artifact publication config,
                      close states, migration descriptors
[LENS_VERSION] — control repo version binding file (written by setup-scripts and /lens-upgrade)
[initiative-state.yaml] — per-initiative committed state file; fields: initiative, milestone,
                           phase, phase_status, lifecycle_status, superseded_by, last_updated;
                           single source of truth for all runtime state reads
[git-state.md] — reads initiative-state.yaml for all state queries; no branch-name parsing
                  or git-log scanning in normal operation
[git-orchestration.md] — branch create/push/validate, commit-artifacts (including atomic
                          initiative-state.yaml update), publish-to-governance
[phase router step files (5)] — preplan, businessplan, techplan, devproposal, sprintplan
                                workflow steps; now use commit markers instead of phase branches
[audience-promotion workflow] — milestone PR + governance publication trigger
[/close workflow] — tombstone generation, governance write, close marker commit
[/lens-upgrade workflow] — migration descriptor application, LENS_VERSION update
[sensing.md] — branch topology read + governance dual-read for historical context
[setup-control-repo.sh/.ps1] — LENS_VERSION initialization on new control repo setup
```

**Component Dependencies / Interaction Map:**

```
[derived]
[phase router steps] → [git-orchestration.md]: commit-artifacts (atomic with state update), create-branch
[phase router steps] → [git-state.md]: read current phase, initiative, milestone level
[audience-promotion workflow] → [git-orchestration.md]: publish-to-governance, create milestone branch
[/close workflow] → [git-orchestration.md]: publish-to-governance (tombstone), update initiative-state.yaml (lifecycle_status)
[/lens-upgrade workflow] → [lifecycle.yaml]: read migrations section; write back to lifecycle.yaml
[/lens-upgrade workflow] → [git-orchestration.md]: branch rename, LENS_VERSION commit
[sensing.md] → [git-orchestration.md]: git show governance:artifacts/ (new read operation)
[preflight (all write commands)] → [LENS_VERSION + lifecycle.yaml]: version mismatch check
[git-state.md] → [initiative-state.yaml]: direct YAML read for all state queries (no log scanning)
[git-state.md] → [lifecycle.yaml]: milestone token list lookup (for validation)
[git-orchestration.md] → [lifecycle.yaml]: validate-branch-name milestone token lookup
[git-orchestration.md] → [initiative-state.yaml]: atomic update on every phase transition commit
```

**Authority Boundaries:**

```
[derived]
Module authority (bmad.lens.src / bmad.lens.release): lifecycle.yaml, all skill/workflow/step files
Control repo authority: LENS_VERSION, initiative yamls, committed planning artifacts
Governance repo authority: published artifacts under artifacts/, tombstones under tombstones/
```

---

### B9. Migration & Compatibility Strategy

**Migration from Previous Version:**

```
Migration approach: [derived]
- User-facing migration steps:
  1. Pull latest module release
  2. Run /lens-upgrade --dry-run → review proposed changes
  3. Run /lens-upgrade (apply) → field renames in lifecycle.yaml, branch renames applied,
     LENS_VERSION updated, migration commit created
  4. All active initiatives: audience branches auto-renamed to milestone names
  5. Phase branches: expected to be merged before migration; remnant phase branches
     are cleaned up as part of /lens-upgrade (listed by --dry-run)
- Data / state migration: lifecycle.yaml field renames applied by migration descriptors
- Backward compatibility commitments: v3 module does NOT support v2 configs silently;
  preflight will hard-stop on version mismatch until /lens-upgrade is run
- Breaking changes: All audience branch names change; phase branches eliminated;
  [PHASE:] commit message format changes from [PREPLAN] to [PHASE:PREPLAN:COMPLETE]
```

**Version/Release Strategy:**

```
Release model: [derived]
- Versioning scheme: Semantic versioning (3.0.0); schema_version in lifecycle.yaml
  matches major version number
- Pinning / update model: Control repos bind to a version via LENS_VERSION; no automatic
  updates; explicitly upgraded via /lens-upgrade or setup script rerun
- Deprecation policy: v2 support removed at v3 release; preflight enforces version
  currency; no long-term v2 compatibility shim
```

---

### B10. Open Architecture Questions (Deferred to TechPlan)

```
Open Decisions (to resolve in /techplan): [needs confirmation — do you want to add any?]
1. Exact governance artifact directory structure under artifacts/{domain}/{service}/
   (flat vs. phase-namespaced; versioning of artifact files)
2. Exact [PHASE:X:COMPLETE] commit marker format for artifact inventory
   (inline list in commit body vs. separate artifact-manifest file committed alongside)
3. /close tombstone file format and required fields
   (minimal: initiative, close-type, date, reason; or richer: artifact links, superseded-by ref)
4. [needs input] Any additional architectural questions you want deferred to TechPlan?
```

---

## PART C: REVIEW CONFIRMATION

All sections above are pre-populated from the product brief and research documents. Review these areas in particular:

**Sections needing your attention:**
- **B10** — Open architecture questions deferred to TechPlan: verify the 3 listed items are correct, and add any others
- Any `[needs confirmation]` markers throughout
- Any values you want to override or refine

When you have reviewed all sections and are satisfied, confirm:

```
"All answers reviewed and confirmed — ready to generate artifacts."
```
