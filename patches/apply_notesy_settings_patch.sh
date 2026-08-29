#!/usr/bin/env bash
set -euo pipefail

PATCH_FILE="$(dirname "$0")/notesy-settings.patch"
if [ ! -f "$PATCH_FILE" ]; then
  echo "Patch file not found: $PATCH_FILE"
  exit 1
fi

if [ ! -f "notesy/settings.py" ]; then
  echo "This script must be run from the root of the notesy-app repository where notesy/settings.py exists."
  exit 1
fi

# Create a git branch, apply patch, and show the diff
BRANCH_NAME="feat/env-django-settings-$(date +%s)"

echo "Creating branch $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Apply the patch using git apply (safe) or patch
if git apply --index "$PATCH_FILE"; then
  echo "Patch applied with git apply."
else
  echo "git apply failed, trying patch utility..."
  patch -p0 < "$PATCH_FILE"
  git add notesy/settings.py
fi

echo "Patch applied. Review changes below:"
git --no-pager diff --staged

echo "Done. Commit the change and push the branch to open a PR."
