# LendaMobile

A mobile wallet application for Bitcoin with Ark protocol support, built with Flutter and Rust.

## Features

- Bitcoin wallet functionality
- Ark protocol integration via [ark-rs](https://github.com/ArkLabsHQ/ark-rs/)
- LendaSat loan integration
- LendaSwap exchange functionality
- Cross-platform support (iOS/Android)
- Rust backend for performance and security

## Prerequisites

- Flutter SDK (see [.fvmrc](./.fvmrc) for the required version)
- Rust toolchain
- iOS Simulator or Android Emulator
- [just](https://github.com/casey/just) command runner
- [FVM](https://fvm.app/) - All Flutter commands are run using FVM to ensure version consistency

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/lendasat/lendamobile.git
   cd lendamobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Flutter-Rust bindings:
   ```bash
   just ffi-build
   ```
   Note: Make sure you have the correct Flutter version installed as defined in `.fvmrc`

4. Create a copy of `.env_sample` and call it `.env`. Adjust the variables if necessary.

5. Build for your target platform:
   ```bash
   just ios-build
   just android-build
   ```

6. Run the app:
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
- `docs/` - Documentation

## Contributing

### PR Requirements

Before a pull request can be merged, the following commands must pass successfully:

```bash
just fmt         # Format Rust code
just clippy      # Run Rust linter
just ios-build   # Build iOS target
just android-build  # Build Android target
```

These checks are also enforced by CI.
