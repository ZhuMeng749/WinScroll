#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/toolchain.sh
mkdir -p .build/checks
xcrun swiftc -enable-testing -emit-library -static -emit-module -module-name ScrollCore Sources/ScrollCore/*.swift -o .build/checks/libScrollCore.a -emit-module-path .build/checks/ScrollCore.swiftmodule
cp scripts/check-scroll.swift .build/checks/main.swift
xcrun swiftc -I .build/checks -L .build/checks -lScrollCore .build/checks/main.swift -o .build/checks/ScrollCoreTests
.build/checks/ScrollCoreTests
