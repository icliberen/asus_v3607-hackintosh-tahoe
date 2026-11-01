#!/bin/bash
# Compile and run a small Metal compute workload. No display reconfiguration.
set -euo pipefail
TASK_ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$TASK_ROOT/build"
xcrun clang -fobjc-arc -framework Foundation -framework Metal -framework CoreGraphics \
  "$TASK_ROOT/Scripts/metal-check.m" -o "$TASK_ROOT/build/metal-check"
"$TASK_ROOT/build/metal-check"
