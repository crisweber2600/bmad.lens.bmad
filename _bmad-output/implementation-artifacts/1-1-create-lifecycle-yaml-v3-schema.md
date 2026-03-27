# Story 1.1: Update lifecycle.yaml to Schema v3

Status: ready-for-dev

## Story

As a module dev agent,
I want to update `lifecycle.yaml` to schema_version 3 with milestone tokens, close_states, artifact_publication, and migrations section,
So that the v3 contract is established and all downstream skills and workflows have a valid schema to reference.

## Acceptance Criteria

1. `schema_version` is `3`
2. Milestone tokens `techplan/devproposal/sprintplan/dev-ready` replace audience tokens `small/medium/large/base` throughout the file
3. `close_states: [completed, abandoned, superseded]` is present at the top level
4. `artifact_publication: { governance_root: 'artifacts/', enabled: true }` is present at the top level
5. A `migrations` section with a v2→v3 migration descriptor is present (fields: `from_version: 2`, `to_version: 3`, `breaking: true`, changes array)
6. The file validates as valid YAML with no structural errors (no duplicate keys, correct nesting)
7. All existing field references — phases, tracks, constitution schema, lifecycle_hierarchy — remain intact and logically consistent



## Tasks / Subtasks

- [ ] Task 1: Update `schema_version` field (AC: 1)
  - [ ] Change `schema_version: 2` to `schema_version: 3` at the top of the file

- [ ] Task 2: Replace audience tokens with milestone tokens (AC: 2)
  - [ ] Rename `audiences:` section keys: `small` → `techplan`, `medium` → `devproposal`, `large` → `sprintplan`, `base` → `dev-ready`
  - [ ] Update `role` and `description` fields within each audience entry to reflect milestone semantics
  - [ ] Update `audience:` fields within `phases:` entries: change `audience: small` → `audience: techplan`, `audience: medium` → `audience: devproposal`, etc.
  - [ ] Update `branching_audience:` fields (devproposal: `medium` → `devproposal`, sprintplan: `large` → `sprintplan`)
  - [ ] Update `tracks:` section `audiences:` lists to use new tokens

- [ ] Task 3: Add `close_states` field (AC: 3)
  - [ ] Add `close_states: [completed, abandoned, superseded]` as a top-level field (place after `schema_version` or near lifecycle configuration fields)

- [ ] Task 4: Add `artifact_publication` field (AC: 4)
  - [ ] Add `artifact_publication:` section with `governance_root: 'artifacts/'` and `enabled: true`

- [ ] Task 5: Add `migrations` section (AC: 5)
  - [ ] Add `migrations:` section at the bottom of the file
  - [ ] Include entry: `from_version: 2`, `to_version: 3`, `breaking: true`
  - [ ] Include `changes:` array with descriptors for: audience-to-milestone token renames (small→techplan, medium→devproposal, large→sprintplan, base→dev-ready), `add_field: close_states`, `add_field: artifact_publication`, `add_field: initiative_state_schema`, `branch_rename_required: true`
  - [ ] Set `migration_command: '/lens-upgrade --from 2 --to 3'`

- [ ] Task 6: Validate file (AC: 6, 7)
  - [ ] Verify no YAML syntax errors (use `python -c "import yaml; yaml.safe_load(open('lifecycle.yaml'))"` or equivalent)
  - [ ] Confirm all `phases:` entries still have valid `audience:` references targeting the new token names
  - [ ] Confirm all `tracks:` entries still have valid `audiences:` lists with new token names

## Dev Notes

### Target File
The file to edit is: `bmad.lens.src/_bmad/lens-work/lifecycle.yaml`

> **NOTE:** `bmad.lens.release/_bmad/lens-work/lifecycle.yaml` is the **read-only authority copy**. Changes happen in `bmad.lens.src/` (the source). The release copy is regenerated from source at publish time.

### Current `lifecycle.yaml` Structure (v2)
Key audience tokens in v2 that must be renamed:

```yaml
# v2 structure (CURRENT)
audiences:
  small: ...    # → rename to: techplan
  medium: ...   # → rename to: devproposal
  large: ...    # → rename to: sprintplan
  base: ...     # → rename to: dev-ready

phases:
  preplan:
    audience: small             # → audience: techplan
  businessplan:
    audience: small             # → audience: techplan
  techplan:
    audience: small             # → audience: techplan
    auto_advance_promote: true  # (keep unchanged)
  devproposal:
    audience: small             # → audience: techplan (where work happens before branching)
    branching_audience: medium  # → branching_audience: devproposal
  sprintplan:
    audience: small             # → audience: techplan (consistent with arch)
    branching_audience: large   # → branching_audience: sprintplan

tracks:
  full:
    audiences: [small, medium, large, base]  # → [techplan, devproposal, sprintplan, dev-ready]
```

### New Fields to Add

```yaml
# Add at top-level (after schema_version)
schema_version: 3
close_states: [completed, abandoned, superseded]
artifact_publication:
  governance_root: 'artifacts/'
  enabled: true

# Add at end of file
migrations:
  - from_version: 2
    to_version: 3
    breaking: true
    migration_command: '/lens-upgrade --from 2 --to 3'
    changes:
      - type: rename_token
        field: audiences
        from: small
        to: techplan
      - type: rename_token
        field: audiences
        from: medium
        to: devproposal
      - type: rename_token
        field: audiences
        from: large
        to: sprintplan
      - type: rename_token
        field: audiences
        from: base
        to: dev-ready
      - type: add_field
        field: close_states
        value: [completed, abandoned, superseded]
      - type: add_field
        field: artifact_publication
        value: { governance_root: 'artifacts/', enabled: true }
      - type: add_field
        field: initiative_state_schema
        value: initiative-state.yaml
      - type: branch_rename_required
        value: true
```

### Architecture Constraints
- **A7 (Branch = lookup key only):** After this story, all downstream skills/workflows must use milestone tokens as branch name suffixes, not audience names. The branch name mapping is: `{initiative_root}-{milestone_token}` (e.g., `foo-bar-techplan` replaces `foo-bar-small`).
- **A1 (YAML source of truth):** `lifecycle.yaml` is the authoritative token list. No hardcoded audience/milestone strings elsewhere.
- **YAML-only changes:** This story is purely a data structure update to a YAML file. No workflow or skill files are modified in this story.
- **Downstream dependency:** Stories 1.2–1.5 and all of Epic 2 depend on this story being merged first. Do not start those stories until this story is complete and merged.

### Validation Command
After editing, validate the file:
```bash
python3 -c "import yaml; d=yaml.safe_load(open('bmad.lens.src/_bmad/lens-work/lifecycle.yaml')); print('Valid YAML. schema_version:', d.get('schema_version'))"
```
Expected output: `Valid YAML. schema_version: 3`

### References
- Architecture v3: `_bmad-output/planning-artifacts/architecture.md` — Section 2.1 (Branch Topology), Section 2.4 (Version Safety)
- Epics: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.1
- Current lifecycle: `bmad.lens.release/_bmad/lens-work/lifecycle.yaml` (read-only reference copy)

## Dev Agent Record

### Agent Model Used

(to be filled by dev agent)

### Debug Log References

### Completion Notes List

### File List

- `bmad.lens.src/_bmad/lens-work/lifecycle.yaml` — **modified** (schema_version, audience tokens renamed to milestone tokens, close_states added, artifact_publication added, migrations section added)
