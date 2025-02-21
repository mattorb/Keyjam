#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
HOOK_DIR="$REPO_ROOT"/.git/hooks
echo Installing pre-commit git hook for linting to $HOOK_DIR
cp "$REPO_ROOT"/tools/githooks/pre-commit "$REPO_ROOT"/.git/hooks
