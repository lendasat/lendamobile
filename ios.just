
release:
    #!/usr/bin/env bash
    set -euxo pipefail

    just ffi-build
    just ios-build
    fvm flutter build ipa
    echo "You can now manually upload the IPA file"