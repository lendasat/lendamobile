set dotenv-load := true

## ------------------------
## rust helper functions
## ------------------------

ffi-build:
    flutter_rust_bridge_codegen generate

android-build:
    cd rust && cargo ndk -o ../android/app/src/main/jniLibs build

ios-build:
    cd rust && cargo build --release --target aarch64-apple-ios

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
