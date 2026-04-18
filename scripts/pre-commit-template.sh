#!/bin/bash
# Vibeliner design system pre-commit hook — installed by scripts/install_pre_commit_hook.sh.
# Runs validation before every commit. Bypass with: git commit --no-verify

python3 "$(git rev-parse --show-toplevel)/scripts/validate_design_system.py"
STATUS=$?

if [ $STATUS -eq 2 ]; then
  echo "warning: Design system validator errored. Commit allowed but please investigate."
  exit 0
fi

if [ $STATUS -ne 0 ]; then
  echo ""
  echo "Design system docs are out of sync. Fix errors above, or use 'git commit --no-verify' to bypass."
  exit 1
fi

exit 0
