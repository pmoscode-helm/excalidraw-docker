#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# build-images.sh
# -----------------------------------------------------------------------------
# Builds Docker images based on a submodule pointing to another GitHub repo.
# - Builds a "dev" image (master branch)
# - Builds a "latest" and versioned image (latest tag)
# Supports:
#   --push         → push images to Docker Hub
#   --only-dev     → build only the dev image
#   --only-release → build only latest/version images
# -----------------------------------------------------------------------------

# Default configuration
SUBMODULE_PATH="excalidraw"     # relative path to submodule
IMAGE_NAME="pmoscode/excalidraw"   # Docker Hub image name
DOCKERFILE="Dockerfile"            # path to Dockerfile relative to this repo
PUSH=false
ONLY_NIGHTLY=false
ONLY_RELEASE=false

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
log() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Parse CLI arguments
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true ;;
    --only-nightly) ONLY_NIGHTLY=true ;;
    --only-release) ONLY_RELEASE=true ;;
    --submodule) SUBMODULE_PATH="$2"; shift ;;
    --image) IMAGE_NAME="$2"; shift ;;
    --dockerfile) DOCKERFILE="$2"; shift ;;
    -h|--help)
      echo "Usage: $0 [--push] [--only-nightly|--only-release] [--submodule PATH] [--image NAME] [--dockerfile FILE]"
      exit 0
      ;;
    *) err "Unknown argument: $1" ;;
  esac
  shift
done

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------
command -v git >/dev/null 2>&1 || err "git not found"
command -v docker >/dev/null 2>&1 || err "docker not found"

if [[ ! -e "$SUBMODULE_PATH/.git" ]]; then
  log "Submodule not initialized – initializing..."
  git submodule update --init --recursive "$SUBMODULE_PATH"
fi

[[ -e "$SUBMODULE_PATH/.git" ]] || err "Submodule not found: $SUBMODULE_PATH"

# -----------------------------------------------------------------------------
# Determine repo state
# -----------------------------------------------------------------------------
pushd "$SUBMODULE_PATH" >/dev/null

ORIG_REF=$(git rev-parse --abbrev-ref HEAD || git rev-parse HEAD)
log "Current submodule ref: $ORIG_REF"

git fetch --tags --quiet
git fetch origin master --quiet || git fetch origin main --quiet

LATEST_TAG=$(git tag --sort=-v:refname | head -n1)
[[ -n "$LATEST_TAG" ]] || err "No tags found in submodule repository."
log "Latest tag detected: $LATEST_TAG"

popd >/dev/null

# -----------------------------------------------------------------------------
# Function: Build Docker image
# -----------------------------------------------------------------------------
build_image() {
  local tag="$1"
  local context="."
  log "Building Docker image: ${IMAGE_NAME}:${tag}"
  docker build -f "$DOCKERFILE" -t "${IMAGE_NAME}:${tag}" "$context"
  if $PUSH; then
    log "Pushing ${IMAGE_NAME}:${tag}"
    docker push "${IMAGE_NAME}:${tag}"
  fi
}

# -----------------------------------------------------------------------------
# 1. Build release images (latest + versioned)
# -----------------------------------------------------------------------------
if ! $ONLY_NIGHTLY; then
  pushd "$SUBMODULE_PATH" >/dev/null
  log "Checking out tag $LATEST_TAG..."
  git checkout --detach "$LATEST_TAG" >/dev/null
  popd >/dev/null

  build_image "$LATEST_TAG"
  build_image "latest"

  # Restore state
  pushd "$SUBMODULE_PATH" >/dev/null
  git checkout "$ORIG_REF" >/dev/null 2>&1 || true
  popd >/dev/null
fi

# -----------------------------------------------------------------------------
# 2. Build nightly image (master branch)
# -----------------------------------------------------------------------------
if ! $ONLY_RELEASE; then
  pushd "$SUBMODULE_PATH" >/dev/null
  log "Checking out master for nightly build..."
  git checkout master >/dev/null 2>&1 || git checkout main >/dev/null 2>&1
  git pull --quiet origin master || git pull --quiet origin main
  popd >/dev/null

  build_image "dev"

  # Restore original state
  pushd "$SUBMODULE_PATH" >/dev/null
  git checkout "$ORIG_REF" >/dev/null 2>&1 || true
  popd >/dev/null
fi

log "✅ Build process complete."
