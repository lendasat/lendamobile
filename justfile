set dotenv-load

## ------------------------
## rust helper functions
## ------------------------

rust-build:
    flutter_rust_bridge_codegen generate

rust-watch:
    flutter_rust_bridge_codegen generate

clippy:
    #!/usr/bin/env bash
    set -euxo pipefail
    cd rust
    cargo clippy --all-targets --all-features -- -D warnings


## ------------------------
## fluttrer helper functions
## ------------------------

run:
    flutter run

flutter-fmt:
    dart format  --output=write .
