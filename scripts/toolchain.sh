# Respect an explicit SDK; otherwise use the selected developer directory's
# canonical SDK. xcrun can pick an incompatible leftover beta SDK by version.
if [ -z "${SDKROOT:-}" ]; then
    developer_dir="$(xcode-select -p)"
    if [ -d "$developer_dir/SDKs/MacOSX.sdk" ]; then
        export SDKROOT="$developer_dir/SDKs/MacOSX.sdk"
    else
        export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
    fi
fi
