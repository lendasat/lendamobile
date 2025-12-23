
# Requires android/key.properties for release signing
release:
    #!/usr/bin/env bash
    set -euxo pipefail

    if [ ! -f android/key.properties ]; then
        echo "Error: android/key.properties not found!"
        echo "Please create this file for release signing."
        echo "See: https://docs.flutter.dev/deployment/android"
        exit 1
    fi

    just ffi-build
    just android-build
    fvm flutter build appbundle
    echo "You can now manually upload the bundle file"
