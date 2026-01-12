# Recompiling the App from Linux/WSL

## IMPORTANT: When to Recompile Rust

**Any changes to Rust code (`rust/src/**/*.rs`) require recompilation!**

Flutter does NOT automatically rebuild Rust code. If you modify any `.rs` file, you MUST manually recompile before running the app, otherwise the old binary will be used.

### Quick Recompile Command

```bash
# From WSL/Linux - run this after ANY Rust changes:
export ANDROID_NDK_HOME=~/android-sdk/android-ndk-r27c && \
cd /mnt/c/Users/tobia/StudioProjects/lendamobile/rust && \
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
```

### How to Verify Your Changes Are Applied

Check the library timestamp after building:

```bash
ls -la android/app/src/main/jniLibs/arm64-v8a/*.so
```

The timestamp should be recent (after your code changes).

### Common Mistake

If you see unexpected behavior after changing Rust code:

1. Check if the `.so` file timestamp is older than your code changes
2. If yes, you forgot to recompile - run the command above
3. Then restart the app

---

This guide explains how to build the Rust native libraries from Linux/WSL when the Windows build fails due to OpenSSL/Perl compatibility issues.

## Problem

When building on Windows, the OpenSSL vendored build may fail with:

```
This perl implementation doesn't produce Unix like paths
```

This occurs because the OpenSSL configure script expects Unix-style paths, but Windows Perl produces Windows-style paths.

## Solution: Build from WSL/Linux

### Prerequisites

1. **WSL2 with Ubuntu** (or another Linux distro)
2. **Rust toolchain** installed in WSL:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```
3. **Android targets** for Rust:
   ```bash
   rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
   ```
4. **cargo-ndk** tool:
   ```bash
   cargo install cargo-ndk
   ```
5. **Android NDK for Linux** (not the Windows version)

### Setup Android NDK for Linux

The Windows Android NDK won't work from WSL. Download the Linux version:

```bash
mkdir -p ~/android-sdk
cd ~/android-sdk

# Download NDK r27c (or latest stable)
wget -O ndk.zip "https://dl.google.com/android/repository/android-ndk-r27c-linux.zip"

# Extract
unzip -q ndk.zip

# Set environment variable
export ANDROID_NDK_HOME=~/android-sdk/android-ndk-r27c
```

Add to your `~/.bashrc` or `~/.zshrc` for persistence:

```bash
export ANDROID_NDK_HOME=~/android-sdk/android-ndk-r27c
```

### Building the Rust Library

Navigate to the project and build:

```bash
cd /mnt/c/Users/<username>/StudioProjects/lendamobile/rust

# Build for arm64-v8a (most modern Android devices)
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release

# Optional: Build for other architectures
cargo ndk -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
cargo ndk -t x86_64 -o ../android/app/src/main/jniLibs build --release
```

### Build All Architectures at Once

```bash
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -o ../android/app/src/main/jniLibs build --release
```

### Architecture Coverage

| Architecture | Devices                              |
| ------------ | ------------------------------------ |
| arm64-v8a    | Modern phones (2017+), most common   |
| armeabi-v7a  | Older 32-bit ARM devices             |
| x86_64       | Android emulators                    |
| x86          | Old emulators, rare physical devices |

For most use cases, `arm64-v8a` is sufficient.

### After Building

The compiled `.so` files will be in:

```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── librust_lib_ark_flutter.so
├── armeabi-v7a/
│   └── librust_lib_ark_flutter.so
└── x86_64/
    └── librust_lib_ark_flutter.so
```

### Building the APK from Windows

Once the Rust libraries are compiled, you can build the Flutter app from Windows:

```cmd
flutter build apk --debug
```

Or run directly:

```cmd
flutter run
```

CargoKit will detect the pre-built libraries and skip the Rust compilation step.

## Troubleshooting

### "Could not find any NDK"

Make sure `ANDROID_NDK_HOME` is set correctly:

```bash
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/
```

### Build takes too long

The first build compiles all dependencies (~20-30 minutes). Subsequent builds are much faster as dependencies are cached.

### Library not found at runtime

Ensure the library name matches what Flutter expects:

```bash
ls android/app/src/main/jniLibs/arm64-v8a/
# Should show: librust_lib_ark_flutter.so
```

### Content hash mismatch

If you see hash mismatch errors, clean and rebuild:

```bash
cd rust
cargo clean
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
```

## Quick Reference

```bash
# One-liner to rebuild from WSL
export ANDROID_NDK_HOME=~/android-sdk/android-ndk-r27c && \
cd /mnt/c/Users/<username>/StudioProjects/lendamobile/rust && \
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
```

Replace `<username>` with your Windows username.
