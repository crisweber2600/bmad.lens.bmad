#!/usr/bin/env bash
# =============================================================================
# LENS Workbench v2 — Control Repo Setup
#
# PURPOSE:
#   Bootstraps a new control repo by cloning all required authority domains:
#   - bmad.lens.release   → Release module (read-only dependency)
#   - <control-repo>.governance → Governance repo (constitutional authority)
#   - .github             → Copied from bmad.lens.release/.github
#
#   Safe to re-run: pulls latest if repos already exist.
#
# USAGE:
#   ./setup-control-repo.sh --org <github-org-or-user>
#   ./setup-control-repo.sh --org weberbot --release-repo my-release
#   ./setup-control-repo.sh --release-org myorg --governance-org governance-team
#   ./setup-control-repo.sh --org weberbot --base-url https://github.company.com
#   ./setup-control-repo.sh --help
#
# OPTIONS:
#   --org <name>               Default GitHub org/user for all repos (falls back if specific org not set)
#   --release-org <name>       Release repo owner (default: uses --org)
#   --release-repo <name>      Release repo name (default: bmad.lens.release)
#   --release-branch <name>    Release repo branch (default: beta)
#   --copilot-org <name>       Reserved for parity with setup-control-repo.ps1
#   --copilot-repo <name>      Reserved for parity with setup-control-repo.ps1
#   --copilot-branch <name>    Reserved for parity with setup-control-repo.ps1
#   --governance-org <name>    Governance repo owner (default: uses --org)
#   --governance-repo <name>   Governance repo name (default: <control-repo>.governance)
#   --governance-branch <name> Governance repo branch (default: main)
#   --governance-path <path>   Local path for governance repo clone (default: TargetProjects/lens/<governance-repo>)
#   --base-url <url>           Git base URL (default: https://github.com) - supports enterprise GitHub
#   --dry-run                  Show what would be done without making changes
#   -h, --help                 Show this help message
#
# =============================================================================

set -euo pipefail

# -- Colors -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# -- Defaults ---------------------------------------------------------------
ORG="crisweber2600"
RELEASE_ORG="crisweber2600"
RELEASE_REPO="bmad.lens.release"
RELEASE_BRANCH="beta"
COPILOT_ORG="crisweber2600"
COPILOT_REPO="bmad.lens.copilot"
COPILOT_BRANCH="beta"
GOVERNANCE_ORG="crisweber2600"
GOVERNANCE_REPO="lens-governance"
GOVERNANCE_BRANCH="main"
GOVERNANCE_PATH="TargetProjects/lens/lens-governance"
BASE_URL="https://github.com"
DRY_RUN=false
GOVERNANCE_REPO_SET=false
GOVERNANCE_PATH_SET=false

# -- Project root (prefer git to avoid cwd-dependent behavior) -----------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if GIT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  PROJECT_ROOT="$GIT_ROOT"
else
  # Fallback: this script lives at _bmad/lens-work/scripts/
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi

# -- Parse Arguments --------------------------------------------------------
show_help() {
  sed -n '2,/^# =/p' "$0" | sed 's/^# //'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      shift
      ORG="$1"
      ;;
    --release-org)
      shift
      RELEASE_ORG="$1"
      ;;
    --release-repo)
      shift
      RELEASE_REPO="$1"
      ;;
    --release-branch)
      shift
      RELEASE_BRANCH="$1"
      ;;
    --copilot-org)
      shift
      COPILOT_ORG="$1"
      ;;
    --copilot-repo)
      shift
      COPILOT_REPO="$1"
      ;;
    --copilot-branch)
      shift
      COPILOT_BRANCH="$1"
      ;;
    --governance-org)
      shift
      GOVERNANCE_ORG="$1"
      ;;
    --governance-repo)
      shift
      GOVERNANCE_REPO="$1"
      GOVERNANCE_REPO_SET=true
      ;;
    --governance-branch)
      shift
      GOVERNANCE_BRANCH="$1"
      ;;
    --governance-path)
      shift
      GOVERNANCE_PATH="$1"
      GOVERNANCE_PATH_SET=true
      ;;
    --base-url)
      shift
      BASE_URL="$1"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${RESET}"
      show_help
      exit 1
      ;;
  esac
  shift
done

# -- Validate required args --------------------------------------------------
if [[ -z "$ORG" && -z "$RELEASE_ORG" && -z "$COPILOT_ORG" && -z "$GOVERNANCE_ORG" ]]; then
  echo -e "${RED}Error: --org is required (or specify --release-org, --copilot-org, --governance-org individually)${RESET}"
  echo ""
  show_help
  exit 1
fi

# -- Apply fallbacks ---------------------------------------------------------
RELEASE_ORG="${RELEASE_ORG:-$ORG}"
COPILOT_ORG="${COPILOT_ORG:-$ORG}"
GOVERNANCE_ORG="${GOVERNANCE_ORG:-$ORG}"

# -- Derive governance defaults from control repo name -----------------------
CONTROL_REPO_NAME="$(basename "$PROJECT_ROOT")"
if [[ "$CONTROL_REPO_NAME" =~ \.src$ ]]; then
  CONTROL_REPO_NAME="${CONTROL_REPO_NAME%.src}.bmad"
fi
if [[ "$GOVERNANCE_REPO_SET" != true ]]; then
  GOVERNANCE_REPO="${CONTROL_REPO_NAME}.governance"
fi
if [[ "$GOVERNANCE_PATH_SET" != true ]]; then
  GOVERNANCE_PATH="TargetProjects/lens/${GOVERNANCE_REPO}"
fi

# -- Helper Functions -------------------------------------------------------
log_info() { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${RESET}   $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_err()  { echo -e "${RED}[ERR]${RESET}  $1"; }

clone_or_pull() {
  local remote_url="$1"
  local local_path="$2"
  local branch="$3"
  local repo_label="$4"
  local is_git_repo=false
  local target_exists=false

  [[ -d "$local_path/.git" ]] && is_git_repo=true
  [[ -e "$local_path" ]] && target_exists=true

  if [[ "$DRY_RUN" == true ]]; then
    if [[ "$is_git_repo" == true ]]; then
      log_info "[DRY-RUN] Would pull latest for ${repo_label} at ${local_path} (branch: ${branch})"
    elif [[ "$target_exists" == true ]]; then
      log_info "[DRY-RUN] Would replace existing path and clone ${repo_label} → ${local_path} (branch: ${branch})"
    else
      log_info "[DRY-RUN] Would clone ${repo_label} → ${local_path} (branch: ${branch})"
    fi
    return
  fi

  if [[ "$is_git_repo" == true ]]; then
    log_info "Pulling latest for ${repo_label} (${local_path})..."
    (
      cd "$local_path"
      git fetch origin
      git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch"
      git pull origin "$branch"
    )
    log_ok "${repo_label} updated (branch: ${branch})"
  else
    if [[ "$target_exists" == true ]]; then
      log_warn "${repo_label} target exists and is not a git repo. Replacing ${local_path}"
      rm -rf "$local_path"
    fi

    log_info "Cloning ${repo_label} → ${local_path} (branch: ${branch})..."
    mkdir -p "$(dirname "$local_path")"
    git clone --branch "$branch" "$remote_url" "$local_path"
    log_ok "${repo_label} cloned (branch: ${branch})"
  fi
}

sync_github_from_release() {
  local release_repo_path="$1"
  local destination_path="$2"
  local source_label="$3"

  local source_path="${release_repo_path}/.github"
  local destination_exists=false
  local destination_is_git_repo=false

  [[ -e "$destination_path" ]] && destination_exists=true
  [[ -d "$destination_path/.git" ]] && destination_is_git_repo=true

  if [[ ! -d "$source_path" ]]; then
    log_err "Missing source .github at ${source_path}"
    exit 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ "$destination_is_git_repo" == true ]]; then
      log_info "[DRY-RUN] Would remove existing .github git repo at ${destination_path}"
    elif [[ "$destination_exists" == true ]]; then
      log_info "[DRY-RUN] Would replace existing .github at ${destination_path}"
    else
      log_info "[DRY-RUN] Would create .github at ${destination_path}"
    fi
    log_info "[DRY-RUN] Would copy .github from ${source_label}"
    return
  fi

  if [[ "$destination_is_git_repo" == true ]]; then
    log_warn ".github is a git repo in control repo. Removing before copy"
  elif [[ "$destination_exists" == true ]]; then
    log_info "Replacing existing .github at ${destination_path}"
  fi

  if [[ "$destination_exists" == true ]]; then
    rm -rf "$destination_path"
  fi

  mkdir -p "$destination_path"
  cp -a "${source_path}/." "$destination_path/"
  log_ok ".github copied from ${source_label}"
}

ensure_github_repo_exists() {
  local base_url="$1"
  local owner="$2"
  local repo="$3"
  local remote_url="$4"

  local repo_full_name="${owner}/${repo}"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would verify ${repo_full_name} exists"
    log_info "[DRY-RUN] Would create private repository ${repo_full_name} if missing"
    return
  fi

  if git ls-remote "$remote_url" HEAD >/dev/null 2>&1; then
    log_info "${repo_full_name} is available"
    return
  fi

  log_warn "${repo_full_name} is missing or inaccessible. Attempting to create it as a private repository."

  if ! command -v gh >/dev/null 2>&1; then
    log_err "GitHub CLI (gh) is required to auto-create ${repo_full_name}. Install gh or create the repo manually."
    exit 1
  fi

  local previous_gh_host="${GH_HOST-}"
  local host
  host="$(printf '%s' "$base_url" | sed -E 's#^[a-zA-Z]+://([^/]+).*$#\1#')"
  if [[ -z "$host" || "$host" == "$base_url" ]]; then
    host="github.com"
  fi

  if [[ "$host" != "github.com" ]]; then
    export GH_HOST="$host"
    log_info "Using GitHub host ${host} for repository creation"
  else
    unset GH_HOST
  fi

  if ! gh repo create "$repo_full_name" --private --add-readme --description "LENS governance repository" --disable-issues; then
    log_err "Failed to create private repository ${repo_full_name}"
    [[ -n "$previous_gh_host" ]] && export GH_HOST="$previous_gh_host" || unset GH_HOST
    exit 1
  fi

  log_ok "Created private repository ${repo_full_name}"

  [[ -n "$previous_gh_host" ]] && export GH_HOST="$previous_gh_host" || unset GH_HOST

  if ! git ls-remote "$remote_url" HEAD >/dev/null 2>&1; then
    log_err "Repository ${repo_full_name} was created but is still not reachable at ${remote_url}"
    exit 1
  fi
}

resolve_clone_branch() {
  local remote_url="$1"
  local preferred_branch="$2"
  local repo_label="$3"

  if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "$preferred_branch"
    return
  fi

  local branch_heads
  branch_heads="$(git ls-remote --heads "$remote_url" "$preferred_branch" 2>/dev/null || true)"
  if [[ -n "$branch_heads" ]]; then
    printf '%s\n' "$preferred_branch"
    return
  fi

  local head_line
  head_line="$(git ls-remote --symref "$remote_url" HEAD 2>/dev/null | grep 'ref: refs/heads/' | head -n1 || true)"
  if [[ -z "$head_line" ]]; then
    log_err "Unable to resolve default branch for ${repo_label}"
    exit 1
  fi

  local default_branch
  default_branch="$(printf '%s' "$head_line" | sed -E 's#.*refs/heads/([^[:space:]]+).*#\1#')"
  if [[ -z "$default_branch" ]]; then
    log_err "Unable to parse default branch for ${repo_label}"
    exit 1
  fi

  log_warn "${repo_label} does not have branch '${preferred_branch}'. Using default branch '${default_branch}' instead."
  printf '%s\n' "$default_branch"
}

ensure_gitignore_entries() {
  local gitignore_file="${PROJECT_ROOT}/.gitignore"
  local entries=(
    "_bmad-output/lens-work/personal/"
    ".github/"
    "bmad.lens.release/"
    "TargetProjects/"
  )

  local added_count=0

  if [[ ! -f "$gitignore_file" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would create ${gitignore_file}"
    else
      : > "$gitignore_file"
      log_info "Created ${gitignore_file}"
    fi
  fi

  for entry in "${entries[@]}"; do
    if [[ -f "$gitignore_file" ]] && grep -Fxq "$entry" "$gitignore_file"; then
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would add '${entry}' to .gitignore"
    else
      printf '%s\n' "$entry" >> "$gitignore_file"
      added_count=$((added_count + 1))
      log_info "Added '${entry}' to .gitignore"
    fi
  done

  if [[ "$DRY_RUN" != true ]]; then
    if [[ "$added_count" -eq 0 ]]; then
      log_ok ".gitignore already contains required entries"
    else
      log_ok ".gitignore updated with required entries"
    fi
  fi
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${BOLD}LENS Workbench v2 — Control Repo Setup${RESET}"
echo -e "${DIM}Base URL: ${BASE_URL}${RESET}"
echo -e "${DIM}Root:     ${PROJECT_ROOT}${RESET}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  log_warn "Dry run mode: no changes will be made"
  echo ""
fi

# -- 1. Release Repo --------------------------------------------------------
RELEASE_URL="${BASE_URL}/${RELEASE_ORG}/${RELEASE_REPO}.git"
RELEASE_PATH="${PROJECT_ROOT}/${RELEASE_REPO}"
clone_or_pull "$RELEASE_URL" "$RELEASE_PATH" "$RELEASE_BRANCH" "${RELEASE_ORG}/${RELEASE_REPO}"

# -- 2. Sync .github from Release Repo --------------------------------------
COPILOT_PATH="${PROJECT_ROOT}/.github"
sync_github_from_release "$RELEASE_PATH" "$COPILOT_PATH" "${RELEASE_ORG}/${RELEASE_REPO}/.github"

# -- 3. Governance Repo -----------------------------------------------------
GOVERNANCE_URL="${BASE_URL}/${GOVERNANCE_ORG}/${GOVERNANCE_REPO}.git"
GOVERNANCE_FULL_PATH="${PROJECT_ROOT}/${GOVERNANCE_PATH}"
ensure_github_repo_exists "$BASE_URL" "$GOVERNANCE_ORG" "$GOVERNANCE_REPO" "$GOVERNANCE_URL"
GOVERNANCE_CLONE_BRANCH="$(resolve_clone_branch "$GOVERNANCE_URL" "$GOVERNANCE_BRANCH" "${GOVERNANCE_ORG}/${GOVERNANCE_REPO}")"
clone_or_pull "$GOVERNANCE_URL" "$GOVERNANCE_FULL_PATH" "$GOVERNANCE_CLONE_BRANCH" "${GOVERNANCE_ORG}/${GOVERNANCE_REPO}"

# -- 4. Output directories --------------------------------------------------
if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "${PROJECT_ROOT}/_bmad-output/lens-work/initiatives"
  mkdir -p "${PROJECT_ROOT}/_bmad-output/lens-work/personal"
  log_ok "Output directory structure verified"
else
  log_info "[DRY-RUN] Would create _bmad-output/lens-work/ directories"
fi

# -- 5. Ensure .gitignore entries -------------------------------------------
ensure_gitignore_entries

# -- Summary ----------------------------------------------------------------
echo ""
echo -e "${BOLD}Setup Complete${RESET}"
echo ""
echo -e "  ${GREEN}${RELEASE_ORG}/${RELEASE_REPO}${RESET} → ${RELEASE_REPO}/    (branch: ${RELEASE_BRANCH})"
echo -e "  ${GREEN}.github${RESET}  <--  ${RELEASE_REPO}/.github"
echo -e "  ${GREEN}${GOVERNANCE_ORG}/${GOVERNANCE_REPO}${RESET} → ${GOVERNANCE_PATH}/  (branch: ${GOVERNANCE_CLONE_BRANCH})"
echo ""
echo -e "GitHub Copilot adapter is installed from bmad.lens.release/.github."
echo -e "No further setup is needed if GitHub Copilot is your only IDE."
echo ""
echo -e "For non-Copilot IDEs, run the module installer:"
echo -e "  ${CYAN}./_bmad/lens-work/scripts/install.sh --ide cursor${RESET}"
echo -e "  ${CYAN}./_bmad/lens-work/scripts/install.sh --all-ides${RESET}"
echo ""
