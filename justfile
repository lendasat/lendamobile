import 'common.just'

mod ios
mod android

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

run: check-env
    fvm flutter run --verbose {{dart-defines}}

## ------------------------
## formatting
## ------------------------

rust-fmt:
    dprint fmt

flutter-fmt:
    find lib -name "*.dart" -not -path "lib/l10n/*" | xargs fvm dart format --output=write

fmt: rust-fmt flutter-fmt

rust-fmt-check:
    dprint check

flutter-fmt-check:
    find lib -name "*.dart" -not -path "lib/l10n/*" | xargs fvm dart format --output=none --set-exit-if-changed

fmt-check: rust-fmt-check flutter-fmt-check
