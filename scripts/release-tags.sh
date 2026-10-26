#!/usr/bin/env bash
set -euo pipefail

# Create and push per-package release tags for axle.
#
# Usage:
#   scripts/release-tags.sh [version] [--dry-run] [--skip-pub-check]
#
# The script refuses to continue unless:
#   - the working tree is clean;
#   - HEAD is on master and matches origin/master;
#   - every package declares the requested version;
#   - no local tag points at a different commit.
#
# Packages whose version is already published on pub.dev are skipped, because
# pushing their publish tag would try to republish that version.
# Existing local tags at HEAD are reused, so an interrupted run can be resumed.

usage() {
  cat <<'EOF'
Usage: scripts/release-tags.sh [version] [--dry-run] [--skip-pub-check]

  version           Version to tag, with or without a leading "v".
                    If omitted, the script prompts for it.
  --dry-run         Validate and print the tag plan without creating/pushing.
  --skip-pub-check  Do not query pub.dev. Use only when the network is unavailable.

The script requires a clean master branch that exactly matches origin/master.
EOF
}

DRY_RUN=0
SKIP_PUB_CHECK=0
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --skip-pub-check)
      SKIP_PUB_CHECK=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$VERSION" ]]; then
        echo "Only one version argument is allowed." >&2
        exit 2
      fi
      VERSION="$1"
      ;;
  esac
  shift
done

if [[ -z "$VERSION" ]]; then
  read -r -p "Version to tag (for example 0.2.0): " VERSION
fi
VERSION="${VERSION#v}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid version: '$VERSION'. Expected semver like 0.2.0." >&2
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

for command in git curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

if [[ "$(git status --porcelain)" != "" ]]; then
  echo "Working tree is not clean. Commit or stash changes before tagging." >&2
  git status --short >&2
  exit 1
fi

BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"
if [[ "$BRANCH" != "master" ]]; then
  echo "Release tags must be created on master (current: '${BRANCH:-detached HEAD}')." >&2
  exit 1
fi

echo "Fetching origin..."
git fetch origin master --tags --quiet

HEAD_SHA="$(git rev-parse HEAD)"
ORIGIN_SHA="$(git rev-parse origin/master)"
if [[ "$HEAD_SHA" != "$ORIGIN_SHA" ]]; then
  echo "HEAD does not match origin/master." >&2
  echo "Push the release commit first, or pull/rebase before tagging." >&2
  exit 1
fi

PACKAGES=(axle_core axle_cli axle_shelf axle_relic axle_serverpod)
PENDING_PACKAGES=()
PENDING_TAGS=()
NEW_TAGS=()
PUBLISHED_PACKAGES=()
ALREADY_PUSHED=()
CORE_PUBLISHED=0

pub_version_exists() {
  local package="$1"
  local version="$2"
  local response

  if ! response="$(curl --fail --silent --show-error \
      --connect-timeout 5 --max-time 15 \
      "https://pub.dev/api/packages/$package" 2>/dev/null)"; then
    return 2
  fi

  printf '%s' "$response" |
    jq --exit-status --arg version "$version" \
      '.versions[] | select(.version == $version)' >/dev/null
}

for package in "${PACKAGES[@]}"; do
  pubspec="packages/$package/pubspec.yaml"
  tag="$package-v$VERSION"

  if [[ ! -f "$pubspec" ]]; then
    echo "Missing package pubspec: $pubspec" >&2
    exit 1
  fi

  package_version="$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | head -n 1 | tr -d '"')"
  if [[ "$package_version" != "$VERSION" ]]; then
    echo "$package is version '$package_version', but requested '$VERSION'." >&2
    exit 1
  fi

  local_tag_commit=""
  if git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null; then
    local_tag_commit="$(git rev-list -n 1 "$tag")"
    if [[ "$local_tag_commit" != "$HEAD_SHA" ]]; then
      echo "Local tag $tag points at $local_tag_commit, not HEAD ($HEAD_SHA)." >&2
      exit 1
    fi
  fi

  remote_tag_exists=0
  if [[ -n "$(git ls-remote --tags origin "refs/tags/$tag")" ]]; then
    remote_tag_exists=1
  fi

  if [[ "$SKIP_PUB_CHECK" -eq 0 ]]; then
    if pub_version_exists "$package" "$VERSION"; then
      echo "SKIP  $package $VERSION is already published on pub.dev"
      PUBLISHED_PACKAGES+=("$package")
      if [[ "$package" == "axle_core" ]]; then
        CORE_PUBLISHED=1
      fi
      continue
    else
      status=$?
      if [[ "$status" -eq 2 ]]; then
        echo "Could not query pub.dev for $package." >&2
        echo "Re-run with --skip-pub-check only if you have verified versions manually." >&2
        exit 1
      fi
    fi
  fi

  if [[ "$remote_tag_exists" -eq 1 ]]; then
    echo "SKIP  $tag already exists on origin"
    ALREADY_PUSHED+=("$tag")
    continue
  fi

  PENDING_PACKAGES+=("$package")
  PENDING_TAGS+=("$tag")
  if [[ -z "$local_tag_commit" ]]; then
    NEW_TAGS+=("$tag")
  fi
done

if [[ "${#PENDING_TAGS[@]}" -eq 0 ]]; then
  echo
  echo "Nothing to tag. Every requested version is already published or tagged."
  if [[ "${#PUBLISHED_PACKAGES[@]}" -gt 0 ]]; then
    printf 'Already published: %s\n' "${PUBLISHED_PACKAGES[*]}"
  fi
  if [[ "${#ALREADY_PUSHED[@]}" -gt 0 ]]; then
    printf 'Already tagged: %s\n' "${ALREADY_PUSHED[*]}"
  fi
  exit 0
fi

echo
echo "Version: $VERSION"
echo "Commit:  $HEAD_SHA"
echo "Tags to push:"
for i in "${!PENDING_TAGS[@]}"; do
  printf '  %-24s %s\n' "${PENDING_TAGS[$i]}" "${PENDING_PACKAGES[$i]}"
done
if [[ "${#NEW_TAGS[@]}" -gt 0 ]]; then
  echo "New local tags:"
  for tag in "${NEW_TAGS[@]}"; do
    printf '  %s\n' "$tag"
  done
fi
if [[ "${#PUBLISHED_PACKAGES[@]}" -gt 0 ]]; then
  printf 'Already published (skipped): %s\n' "${PUBLISHED_PACKAGES[*]}"
fi
if [[ "${#ALREADY_PUSHED[@]}" -gt 0 ]]; then
  printf 'Already tagged remotely (skipped): %s\n' "${ALREADY_PUSHED[*]}"
fi
echo

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run: no tags created or pushed."
  exit 0
fi

read -r -p "Create/push these tags? [y/N] " confirmation
if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
  echo "Aborted."
  exit 0
fi

for tag in "${NEW_TAGS[@]}"; do
  package="${tag%-v$VERSION}"
  git tag --annotate "$tag" --message "Release $package $VERSION"
  echo "Created $tag"
done

CORE_TAG="axle_core-v$VERSION"
CORE_PENDING=0
for tag in "${PENDING_TAGS[@]}"; do
  if [[ "$tag" == "$CORE_TAG" ]]; then
    CORE_PENDING=1
    break
  fi
done

if [[ "$CORE_PENDING" -eq 1 ]]; then
  echo
  echo "Pushing core first: $CORE_TAG"
  git push origin "$CORE_TAG"
fi

ADAPTER_TAGS=()
for tag in "${PENDING_TAGS[@]}"; do
  if [[ "$tag" != "$CORE_TAG" ]]; then
    ADAPTER_TAGS+=("$tag")
  fi
done

if [[ "${#ADAPTER_TAGS[@]}" -gt 0 ]]; then
  if [[ "$CORE_PENDING" -eq 1 ]] || [[ "$CORE_PUBLISHED" -eq 0 ]]; then
    echo
    echo "Wait until axle_core $VERSION is indexed on pub.dev before publishing adapters."
    read -r -p "Press Enter to push the remaining tags, or Ctrl-C to stop here. "
  fi

  for tag in "${ADAPTER_TAGS[@]}"; do
    echo "Pushing $tag"
    git push origin "$tag"
  done
fi

echo
echo "All requested publish tags were pushed."
echo "Monitor the GitHub Actions Publish runs and verify each package on pub.dev."
