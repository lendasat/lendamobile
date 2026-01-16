#!/bin/bash

# Install git hooks for the project
# Run this after cloning the repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "Installing git hooks..."

# Copy pre-commit hook
cp "$SCRIPT_DIR/pre-commit-hook.sh" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "  ✓ Installed pre-commit hook"

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will run the same checks as CI:"
echo "  - dprint check (JSON, YAML, TOML, Markdown)"
echo "  - Dart format check"
echo "  - Clippy (Rust linting, when Rust files are staged)"
echo ""
echo "Usage options:"
echo "  git commit                    # Run all checks"
echo "  SKIP_CLIPPY=1 git commit      # Skip clippy for faster commits"
echo "  AUTO_FIX=1 git commit         # Auto-fix formatting before commit"
echo "  SKIP_PRECOMMIT=1 git commit   # Skip all checks (use sparingly!)"
