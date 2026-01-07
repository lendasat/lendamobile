import 'common.just'

release: check-env
    #!/usr/bin/env bash
    set -euxo pipefail

    BUILD_NAME=$(yq -r .version pubspec.yaml)
    BUILD_NUMBER=$(git rev-list --count HEAD)

    just ffi-build
    just ios-build
    fvm flutter build ipa \
      --release \
      --build-name=$BUILD_NAME \
      --build-number=$BUILD_NUMBER \
      {{dart-defines}}
    echo "You can now manually upload the IPA file"