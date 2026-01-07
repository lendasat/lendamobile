import 'common.just'

# Requires android/key.properties for release signing
release: check-env
    #!/usr/bin/env bash
    set -euxo pipefail

    if [ ! -f android/key.properties ]; then
        echo "Error: android/key.properties not found!"
        echo "Please create this file for release signing."
        echo "See: https://docs.flutter.dev/deployment/android"
        exit 1
    fi

    BUILD_NAME=$(yq -r .version pubspec.yaml)
    BUILD_NUMBER=$(git rev-list --count HEAD)

    just ffi-build
    just android-build
    fvm flutter build appbundle \
        --release \
        --build-name=$BUILD_NAME \
        --build-number=$BUILD_NUMBER \
        {{dart-defines}}
    echo "You can now manually upload the bundle file"
