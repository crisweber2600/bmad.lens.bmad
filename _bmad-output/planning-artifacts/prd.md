---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
inputDocuments: ['_bmad-output/planning-artifacts/product-brief-bmad.lens.bmad-2026-03-08.md', '_bmad-output/brainstorming/brainstorming-session-2026-03-08-001.md', '_bmad-output/planning-artifacts/lens-work-v2-architecture.md']
workflowType: 'prd'
date: 2026-03-08
author: CrisWeber
briefCount: 1
researchCount: 0
brainstormingCount: 1
projectDocsCount: 0
classification:
  projectType: developer_tool
  domain: general
  complexity: medium-high
  projectContext: greenfield
---

# Product Requirements Document - bmad.lens.bmad

**Author:** CrisWeber
**Date:** 2026-03-08

## Executive Summary

lens-work v2 is a BMAD framework module that provides git-native lifecycle orchestration for software teams working across multiple domains and services. It operates as a single unified agent (`@lens`) within a VS Code Copilot runtime, routing phase commands (`/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/dev`) into structured workflows that produce planning and implementation artifacts, manage git branch topology, enforce constitutional governance through pull requests, and detect cross-initiative overlaps automatically.

The system serves six primary roles — developers, tech leads, architects, product owners, scrum masters, and BMAD admins — through a single control repository that functions as an operational workspace. Each role interacts with different lifecycle phases, but all share the same command surface, branch topology, and PR-based governance gates. The control repo contains the release module (read-only dependency), governance repo clone, Copilot adapter layer, and committed initiative artifacts.

v2 is a ground-up rebuild that eliminates the fundamental contradiction of v1: a git-native system that used a git-ignored `state.yaml` as its source of truth. v2 derives all state from git branch existence, PR metadata, and committed initiative configs. This eliminates the entire category of state corruption, dual-write staleness, and repair workflows that consumed v1.

### What Makes This Special

**Git branch topology IS the lifecycle tracker.** No external state, no database, no state files. The entire project lifecycle — every initiative, every phase, every audience tier, every pending approval — is reconstructable from `git branch --list` and PR history alone. This isn't just state storage; it's a design axiom that eliminates entire failure categories by construction.

**PR-as-PBR (Product Backlog Refinement).** Phase artifacts are reviewed as pull request diffs. Approval, compliance, and promotion happen through PRs with automatic constitution checks. No meetings required — governance happens through the tool teams already use.

**Four authority domains with hard boundaries.** Every file belongs to exactly one authority (Control Repo, Release Module, Copilot Adapter, Governance Repo). Cross-authority writes are forbidden at the design level, eliminating the drift and staleness that plagued v1.

**Automatic cross-initiative sensing.** At every promotion gate, the system scans all active initiative branches for overlapping domain/service targets and surfaces conflicts before approval — not through manual discovery commands nobody runs.

## Project Classification

- **Project Type:** Developer Tool / Framework Module
- **Domain:** Software Development Lifecycle Tooling (General)
- **Complexity:** Medium-High — four authority domains, multi-repo git orchestration, branch topology as state, constitutional governance hierarchy, multi-provider support (GitHub + Azure DevOps)
- **Project Context:** Greenfield (ground-up rebuild; v1 is reference material only)

## Success Criteria

### User Success

- **Self-service operation:** Every user operation (onboarding, phase commands, switching initiatives, status checks, promotions) completes without admin intervention. Zero white-glove support required.
- **Onboarding completion:** A new team member clones the control repo, runs `/onboard`, and executes their first phase command without external help.
- **Command reliability:** Phase commands (`/preplan` through `/dev`), `/status`, `/switch`, and `/next` succeed without state-related errors. Git-derived state eliminates corruption by design.
- **Context clarity:** Running `/next` produces a clear, actionable directive — the correct branch, the correct phase, the correct task — without the user needing to ask anyone.
- **Initiative mobility:** `/switch` moves between active initiatives seamlessly. Committed initiative configs travel with branches; no state file falls out of sync.

### Business Success

- **Module author independence:** The release module auto-updates as a read-only dependency. The module author is no longer a single point of failure for distribution. Any control repo can pull updates without personal guidance.
- **Infrastructure-to-feature ratio:** v2 targets ~16 workflows, 13 prompts, and 5 skills behind the same ~11 user touchpoints. This is a 4:1 reduction from v1's ~60 workflows, 47 prompts, and 7 skills.
- **Adoption friction:** Onboarding is "clone and run." No multi-repo juggling, no folder switching, no manual branch coordination.
- **Cross-initiative coordination:** Sensing reports surface overlapping initiatives at promotion gates automatically. Zero manual discovery effort required.

### Technical Success

- **State integrity:** All shared workflow state is committed to git. No git-ignored runtime state. Branch-traveling state is always consistent with the branch it's on.
- **Authority enforcement:** Cross-authority writes produce hard errors, not warnings. The release repo is read-only at runtime. Governance writes only happen via governance repo PRs.
- **Provider portability:** Git orchestration and PR management work across both GitHub and Azure DevOps through provider-specific adapters behind a common skill interface.
- **Governance correctness:** Four-level constitution hierarchy (org → domain → service → repo) resolves correctly with language-specific variants. Constitution checks execute automatically at PR gates.

### Measurable Outcomes

| Metric | Target |
|--------|--------|
| Self-service rate | 100% of user operations without admin help |
| Onboarding success | Clone → onboard → first phase command with zero intervention |
| Command success rate | 100% — no state corruption possible by design |
| Infrastructure ratio | ≤16 workflows behind ~11 user touchpoints |
| Module update | Self-service, no author involvement |
| Sensing coverage | 100% of promotion gates include cross-initiative scan |

## Product Scope

### MVP - Minimum Viable Product

The MVP delivers the core lifecycle loop with git-derived state:

- **Lifecycle contract** (`lifecycle.yaml`): phases, audiences, tracks, branch naming, constitution schema
- **Unified @lens agent** with phase routing and skill delegation
- **Core phase workflows:** `/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/dev`
- **Utility workflows:** `/onboard`, `/status`, `/next`, `/switch`, `/help`
- **Git orchestration skill:** branch creation, commits, pushes, PR creation
- **Git state skill:** state derivation from branch topology and PR metadata
- **Constitution skill:** 4-level hierarchy resolution and compliance checks at PR gates
- **Phase lifecycle workflow:** phase start, phase end, phase-to-audience PR
- **Audience promotion workflow:** audience-to-audience PR with governance gate
- **Single provider adapter:** GitHub (primary target)
- **Copilot adapter layer:** thin `.github/` wiring that references module skills/workflows by path
- **Cross-initiative sensing skill:** automatic overlap detection at promotion gates
- **Cross-initiative sensing workflow:** sensing scan integrated into audience promotion

### Out of Scope for MVP

| Feature | Rationale for Deferral |
|---------|------------------------|
| Language-specific constitutions | Constitution resolution works at MVP with universal constitutions. Language-specific variants add complexity without blocking core governance. |
| Jira / Azure DevOps tracker integration | Lifecycle management works without external tracker sync. Integration is additive. |
| `/sync` command | Pull + rebase is a standard git operation users can do manually. Convenience, not core. |
| `/fix` command | v2's git-derived state eliminates the class of state corruption that required repair workflows. |
| Telemetry dashboards | Lifecycle progress is visible through git branches and PRs. Dashboards are a reporting enhancement. |
| GitHub Actions / CI integration | Gates work through PR-based reviews. CI automation is an optimization layer. |

### Growth Features (Post-MVP)

- **Azure DevOps provider adapter:** second provider support
- **Language-specific constitution variants:** per-language governance rules applied based on initiative language detection
- **Batch-first execution with preference learning:** per-workflow user mode preferences
- **Contract test suite:** slim tests for branch parsing, provider adapters, sensing, governance resolution
- **Auto-update mechanism:** self-service release module updates

### Vision (Future)

- **Multi-control-repo federation:** sensing across control repos, not just within one
- **Governance analytics:** constitution compliance trends, cross-initiative coordination metrics
- **IDE-agnostic agent runtime:** support beyond VS Code Copilot (Cursor, Claude Code, etc.)
- **Webhook-triggered governance:** automatic constitution checks on PR creation via CI/CD integration

## User Journeys

### Journey 1: Dana the Developer — "What Should I Work On?"

Dana is a mid-level developer working across two active initiatives in the payments domain. She just finished a code review on one initiative and isn't sure where to pick up next. She opens VS Code, activates `@lens`, and types `/next`.

The agent reads committed initiative configs across her active branches, checks PR states, and responds: "Initiative `payments-refund-api` has story S3 ready for development on branch `initiative/payments-refund-api/dev/sprint-1`. Your other initiative `payments-webhook-v2` is pending techplan review — no action needed from you." Dana runs `/switch payments-refund-api`, the branch checks out, and she sees the story spec committed right there in the initiative artifacts. She starts coding immediately.

When she finishes the story, she commits her work. The phase-end workflow detects the completion, creates a PR from her dev phase branch to the small audience branch, and constitution compliance checks run automatically. No manual state updates. No wondering if the state file is stale. The branch IS the state.

**Capabilities revealed:** `/next` directive, `/switch` branch checkout, git-derived state queries, automatic PR creation, constitution compliance at PR gates.

### Journey 2: Tara the Tech Lead — "Is This Promotion Safe?"

Tara leads technical design for the payments domain. She receives a notification that initiative `payments-refund-api` is requesting promotion from small audience to medium audience. She opens the PR and sees the artifact diff — architecture decisions, API contracts, test coverage reports — all right there in the PR.

But she also sees something new: a sensing report appended to the PR description. It flags that another active initiative, `payments-webhook-v2`, is modifying the same payment event schema. Tara clicks through to the other initiative's techplan artifacts (visible on its branch), sees the overlap, and adds a comment on the PR requesting the refund API team coordinate their schema changes before she approves.

This sensing report appeared automatically at the promotion gate. Nobody told Tara to check. Nobody ran a manual discovery command. The system scanned all active initiative branches for overlapping domain/service targets and surfaced the conflict.

**Capabilities revealed:** PR-based promotion review, artifact diffs in PRs, automatic sensing at promotion gates, cross-initiative branch scanning, conflict surfacing.

### Journey 3: Priya the Product Owner — "I Need a Complete Product Brief"

Priya is kicking off a new initiative to add subscription billing to the platform. She opens VS Code, activates `@lens`, and types `/preplan`. The agent reads `lifecycle.yaml` for the preplan phase definition, checks governance for permitted tracks, and creates the initiative branch structure: `initiative/billing-subscription/preplan/`.

The preplan workflow executes in batch mode — Priya's preference, learned from her previous sessions. It produces a complete product brief, market context summary, and competitive analysis in one pass, committing artifacts to the initiative branch as it goes. At the end, Priya reviews the generated artifacts, makes a few edits, and the workflow creates a PR from the preplan phase branch to the small audience branch.

The PR includes constitution compliance status — the org-level constitution requires product briefs to address data privacy, and the system verified this section exists. Priya's team lead reviews the PR, approves, and the artifacts are merged to the small audience branch. Preplan is done; businessplan is next.

**Capabilities revealed:** `/preplan` phase command, initiative branch creation, batch-mode execution, artifact commits to branch, automatic PR creation, constitution compliance verification.

### Journey 4: Sam the Scrum Master — "Where Does Every Initiative Stand?"

Sam manages sprint execution across three active initiatives in the payments domain. He opens VS Code and types `/status`. The agent scans all `initiative/*` branches, reads committed configs for phase and audience state, queries PR metadata for pending reviews and approvals, and presents a consolidated report:

```
Active Initiatives (payments domain):
1. payments-refund-api    | Phase: dev/sprint-2  | Audience: small   | PRs: 1 pending review
2. payments-webhook-v2    | Phase: techplan       | Audience: small   | PRs: 0
3. billing-subscription   | Phase: preplan        | Audience: small   | PRs: 1 approved (ready to promote)
```

Every piece of this report is derived from git. Branch names encode the initiative, phase, and track. PR states reveal pending actions. Committed configs carry audience tier. Nothing can be stale because there's nothing stored outside git.

Sam sees that `billing-subscription` is ready for promotion. He types `/promote billing-subscription` and the system creates the promotion PR with a sensing scan attached.

**Capabilities revealed:** `/status` consolidated report, git-derived state from branches + PRs, multi-initiative visibility, `/promote` command with sensing.

### Journey 5: Alex the Admin — "New Team Member Needs Access"

Alex is the BMAD admin for the control repo. A new developer, Jordan, just joined the team. Alex tells Jordan to clone the control repo and run `/onboard`.

Jordan clones, opens VS Code, activates `@lens`, and types `/onboard`. The agent detects the configured PR provider (GitHub), validates Jordan's authentication using the GitHub CLI (no secrets written to git — credentials stay in the OS credential store), and verifies the governance repo clone exists at the configured path. If the governance clone is missing, it clones it automatically. Jordan's profile is created with role, domain assignment, and question-mode preference.

Alex didn't touch anything. No folder switching, no branch coordination, no manual instructions. Jordan is ready to work.

**Capabilities revealed:** `/onboard` self-service, provider authentication validation, governance repo bootstrap, profile creation, zero admin intervention.

### Journey 6: Arun the Architect — "Three Initiatives in One Service"

Arun owns technical design for the payments domain's core event processing service. He opens VS Code, activates `@lens`, and types `/techplan`. The agent creates a techplan phase branch for his initiative and begins the architecture workflow.

Before Arun writes a single architecture decision, the system runs a sensing scan. It detects two other active initiatives — `payments-refund-api` and `payments-webhook-v2` — both targeting the same event processing service. The sensing report appears in Arun's techplan workspace with a summary: overlapping domain, overlapping service, current phases, and links to each initiative's committed artifacts.

Arun reviews the other initiatives' techplan artifacts (visible on their branches), identifies shared schema dependencies, and designs his architecture to account for all three initiatives. When his techplan is complete, the phase-end workflow creates a PR to the small audience branch. The PR includes constitution compliance status — the domain-level constitution requires architecture documents to address cross-service dependencies, and the system verified this section exists.

Later, when `payments-refund-api` requests promotion from small to medium audience, Arun sees the promotion PR with a fresh sensing report attached. He verifies the refund API's architecture accounts for the shared event schema and approves.

**Capabilities revealed:** `/techplan` phase command, automatic sensing at phase start, cross-initiative artifact visibility, architecture workflow, constitution compliance at PR gates, sensing at promotion gates.

### Journey Requirements Summary

| Capability Area | Journeys Revealing It |
|----------------|----------------------|
| Git-derived state queries | Dana, Sam |
| Branch checkout / switching | Dana |
| Initiative branch creation | Priya, Arun |
| Phase command routing | Priya, Dana, Arun |
| Batch-mode execution | Priya |
| PR creation (phase-end, promotion) | Dana, Priya, Sam, Arun |
| Constitution compliance checks | Dana, Priya, Arun |
| Cross-initiative sensing | Tara, Sam, Arun |
| Cross-initiative artifact visibility | Arun |
| Consolidated status reporting | Sam |
| Self-service onboarding | Alex/Jordan |
| Provider authentication | Alex/Jordan |
| Governance repo management | Alex/Jordan, Priya |

## Innovation & Novel Patterns

### Git Branch Topology as State Machine

The core innovation is using git branch naming conventions and PR metadata as the complete state machine for a multi-phase, multi-audience lifecycle system. This isn't novel in the sense of using git branches — it's novel in eliminating ALL other state and deriving every status query, every gate check, and every sensing scan from the branch topology alone. No database, no state file, no external service.

**What makes this different from git-flow or trunk-based development:** Those are branching strategies for code. lens-work v2 uses branches for operational workflow state — tracking which initiative is in which phase, which audience tier has approved, and which constitutions have been satisfied. The branches carry committed artifact files, not code.

### PR-as-PBR (Product Backlog Refinement)

Using pull requests as the mechanism for product backlog refinement sessions is a pattern shift. Instead of synchronous meetings where artifacts are presented and discussed:
- Artifact diffs are the review material
- PR comments are the discussion forum
- Approval is the gate
- Constitution checks are automated compliance

This converts a meeting-heavy process into an asynchronous, git-native workflow.

### Validation Approach

- Git-derived state correctness validated by verifying branch topology matches expected lifecycle state at every gate
- PR-as-PBR validated in v1 — confirmed as the primary validated success of v1
- Sensing validated by confirming overlap detection accuracy against known cross-initiative scenarios

### Risk Mitigation

- **Branch topology complexity:** Mitigated by strict naming conventions encoded in `lifecycle.yaml` and validated by the git-state skill
- **PR provider differences:** Mitigated by provider adapter pattern — common skill interface, provider-specific implementation
- **Constitution resolution correctness:** Mitigated by contract tests for 4-level hierarchy resolution

## Developer Tool Specific Requirements

### Project-Type Overview

lens-work v2 is a framework module consumed by an IDE agent runtime (VS Code Copilot). It has no standalone runtime, no UI, no server. Users interact via slash commands in the IDE chat. The module provides agent definitions, skills, workflows, prompts, and a lifecycle contract — all declarative files that the agent runtime loads and executes.

### Technical Architecture Considerations

**Module Distribution:**
- Module lives in a release repo (`bmad.lens.release`) with semver tags
- Control repos consume it as a read-only dependency (pinned submodule or pinned clone)
- Updates are self-service pull operations, not push-based distribution

**Agent Runtime:**
- Single unified `@lens` agent acts as phase router
- Skills provide reusable capabilities (git orchestration, state queries, constitution resolution, sensing, checklists)
- Workflows define step-by-step execution for each phase command
- Prompts provide IDE-level command launchers

**Git Operations:**
- Branch creation, checkout, commit, push via git CLI
- PR creation, status queries, merge operations via provider CLI (GitHub CLI / Azure DevOps CLI)
- No JS libraries, no runtime dependencies beyond git and provider CLIs

**File Architecture:**
- All module files are declarative: YAML, Markdown, CSV
- No executable code in the module itself
- Agent runtime (VS Code Copilot) provides the execution environment
- Skills are instruction documents, not code libraries

### Command Surface

| Command | Phase | Description |
|---------|-------|-------------|
| `/onboard` | Utility | Profile creation, auth validation, governance bootstrap |
| `/preplan` | Phase | Product brief, research, competitive analysis |
| `/businessplan` | Phase | PRD, UX design |
| `/techplan` | Phase | Architecture, technical decisions |
| `/devproposal` | Phase | Implementation proposal, sprint structure |
| `/sprintplan` | Phase | Sprint planning, story creation |
| `/dev` | Phase | Story implementation, code review |
| `/status` | Utility | Git-derived state report across all initiatives |
| `/next` | Utility | Actionable directive — what to work on |
| `/switch` | Utility | Checkout to different initiative branch |
| `/promote` | Lifecycle | Create promotion PR with sensing |
| `/help` | Utility | Available commands and guidance |

### Implementation Considerations

- Module must work within Copilot agent context limits (no unbounded file loading)
- Skills must be self-contained instruction documents loadable by the agent
- Workflows follow BMAD step-file architecture (JIT loading, sequential execution)
- Git operations must handle both clean and dirty working tree states gracefully
- Provider adapters must normalize differences between GitHub and Azure DevOps PR/branch APIs

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-solving MVP — prove that git-derived state eliminates state corruption and that the core lifecycle loop (init → phase → PR → promote) works end-to-end on a single provider (GitHub).

**Resource Requirements:** Solo developer (module author) building declarative files (YAML, Markdown). No runtime code to write. The "implementation" is authoring agent instructions, skill documents, workflow steps, and the lifecycle contract.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- Dana: `/next` → `/switch` → dev → auto-PR (developer daily loop)
- Priya: `/preplan` → artifacts → auto-PR → review (PO planning loop)
- Sam: `/status` → consolidated report (SM visibility)
- Alex/Jordan: `/onboard` → ready to work (admin/onboarding)

**Must-Have Capabilities:**
- `lifecycle.yaml` contract defining phases, audiences, tracks, branch naming
- Unified `@lens` agent with phase routing
- Git orchestration skill (branch, commit, push, PR)
- Git state skill (derive state from branches + PRs)
- Constitution skill (4-level hierarchy resolution, compliance checks)
- Cross-initiative sensing skill and workflow (automatic at promotion gates)
- Phase lifecycle workflow (start, end, phase-to-audience PR)
- Audience promotion workflow (audience-to-audience PR with governance gate and sensing)
- 6 phase workflows (`/preplan` through `/dev`)
- 5 utility workflows (`/onboard`, `/status`, `/next`, `/switch`, `/help`)
- GitHub provider adapter
- Copilot adapter layer (`.github/` wiring)

### Post-MVP Features (Phase 2)

- Azure DevOps provider adapter
- Language-specific constitution variants
- Batch-first execution with per-workflow preference learning
- Contract test suite
- Self-service module auto-update mechanism

### Expansion Features (Phase 3)

- Multi-control-repo federation
- Governance analytics and compliance trending
- IDE-agnostic runtime support
- CI/CD-triggered governance checks

### Risk Mitigation Strategy

**Technical Risks:**
- *Branch topology parsing complexity:* Mitigated by encoding naming conventions in `lifecycle.yaml` and validating with the git-state skill. Strict conventions reduce ambiguity.
- *Provider API differences:* Mitigated by adapter pattern with common interface. MVP targets only GitHub, deferring provider abstraction complexity.
- *Copilot agent context limits:* Mitigated by JIT step-file loading and skill-based architecture. No workflow requires loading the entire module at once.

**Market Risks:**
- *Adoption of new paradigm:* Mitigated by keeping the exact same command surface as v1. Users who knew v1 commands can use v2 immediately.
- *Single-user validation:* The module author is the primary user during MVP. Real-team validation happens post-MVP.

**Resource Risks:**
- *Solo developer:* The module is declarative files, not code. A solo author can produce the full MVP. The architecture specifically avoids runtime code to keep the surface tractable.

## Functional Requirements

### Lifecycle Management

- FR1: `@lens` agent can route phase commands (`/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/dev`) to the correct workflow based on `lifecycle.yaml` definitions
- FR2: `@lens` agent can create initiative branch structures following the naming conventions defined in `lifecycle.yaml`
- FR3: `@lens` agent can create phase branches within an initiative following the lifecycle-defined phase sequence
- FR4: `@lens` agent can detect the current initiative and phase from the checked-out branch name
- FR5: `@lens` agent can enforce phase ordering — a phase cannot start until its predecessor phase has completed (PR merged)

### Git Orchestration

- FR6: `@lens` agent can create named branches in the control repo following lifecycle naming conventions
- FR7: `@lens` agent can commit initiative artifacts to the current branch
- FR8: `@lens` agent can push branches to the remote
- FR9: `@lens` agent can create pull requests from phase branches to audience branches with auto-populated descriptions including artifact summaries
- FR10: `@lens` agent can create promotion pull requests from one audience tier to the next with constitution compliance status and sensing reports attached

### State Derivation

- FR11: `@lens` agent can derive the current phase and audience of any initiative from its branch topology (branch existence and names)
- FR12: `@lens` agent can derive pending actions from PR metadata (open PRs, review status, approval state)
- FR13: `@lens` agent can produce a consolidated status report across all active initiatives by scanning `initiative/*` branches and their PR states
- FR14: `@lens` agent can determine the next actionable task for the current user based on branch state, PR state, and role

### Constitutional Governance

- FR15: `@lens` agent can resolve the effective constitution for an initiative by merging the 4-level hierarchy (org → domain → service → repo)
- FR16: [POST-MVP] `@lens` agent can apply language-specific constitution variants when the initiative's language matches a variant
- FR17: `@lens` agent can check artifact compliance against the resolved constitution at PR creation time
- FR18: `@lens` agent can include constitution compliance status in PR descriptions

### Cross-Initiative Sensing

- FR19: `@lens` agent can scan all active initiative branches to identify initiatives targeting the same domain or service
- FR20: `@lens` agent can generate a sensing report listing overlapping initiatives with their current phase and artifacts
- FR21: `@lens` agent can attach sensing reports to promotion PRs automatically

### Initiative Navigation

- FR22: `@lens` agent can switch the working tree to a different initiative's branch via `/switch`
- FR23: `@lens` agent can list all active initiatives with their current phase and audience via `/status`
- FR24: `@lens` agent can recommend the next action for the user via `/next` based on git-derived state

### Onboarding

- FR25: `@lens` agent can detect the configured PR provider (GitHub or Azure DevOps) for the control repo
- FR26: `@lens` agent can validate provider authentication using the provider's CLI without writing secrets to git
- FR27: `@lens` agent can verify or clone the governance repo to the configured path
- FR28: `@lens` agent can create a user profile with role, domain assignment, and question-mode preference

### Phase Workflows

- FR29: `@lens` agent can execute preplan phase workflows producing product briefs, research, and competitive analysis artifacts
- FR30: `@lens` agent can execute businessplan phase workflows producing PRD and UX design artifacts
- FR31: `@lens` agent can execute techplan phase workflows producing architecture and technical decision artifacts
- FR32: `@lens` agent can execute devproposal phase workflows producing implementation proposal artifacts
- FR33: `@lens` agent can execute sprintplan phase workflows producing sprint plans and user stories
- FR34: `@lens` agent can execute dev phase workflows managing story implementation and code review cycles

### Authority Enforcement

- FR35: `@lens` agent can block writes to the release module directory during initiative work
- FR36: `@lens` agent can block writes to the governance repo during initiative work (except proposing governance PRs)
- FR37: `@lens` agent can block initiative artifact writes to any location outside the control repo's initiative directory

### Module Management

- FR38: `@lens` agent can read the module version from the release repo and report it
- FR39: `@lens` agent can detect when a newer module version is available
- FR40: `@lens` agent can guide the user through a self-service module update

## Non-Functional Requirements

### Reliability

- NFR1: The system shall derive all shared workflow state from git with zero secondary state stores, verified by confirming no git-ignored state files exist in the module
- NFR2: The system shall produce a consistent working tree state on every `/switch` execution with no partial state or stale configs, verified by switch-and-verify test sequences
- NFR3: The system shall produce deterministic constitution resolution results for identical 4-level hierarchy inputs, verified by repeated resolution with same inputs yielding identical output

### Security

- NFR4: The system shall store user credentials (PATs, OAuth tokens) exclusively in the OS credential store or provider CLI login state, verified by scanning all git-tracked files for credential patterns
- NFR5: The system shall enforce authority domain boundaries such that the release module and governance repo cannot be mutated by initiative workflows, verified by attempting cross-authority writes and confirming hard errors
- NFR6: The system shall execute constitution compliance checks locally with no sensitive data sent to external services beyond the configured git provider, verified by network traffic analysis during compliance checks

### Portability

- NFR7: The system shall support git-compatible hosting providers (GitHub, Azure DevOps) through provider-specific adapters behind a common skill interface, verified by executing identical operations on both providers
- NFR8: The system shall use only declarative file formats (YAML, Markdown, CSV) with no OS-specific dependencies, verified by successful execution on Windows, macOS, and Linux
- NFR9: The system shall use standard `.github/` agent conventions as defined by VS Code Copilot, verified by Copilot runtime loading the adapter layer without modifications

### Maintainability

- NFR10: The system shall maintain a module surface of ≤16 workflows, ≤13 prompts, and ≤5 skills behind ~11 user touchpoints, verified by counting module artifacts at each release
- NFR11: The system shall contain no runtime code (JS, Python, etc.) — all capabilities expressed as declarative agent instructions, verified by scanning the module for executable files
- NFR12: The system shall support independent skill updates without requiring workflow changes, verified by modifying a skill document and confirming dependent workflows execute correctly
- NFR13: The system shall use `lifecycle.yaml` as the single contract defining all branch naming, phase ordering, audience tiers, and constitution schema, verified by confirming no other files duplicate these definitions

## Migration Guide

### v1 to v2 Migration Path

Existing v1 users follow a one-time upgrade:

1. Clone the v2 control repo (or convert existing control repo using documented steps)
2. Run `/onboard` to create committed profile with role, domain, and preferences
3. Verify governance repo clone is at the configured path
4. Resume using the same phase commands (`/preplan` through `/dev`) — command surface is identical

**What changes for v1 users:**
- No more `state.yaml` — state is derived from git branches and PRs
- No more folder switching between repos — single control repo workspace
- No more white-glove module updates — self-service pull from release repo
- `/switch` now works reliably — initiative configs travel with branches

**What stays the same:**
- All phase commands (`/preplan`, `/businessplan`, `/techplan`, `/devproposal`, `/sprintplan`, `/dev`)
- PR-as-PBR workflow (artifact diffs, approval gates, constitution compliance)
- Audience tier model (small, medium, large)
- Constitution governance hierarchy

## Command Examples

### `/status` Output

```
Active Initiatives (payments domain):
1. payments-refund-api    | Phase: dev/sprint-2  | Audience: small   | PRs: 1 pending review
2. payments-webhook-v2    | Phase: techplan       | Audience: small   | PRs: 0
3. billing-subscription   | Phase: preplan        | Audience: small   | PRs: 1 approved (ready to promote)
```

### `/next` Output

```
Initiative: payments-refund-api
Phase: dev/sprint-2
Branch: initiative/payments-refund-api/dev/sprint-2
Action: Story S3 is ready for development. Run /switch payments-refund-api to check out the branch.
```

### `/switch` Output

```
Switched to: initiative/billing-subscription/preplan
Initiative: billing-subscription
Phase: preplan
Audience: small
Pending: Product brief in progress
```

## Language Support

lens-work v2 is a language-agnostic lifecycle orchestration module. It manages planning and governance artifacts (YAML, Markdown, CSV) — not source code in any specific programming language. Initiatives managed through lens-work can be in any language or framework; the module imposes no language constraints on the projects it orchestrates.
