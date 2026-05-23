#!/bin/sh
set -eu

DRY_RUN=0
FORCE_GH=0

usage() {
  cat <<'EOF'
Usage:
  ./tools/get-tools-macos.sh [--dry-run] [--force-gh]

Homebrew-free macOS setup helper.

It checks Apple Command Line Tools for git/clang and installs GitHub CLI from
GitHub's official macOS .pkg release when gh is missing.

Options:
  --dry-run    Print what would happen without installing anything.
  --force-gh   Reinstall/upgrade gh even if gh is already available.
  --help       Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --force-gh)
      FORCE_GH=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This helper is for macOS only." >&2
  exit 1
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN:'
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

echo "Checking Apple Command Line Tools..."
if xcode-select -p >/dev/null 2>&1; then
  echo "  OK: $(xcode-select -p)"
else
  echo "  Missing: Apple Command Line Tools"
  echo "  This opens Apple's installer prompt; rerun this script after it finishes."
  run xcode-select --install
fi

if have git; then
  echo "  git: $(git --version)"
else
  echo "  git missing; install Apple Command Line Tools first."
fi

if have clang; then
  echo "  clang: $(clang --version | sed -n '1p')"
else
  echo "  clang missing; install Apple Command Line Tools first."
fi

install_gh=0
if have gh && [ "$FORCE_GH" -eq 0 ]; then
  echo "GitHub CLI already available: $(gh --version | sed -n '1p')"
else
  install_gh=1
fi

if [ "$install_gh" -eq 1 ]; then
  if ! have curl; then
    echo "curl is required to download GitHub CLI." >&2
    exit 1
  fi

  case "$(uname -m)" in
    x86_64)
      gh_arch="amd64"
      ;;
    arm64)
      gh_arch="arm64"
      ;;
    *)
      echo "Unsupported macOS architecture for gh package: $(uname -m)" >&2
      exit 1
      ;;
  esac

  echo "Finding latest GitHub CLI macOS ${gh_arch} package..."
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: curl GitHub releases API and install matching macOS_${gh_arch}.pkg"
  else
    gh_pkg_url=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest |
      awk -F '"' -v arch="$gh_arch" '$2 == "browser_download_url" && $4 ~ ("macOS_" arch "\\.pkg$") { print $4; exit }')

    if [ -z "$gh_pkg_url" ]; then
      echo "Could not find a GitHub CLI macOS ${gh_arch} .pkg in the latest release." >&2
      exit 1
    fi

    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/codex-pet-tools.XXXXXX")
    trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
    gh_pkg="$tmp_dir/gh.pkg"

    echo "Downloading: $gh_pkg_url"
    curl -fL "$gh_pkg_url" -o "$gh_pkg"

    echo "Installing GitHub CLI package. macOS may ask for your password."
    sudo installer -pkg "$gh_pkg" -target /
  fi
fi

echo ""
echo "Tool summary:"
if have git; then
  echo "  git:   $(command -v git) ($(git --version))"
else
  echo "  git:   missing"
fi

if have clang; then
  echo "  clang: $(command -v clang)"
else
  echo "  clang: missing"
fi

if have gh; then
  echo "  gh:    $(command -v gh) ($(gh --version | sed -n '1p'))"
else
  echo "  gh:    missing"
fi

echo ""
echo "Optional Git UI app:"
echo "  GitHub Desktop: https://desktop.github.com/"
echo ""
echo "Next steps:"
echo "  cd codex-pet-watch/macosx"
echo "  ./build.sh"
