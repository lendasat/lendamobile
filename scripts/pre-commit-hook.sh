#!/bin/bash

# Pre-commit hook that mirrors CI/CD quality checks
# Runs: dprint check, dart format check, and optionally clippy
#
# Environment variables:
#   SKIP_PRECOMMIT=1     - Skip all checks
#   SKIP_CLIPPY=1        - Skip clippy (faster commits)
#   AUTO_FIX=1           - Auto-fix formatting issues instead of failing
#
# Usage:
#   git commit                    # Run all checks
#   SKIP_CLIPPY=1 git commit     # Skip clippy for faster commits
#   AUTO_FIX=1 git commit        # Auto-fix formatting before commit
#   SKIP_PRECOMMIT=1 git commit  # Skip all checks (use sparingly!)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Skip all checks if requested
if [ "${SKIP_PRECOMMIT:-0}" = "1" ]; then
    echo -e "${YELLOW}⚠️  Skipping pre-commit checks (SKIP_PRECOMMIT=1)${NC}"
    exit 0
fi

echo -e "${BLUE}Running pre-commit quality checks...${NC}"
echo ""

# Track failures
FAILED=0

# Detect if we're in WSL
is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# Get staged files by type
get_staged_files() {
    local pattern="$1"
    git diff --cached --name-only --diff-filter=ACM | grep -E "$pattern" || true
}

STAGED_DART_FILES=$(get_staged_files '\.dart$' | grep -v '\.freezed\.dart$' | grep -v '\.g\.dart$' | grep -v 'frb_generated' || true)
STAGED_RUST_FILES=$(get_staged_files '\.rs$' | grep -v 'frb_generated' || true)
STAGED_CONFIG_FILES=$(get_staged_files '\.(json|yaml|yml|toml|md)$' || true)

# ============================================
# 1. DPRINT CHECK (JSON, YAML, TOML, Markdown, Rust)
# ============================================
if command -v dprint &> /dev/null; then
    echo -e "${BLUE}[1/3] Checking dprint formatting...${NC}"

    if [ "${AUTO_FIX:-0}" = "1" ]; then
        # Auto-fix mode
        if [ -n "$STAGED_CONFIG_FILES" ] || [ -n "$STAGED_RUST_FILES" ]; then
            dprint fmt 2>/dev/null || true
            # Re-add formatted files
            for file in $STAGED_CONFIG_FILES $STAGED_RUST_FILES; do
                if [ -f "$file" ]; then
                    git add "$file" 2>/dev/null || true
                fi
            done
            echo -e "  ${GREEN}✓ Auto-formatted with dprint${NC}"
        else
            echo -e "  ${GREEN}✓ No config/rust files to check${NC}"
        fi
    else
        # Check mode (mirrors CI)
        if ! dprint check 2>&1; then
            echo -e "  ${RED}✗ dprint check failed${NC}"
            echo -e "  ${YELLOW}Run 'dprint fmt' to fix, or commit with AUTO_FIX=1${NC}"
            FAILED=1
        else
            echo -e "  ${GREEN}✓ dprint check passed${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[1/3] Skipping dprint (not installed)${NC}"
fi

# ============================================
# 2. DART FORMAT CHECK
# ============================================
echo -e "${BLUE}[2/3] Checking Dart formatting...${NC}"

if [ -n "$STAGED_DART_FILES" ]; then
    # Determine dart command
    DART_CMD=""
    if is_wsl; then
        # Try FVM through cmd.exe first
        if cmd.exe /c "fvm dart --version" >/dev/null 2>&1; then
            DART_CMD="cmd.exe /c fvm dart"
        elif cmd.exe /c "dart --version" >/dev/null 2>&1; then
            DART_CMD="cmd.exe /c dart"
        fi
    else
        if command -v fvm &> /dev/null; then
            DART_CMD="fvm dart"
        elif command -v dart &> /dev/null; then
            DART_CMD="dart"
        fi
    fi

    if [ -z "$DART_CMD" ]; then
        echo -e "  ${YELLOW}⚠️  Dart not found, skipping Dart format check${NC}"
    else
        if [ "${AUTO_FIX:-0}" = "1" ]; then
            # Auto-fix mode
            for file in $STAGED_DART_FILES; do
                if [ -f "$file" ]; then
                    if is_wsl; then
                        win_path=$(wslpath -w "$(pwd)/$file")
                        $DART_CMD format --output=write "$win_path" >/dev/null 2>&1 || true
                    else
                        $DART_CMD format --output=write "$file" >/dev/null 2>&1 || true
                    fi
                    git add "$file"
                fi
            done
            echo -e "  ${GREEN}✓ Auto-formatted Dart files${NC}"
        else
            # Check mode (mirrors CI) - check only staged files
            DART_CHECK_FAILED=0
            for file in $STAGED_DART_FILES; do
                if [ -f "$file" ]; then
                    if is_wsl; then
                        win_path=$(wslpath -w "$(pwd)/$file")
                        if ! $DART_CMD format --output=none --set-exit-if-changed "$win_path" >/dev/null 2>&1; then
                            echo -e "  ${RED}✗ $file${NC}"
                            DART_CHECK_FAILED=1
                        fi
                    else
                        if ! $DART_CMD format --output=none --set-exit-if-changed "$file" >/dev/null 2>&1; then
                            echo -e "  ${RED}✗ $file${NC}"
                            DART_CHECK_FAILED=1
                        fi
                    fi
                fi
            done

            if [ "$DART_CHECK_FAILED" = "1" ]; then
                echo -e "  ${RED}✗ Dart format check failed${NC}"
                echo -e "  ${YELLOW}Run 'just flutter-fmt' to fix, or commit with AUTO_FIX=1${NC}"
                FAILED=1
            else
                echo -e "  ${GREEN}✓ Dart format check passed${NC}"
            fi
        fi
    fi
else
    echo -e "  ${GREEN}✓ No Dart files to check${NC}"
fi

# ============================================
# 3. CLIPPY (Rust linting)
# ============================================
if [ "${SKIP_CLIPPY:-0}" = "1" ]; then
    echo -e "${YELLOW}[3/3] Skipping clippy (SKIP_CLIPPY=1)${NC}"
elif [ -z "$STAGED_RUST_FILES" ]; then
    echo -e "${BLUE}[3/3] Skipping clippy (no Rust files staged)${NC}"
elif ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}[3/3] Skipping clippy (cargo not found)${NC}"
else
    echo -e "${BLUE}[3/3] Running clippy...${NC}"

    # Run clippy from rust directory
    if [ -d "rust" ]; then
        cd rust
        if ! cargo clippy --all-targets --all-features -- -D warnings 2>&1 | head -50; then
            echo -e "  ${RED}✗ Clippy found issues${NC}"
            echo -e "  ${YELLOW}Fix the warnings above before committing${NC}"
            FAILED=1
        else
            echo -e "  ${GREEN}✓ Clippy passed${NC}"
        fi
        cd ..
    else
        echo -e "  ${YELLOW}⚠️  rust/ directory not found${NC}"
    fi
fi

# ============================================
# FINAL RESULT
# ============================================
echo ""
if [ "$FAILED" = "1" ]; then
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}Pre-commit checks FAILED${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Options:"
    echo -e "  ${YELLOW}AUTO_FIX=1 git commit${NC}    - Auto-fix formatting issues"
    echo -e "  ${YELLOW}SKIP_CLIPPY=1 git commit${NC} - Skip clippy for faster commits"
    echo -e "  ${YELLOW}SKIP_PRECOMMIT=1 git commit${NC} - Skip all checks (use sparingly!)"
    echo ""
    exit 1
else
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}All pre-commit checks passed!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    exit 0
fi
