# ark-flutter-sample

A sample project demonstrating how to integrate [ark-rs](https://github.com/ArkLabsHQ/ark-rs/) with
Flutter using [flutter-rust-bridge](https://cjycode.com/flutter_rust_bridge/). This project serves
as a reference implementation for building an Ark Wallet using Flutter and Rust.

## Features

- Ark wallet functionality
- Cross-platform support (iOS/Android)
- Rust backend for performance and security

## Prerequisites

- Flutter SDK (latest stable version)
- Rust toolchain
- iOS Simulator or Android Emulator
- [flutter-rust-bridge](https://cjycode.com/flutter_rust_bridge/)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/ArkLabsHQ/ark-flutter-sample.git
   cd ark-flutter-sample
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Flutter-Rust bindings :
   NOTE: make sure you have the correct flutter version installed as defined in .fmrc!
   ```bash
   just ffi-build
   ```

4. Create a copy of `.env_sample` and call it `.env`. Adjust the variables if necessary

5. Build for your target platform

```bash
just ios-build
just android-build
```

5. Run the app:
   ```bash
   flutter run
   ```

## Development

### Rust Code Changes

When making changes to the Rust code:

1. Regenerate the Flutter bindings:
   ```bash
   flutter_rust_bridge_codegen generate --watch
   ```

2. Restart the Flutter app:
   ```bash
   flutter run
   ```
   Note: Hot-reload/hot-restart is not currently supported for Rust code changes.

### Project Structure

- `lib/` - Flutter/Dart code
- `rust/` - Rust code
