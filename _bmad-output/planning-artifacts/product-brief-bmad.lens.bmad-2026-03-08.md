---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments: ['_bmad-output/brainstorming/brainstorming-session-2026-03-08-001.md', 'Reference/bmad.lens.release/_bmad/lens-work']
date: 2026-03-08
author: CrisWeber
---

# Product Brief: bmad.lens.bmad

## Executive Summary

**lens-work v2** is the front door to BMAD — a single git-based control repository where developers, tech leads, architects, product owners, and scrum masters start all work across every domain and service. It provides lifecycle orchestration through familiar phase commands (`/preplan` through `/dev`), automated git branch topology, governance gates via pull requests, and batch-first execution that produces complete artifacts in one pass.

v1 proved the core model works: phase-routed commands, PR-as-PBR (pull requests as product backlog refinement), and multi-audience governance gates deliver real value. But v1 also revealed systemic flaws — a git-ignored state file that contradicted the git-native design, manual discovery that nobody exercised, 60+ workflows behind 11 user touchpoints, orphaned infrastructure (JS libs, unused prompts), and white-glove update distribution that made the module author a single point of failure.

v2 is a ground-up rebuild on five axioms: git as the only source of truth, PRs as the only gating mechanism, explicit authority domains with hard boundaries, automatic cross-initiative sensing, and the control repo as an operational workspace. The result: the same familiar commands, dramatically fewer moving parts (~16 workflows vs. ~60), batch-mode execution by default with per-workflow preference learning, self-service dependency updates, and a system where onboarding means "clone, onboard, and run."

---

## Core Vision

### Problem Statement

Software teams need a disciplined lifecycle system that enforces governance, tracks phase progression, and coordinates cross-initiative work across domains and services — all through git, the tool they already use. Today, getting started with BMAD lifecycle management requires white-glove guidance: manually switching folders, pulling branches across multiple repos, and recovering from broken state when things go wrong. The system meant to provide discipline instead creates friction and bottlenecks.

This affects everyone on the team — developers writing code, tech leads reviewing proposals, architects designing systems, product owners defining requirements, and scrum masters managing sprints. Each role interacts with different lifecycle phases, but all need the same reliable, self-service entry point.

### Problem Impact

- **Module author is a single point of failure** — every lens-work update requires personal guidance to switch folders, change branches, and git pull across multiple repos. If the author is unavailable, nobody updates. This bottleneck doesn't scale.
- **Onboarding breaks easily** — SetupRepo runs once, but recovery from failure is hard and opaque. New team members get stuck and need rescue.
- **State corruption is systemic** — a git-ignored `state.yaml` contradicts the git-native design, causing staleness that cascades into 9 repair workflows that themselves add complexity.
- **Cross-initiative blind spots** — discovery was manual and never exercised; teams can't see what other initiatives touch the same domain or service until conflicts surface late.
- **Infrastructure bloat without proportional value** — 60+ workflows, 47 prompts, 33 JS files, 34 test files behind ~11 user touchpoints. A 6:1 infrastructure-to-feature ratio that burdens maintenance without delivering user value.

### Why Existing Solutions Fall Short

No existing tool fills this niche. Git branching strategies (git-flow, trunk-based development) provide structure but no lifecycle governance — they don't know what a "preplan phase" is or enforce that planning artifacts exist before code is written. Project management tools (Jira, Azure DevOps, Linear) track work items but don't orchestrate the actual artifact creation or enforce governance at the PR level. These tools complement lens-work but cannot replace it.

v1 lens-work proved the model itself is sound but couldn't sustain its own complexity. The fundamental contradiction — building on git-as-truth while using a git-ignored file as the source of truth — made state management inherently fragile. Attempts to compensate (dual-write patterns, sync workflows, repair utilities) created more failure vectors rather than fewer.

### Proposed Solution

lens-work v2 rebuilds from first principles with five non-negotiable design axioms:

1. **Git is the only source of truth for shared workflow state** — no `state.yaml`, no git-ignored runtime state. Initiative state is derived from branch existence, PR metadata, and committed configs. Machine-local secrets stay outside git in provider or OS credential storage.
2. **PRs are the only gating mechanism** — review, approval, promotion, and compliance all happen through pull requests. No side-channel approval.
3. **Explicit authority domains** — four domains (Control Repo, Release Module, Copilot Adapter, Governance Repo) with hard boundaries. Every file belongs to exactly one authority. Cross-authority writes are forbidden.
4. **Automatic sensing** — cross-initiative awareness triggers at lifecycle gates automatically, not through manual discovery commands nobody runs.
5. **Batch-first execution with preference learning** — all phase workflows execute end-to-end producing complete artifacts in one pass, with a review session at the end. After completion, the system asks users if they want batch as their default for that specific workflow — building a per-workflow preference profile over time. Only brainstorming (interactive by nature) and dev (requires human judgment) default to interactive.
6. **Automatic PR creation is retained as a first-class feature** — when a phase bundle is reviewable, lens-work opens the phase PR automatically with the required metadata. Promotion PRs are also created automatically once their prechecks pass. Review and merge remain gated.

The command surface stays identical (`/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/dev`). The release module is a pinned read-only dependency with a documented self-service update flow. Onboarding is: clone the control repo, run `/onboard`, start working.

### Key Differentiators

- **The front door to BMAD** — one control repo to start all work across all domains and services. No folder switching, no branch hunting, no multi-repo coordination.
- **Git branch topology is the lifecycle tracker** — no external state, no database, no state files. The entire project lifecycle is reconstructable from branch topology, committed artifacts, and PR metadata in the configured provider.
- **PR-as-PBR** — product backlog refinement happens as pull request reviews, not meetings. Artifact diffs, approval workflows, and branch naming deliver governance without ceremony.
- **Automatic PR creation at lifecycle handoffs** — phase completion and audience promotion open the next required PR automatically, so users do not drop work on the floor between artifact creation and review.
- **Four authority domains with hard boundaries** — Control Repo (operational workspace), Release Module (read-only dependency), Copilot Adapter (thin IDE wiring), and Governance Repo (constitutional authority). Cross-authority writes are forbidden, eliminating the drift and staleness that plagued v1.
- **Batch-first with per-workflow preference learning** — phase commands produce complete artifacts in one pass with intelligent defaults, followed by focused review. Users progressively teach the system their preferred interaction mode for each workflow type.
- **Self-service module updates** — the release module is a pinned read-only dependency that users update through a documented workflow instead of white-glove guidance. Commands stay the same across versions.
- **Constitutional governance without bureaucracy** — four-level constitution hierarchy (org → domain → service → repo) with language-specific variants, enforced at PR gates automatically.

---

## Target Users

### Primary Users

#### Developer (e.g., "Dana")

**Role & Context:** Individual contributor writing code across one or more domains. Uses the control repo daily as their workspace for both planning contributions and implementation.

**How They Experience lens-work:**
- Primary phase: `/dev` — receives story specs, works on implementation branches
- Uses `/switch` to move between active initiatives
- Uses `/status` and `/next` to understand what to work on
- Contributes to earlier phases when working on solo or small-team initiatives

**Current Pain:**
- Doesn't know which branch to be on or what to work on next
- Switching between initiatives means manual folder/branch juggling
- When state breaks, recovery is opaque — needs rescue from admin

**Success Moment:** Runs `/next`, gets a clear directive, switches to the right branch, and starts coding — all without asking anyone.

---

#### Tech Lead (e.g., "Tara")

**Role & Context:** Senior IC who both creates and reviews. Runs `/techplan` and `/devproposal` phases. Reviews PRs at the medium audience gate (adversarial review). Spans multiple initiatives within a domain.

**How They Experience lens-work:**
- Creates architecture artifacts and implementation proposals
- Reviews PRs at promotion gates — sees artifact diffs, constitution compliance
- Needs cross-initiative visibility to spot conflicts before approving

**Current Pain:**
- Needs to see what's changed across initiatives in the domain before approving a promotion
- Manual discovery means conflicts surface too late
- Updates to lens-work require switching repos and pulling branches manually

**Success Moment:** Opens a promotion PR, sees the sensing report flagging a related initiative, and coordinates before approving — without anyone telling her to check.

---

#### Architect (e.g., "Arun")

**Role & Context:** Owns technical design across services. Drives `/techplan` phase. Participates in cross-initiative sensing and constitution governance. May own domain-level constitutions.

**How They Experience lens-work:**
- Creates architecture documents during techplan
- Reviews cross-initiative sensing reports at promotion gates
- Contributes to governance — writes and updates constitutions

**Current Pain:**
- Multiple initiatives touch the same services and nobody coordinates until it's too late
- Constitution governance exists but compliance checking is manual
- Cross-initiative discovery was never exercised in v1

**Success Moment:** Runs `/techplan`, sensing automatically flags two other initiatives in the same service, and the architecture accounts for all three from the start.

---

#### Product Owner (e.g., "Priya")

**Role & Context:** Drives business planning. Runs `/preplan` (product brief, research) and `/businessplan` (PRD, UX). Approves at the large audience gate (stakeholder approval).

**How They Experience lens-work:**
- Creates product briefs and PRDs through batch-mode workflows
- Reviews and approves promotion PRs at stakeholder gate
- Needs status visibility across all initiatives in their domain

**Current Pain:**
- Needs planning artifacts to exist and be reviewed before anyone starts coding, but enforcement is inconsistent
- Phase status is hard to assess without digging through branches
- Batch mode didn't exist in v1 — long interactive sessions were fatiguing

**Success Moment:** Runs `/preplan`, gets a complete product brief in one pass, reviews and tweaks, then sees the phase PR auto-created with constitution compliance metadata — all in one session.

---

#### Scrum Master (e.g., "Sam")

**Role & Context:** Manages sprint execution. Runs `/sprintplan` phase. Creates stories, tracks sprint status, coordinates across initiatives.

**How They Experience lens-work:**
- Creates sprint plans and user stories
- Uses `/status` to monitor all active initiatives
- Coordinates promotion timing across multiple initiatives

**Current Pain:**
- Needs to know where every initiative stands without digging through branches
- Sprint planning requires manual cross-referencing between initiatives
- State corruption in v1 made status reports unreliable

**Success Moment:** Runs `/status`, gets a single view of all active initiatives with phases, audiences, and pending PRs — derived from branch topology and PR metadata without branch/state drift.

---

#### BMAD Admin (e.g., "Alex")

**Role & Context:** Sets up and maintains the control repo. Responsible for onboarding, module updates, governance repo configuration, and troubleshooting. May be the module author or a designated platform lead.

**How They Experience lens-work:**
- Runs initial `SetupRepo` and configures governance
- Onboards new team members
- Manages release module updates (currently white-glove)
- Troubleshoots broken state, failed setups, recovery situations

**Current Pain:**
- Is a single point of failure for updates — personally guides every user through folder switches and git pulls across repos
- Recovery from broken state is hard and requires deep system knowledge
- Onboarding failures are opaque and require manual intervention

**Success Moment:** Release module updates through a documented self-service flow. New team member clones, runs onboarding, and is productive within minutes — without Alex touching anything.

---

### Secondary Users

N/A — All identified roles are primary users of the system. The onboarding workflow scopes each user to their domain, so the system naturally adapts to each role's focus area.

### User Journey

**Discovery → Onboarding → Daily Use → Mastery**

1. **Discovery:** Team member is added to the control repo. They clone it.
2. **Onboarding:** Run `/onboard` — profile created (role, domain, provider context, non-secret preferences). Auth is validated through the configured provider or OS credential store, and TargetProjects are bootstrapped automatically.
3. **First Phase:** User runs their first phase command (e.g., `/preplan`). Batch mode executes end-to-end. At completion, asked if batch should be their default for this workflow. **Exception:** Brainstorming never uses batch mode — it is inherently interactive and requires real-time creative dialogue.
4. **Daily Use:** `/next` and `/status` become the entry points. `/switch` moves between initiatives seamlessly. PR reviews happen naturally in the configured provider (GitHub or Azure DevOps).
5. **Mastery:** User has per-workflow batch preferences dialed in. Cross-initiative sensing reports are routine. Governance gates are transparent — constitution compliance just works at PR time.

---

## Success Metrics

### User Success Metrics

| Metric | Description | v1 Baseline | v2 Target |
|--------|-------------|-------------|-----------|
| **Self-service rate** | % of operations completed without admin intervention | Low — most updates and recovery required white-glove support | >=95% for supported workflows |
| **Onboarding completion** | New user: clone → onboard → first phase command without help | Fragile — SetupRepo failures required manual rescue | >=90% first-run success with no admin rescue |
| **Command reliability** | Phase commands, `/status`, `/switch` succeed without errors | State corruption caused unpredictable failures | >=95% for supported commands when git and provider auth are healthy |
| **Time-to-first-artifact** | Time from onboarding to completing first phase output | Multiple sessions, interactive step-by-step | Single guided session — batch mode produces a reviewable first artifact set |

### Operational Success Metrics

| Metric | Description | v1 Baseline | v2 Target |
|--------|-------------|-------------|-----------|
| **No white-glove updates** | Module updates no longer require admin intervention | Every update hand-guided per user | Documented self-service update flow for every supported repo |
| **State accuracy** | System state matches reality | Frequent drift — git-ignored `state.yaml` went stale | Deterministic from branch topology, PR metadata, and committed artifacts; no local state drift class |
| **Repair workflow count** | Number of repair/recovery workflows needed | 9 repair workflows shipped | Zero — no state to corrupt means nothing to repair |
| **Infrastructure-to-feature ratio** | Files behind user touchpoints | ~60 workflows / ~11 commands = 6:1 | ~16 workflows / ~11 commands = 1.5:1 |

### Adoption Success Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| **Phase completion rate** | % of initiatives that progress through their full lifecycle track | Initiatives move through phases to completion, not stall |
| **Cross-initiative sensing utilization** | Sensing reports generated at promotion gates | 100% — automatic at every promotion, not opt-in |
| **Role coverage** | All onboarding roles (Developer, Tech Lead, Architect, PO, SM, Admin) actively using lens-work | Company-wide adoption across all roles |
| **Domain coverage** | Active initiatives across all org domains | Expanding from current users to full organizational adoption |
| **Batch preference adoption** | % of users who opt into batch-default after first experience | High — indicates batch mode delivers value |

### Business Objectives

This is an internal tooling play — success is measured by adoption and operational efficiency, not revenue.

- **Current users:** Existing lens-work users migrate to v2 with low-friction, documented upgrade steps. Same core phase commands, better reliability, no white-glove dependency.
- **Company-wide adoption:** New teams onboard independently. The control repo becomes the standard entry point for all BMAD lifecycle work across the organization.
- **Admin overhead elimination:** The BMAD Admin role shifts from "manual update distributor and state repair technician" to "governance curator and onboarding support" — strategic instead of operational.

### Key Performance Indicators

1. **Zero white-glove updates** — every release module update follows the documented self-service flow
2. **Zero local state-desync incidents** — no user hits branch/state mismatch caused by local runtime files
3. **Sub-5-minute onboarding** — clone to first phase command in under 5 minutes
4. **100% sensing coverage** — every promotion gate includes cross-initiative sensing
5. **Company-wide active usage** — all domains have at least one active initiative managed through lens-work

---

## MVP Scope

### Core Features

**Foundation (Design Axioms — everything else is built on these):**

1. **Git-derived state model** — no `state.yaml`. State derived from branch existence, PR metadata, and committed initiative configs. This is the architectural foundation that eliminates the entire class of v1 state corruption issues.
2. **Four authority domains with hard boundaries** — Control Repo (operational workspace), Release Module (read-only dependency), Copilot Adapter (thin IDE wiring), Governance Repo (constitutional authority). Cross-authority writes are forbidden.
3. **Multi-control-repo by design** — each team/org sets up their own sovereign control repo. The release module is a shared read-only dependency. Governance repos can be shared across control repos. No central coordination required — independence is the default architecture.

**Initiative Lifecycle:**

4. **Initiative creation** — `/new-domain`, `/new-service`, `/new-feature` with proper branch topology, initiative config committed to git, and governance validation.
5. **Phase routing commands** — `/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/dev` — each routing to the correct BMAD agent with proper branch context.
6. **Audience promotion** — `/promote` creates PR from current audience to next audience with gate checks (adversarial review, stakeholder approval, constitution gate), cross-initiative sensing, and constitution compliance.

**State & Navigation:**

7. **Status and next** — `/status` reports initiative state derived from git. `/next` recommends the next action based on lifecycle rules.
8. **Context switching** — `/switch` checks out a different initiative branch; committed initiative config travels with the branch, so context stays branch-aligned.

**Governance:**

9. **Constitution resolution** — 4-level hierarchy (org → domain → service → repo) with additive inheritance. Resolved at every gate.
10. **Compliance checking** — constitutional requirements enforced at promotion PRs. Hard-fail promotion if required gates fail.
11. **Cross-initiative sensing** — automatic at init and promotion gates. Scans branch topology to detect overlapping initiatives in the same domain/service. Informational by default, constitution can upgrade to hard gate.

**User Experience:**

12. **Onboarding workflow** — clone → `/onboard` → committed profile (role, domain, provider choice, non-secret preferences) → provider auth validated through the local credential store → TargetProjects bootstrapped → ready to work.
13. **Self-service release-module updates** — release module is a pinned read-only dependency with a documented update check and upgrade flow. Commands stay stable across versions.
14. **Batch-first execution with preference learning** — all phase workflows (except brainstorming and dev) run end-to-end in batch mode by default. After completion, user is asked if batch should be their permanent default for that workflow. Non-secret preferences are stored in the committed profile.
15. **Migration guide and compatibility checklist** — existing v1 users keep the familiar phase commands after a documented one-time upgrade step; no hidden/manual rescue path.
16. **Automatic PR creation** — phase workflows auto-create their review PRs when the output bundle is ready, and `/promote` auto-creates the promotion PR after prechecks pass. Review and merge remain manual gates.

### Out of Scope for MVP

| Feature | Rationale for Deferral |
|---------|----------------------|
| **Language-specific constitutions** | Constitution resolution works at MVP with universal constitutions. Language-specific variants add complexity without blocking core governance. |
| **Jira / Azure DevOps tracker integration** | Lifecycle management works without external tracker sync. Integration is additive — doesn't change how phases or gates work. |
| **`/sync` command** | Pull + rebase is a standard git operation users can do manually. Convenience, not core. |
| **`/fix` command** | v2's git-derived state model eliminates the class of state corruption that required repair workflows. If `/fix` is needed, the architecture has failed. |
| **Telemetry dashboards** | Lifecycle progress is visible through git branches and PRs. Dashboards are a reporting enhancement, not a workflow requirement. |
| **GitHub Actions / CI integration at lifecycle gates** | Gates work through PR-based reviews. CI automation is an optimization layer on top of working gates. |

### MVP Success Criteria

- All 6 persona types (Developer, Tech Lead, Architect, PO, SM, Admin) can complete their primary workflows self-service
- No branch/state desync incidents caused by local runtime state
- Onboarding completes in under 5 minutes without admin intervention
- Cross-initiative sensing fires at every promotion gate automatically
- Module updates follow the self-service update flow in every supported control repo
- Existing v1 users have a documented one-time migration path and can use the same phase commands immediately after upgrade

### Future Vision

**Post-MVP enhancements build on the proven foundation:**

- **Language-specific constitutions** — per-language governance rules (TypeScript conventions, Python style, Go patterns) applied automatically based on initiative language detection
- **Tracker integration** — bi-directional sync with Jira and Azure DevOps for organizations that need work items alongside BMAD lifecycle artifacts
- **`/sync` convenience command** — automated pull + rebase with conflict detection
- **Telemetry and reporting** — dashboards showing lifecycle progress, phase throughput, and governance compliance across all initiatives in a control repo
- **CI/CD gate automation** — GitHub Actions or Azure Pipelines triggered at lifecycle gates for automated constitution checks, artifact validation, and promotion workflows
