#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/toolchain.sh
app="$PWD/dist/WinScroll.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" .build/manual
arch="$(uname -m)"
xcrun swiftc -O -target "$arch-apple-macosx13.0" -emit-library -static -emit-module -module-name ScrollCore Sources/ScrollCore/*.swift -o .build/manual/libScrollCore.a -emit-module-path .build/manual/ScrollCore.swiftmodule
xcrun swiftc -O -target "$arch-apple-macosx13.0" -I .build/manual -L .build/manual -lScrollCore Sources/WinScroll/*.swift -o "$app/Contents/MacOS/WinScroll"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp LICENSE REFERENCES.md "$app/Contents/Resources/"
xcrun swift scripts/make-icon.swift "$PWD/.build/AppIcon.iconset"
iconutil -c icns .build/AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
# File-provider folders can attach Finder metadata to a freshly made bundle.
xattr -dr com.apple.FinderInfo "$app" 2>/dev/null || true
codesign --force --sign "${WINSCROLL_SIGN_IDENTITY:--}" "$app"
codesign --verify --deep --strict "$app"
ditto -c -k --norsrc --noextattr --noqtn --keepParent "$app" "$PWD/dist/WinScroll-macOS.zip"
printf '已生成 %s\n' "$app"
