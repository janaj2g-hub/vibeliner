#!/bin/bash
# Install the Vibeliner design system pre-commit hook into .git/hooks/pre-commit.
# Idempotent: asks before overwriting an existing hook.

set -e

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: not inside a git working tree" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOK_PATH="$REPO_ROOT/.git/hooks/pre-commit"
TEMPLATE="$REPO_ROOT/scripts/pre-commit-template.sh"

if [ ! -f "$TEMPLATE" ]; then
  echo "Error: template not found at $TEMPLATE" >&2
  exit 1
fi

if [ -f "$HOOK_PATH" ]; then
  echo "A pre-commit hook already exists at $HOOK_PATH"
  read -p "Overwrite? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled."
    exit 0
  fi
fi

cp "$TEMPLATE" "$HOOK_PATH"
chmod +x "$HOOK_PATH"
echo "Installed pre-commit hook at $HOOK_PATH"
echo "Test it: run 'git commit --allow-empty -m test' (then reset if you don't want it)"
echo "Uninstall: rm $HOOK_PATH"
