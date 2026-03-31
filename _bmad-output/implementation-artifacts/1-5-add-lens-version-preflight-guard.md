# Story 1.5: Add LENS_VERSION File and Preflight Version Guard

## Implementation Summary

Added version binding and compatibility enforcement to the lens-work module in `bmad.lens.src`.

## Changes Made

- **Files:** `_bmad/lens-work/scripts/setup-control-repo.sh`, `_bmad/lens-work/scripts/setup-control-repo.ps1`
  - Added Step 5: Write `LENS_VERSION` to control repo root using `schema_version` from `lifecycle.yaml`
  - Bumped version headers from v2 to v3
- **File:** `_bmad/lens-work/workflows/includes/preflight.md`
  - Added Step 1a: Enforce `LENS_VERSION` compatibility check against `lifecycle.yaml schema_version`
  - Hard-stops workflow with clear upgrade message on version mismatch

## PR

- PR #21: https://github.com/crisweber2600/bmad.lens.src/pull/21
- Branch: `feature/lens-epic-1-1-5` → `feature/lens-epic-1-1-4`

## Verification

- Preflight logic matches v3 release authority reference
- Setup scripts add LENS_VERSION writing (new v3 feature per story acceptance criteria)
