# MoonBit jq clone

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Check formatting without rewriting files
fmt-check:
    moon fmt --check

# Type check (native covers both library and CLI)
check:
    moon check --deny-warn --target native

# Run library tests (js target)
test:
    moon test --target js -p mizchi/jq

# Update snapshot tests
test-update:
    moon test --update --target js -p mizchi/jq

# Generate type definition files
info:
    moon info --target native

# Verify generated type definition files are up to date
info-check:
    moon info --target native
    git diff --exit-code -- ':(glob)**/*.generated.mbti'

# Build native CLI
build:
    moon build --target native

# Run moonjq CLI
moonjq *ARGS:
    moon run cmd/moonjq --target native -- {{ARGS}}

# Clean build artifacts
clean:
    moon clean

# Pre-release check
release-check: fmt info check test

# CI checks
ci: fmt-check info-check check test
