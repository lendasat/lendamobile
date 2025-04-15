# WTFark - A Wallet That Flies on Ark

A sample project of how to use ark-rs within flutter
using [flutter-rust-bridge](https://cjycode.com/flutter_rust_bridge/).

## Getting Started

1. Install flutter for your system including setting up simulators
2. build rust backend with `flutter_rust_bridge_codegen generate`
2. run the app on your simulator `flutter run`

## Development

Whenever you make changes in the rust code, you will need to re-generate the flutter bindings.
You can do this with

```bash
flutter_rust_bridge_codegen generate --watch
```

Unfortunately, after making changes in rust, you will need to restart flutter as currently flutter does not support
hot-reload/hot-restart yet.
