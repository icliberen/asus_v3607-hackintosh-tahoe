#!/bin/bash
# Build the already-patched local ASUS source; never install or load it.
set -euo pipefail
TASK_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TASK_BUILD="$TASK_ROOT/build/nmintelfb"
W="$TASK_BUILD"
mkdir -p "$TASK_BUILD/src" "$TASK_BUILD/out/NMIntelFB.kext/Contents/MacOS"
cp "$TASK_ROOT"/Graphics/NMIntelFB-source/* "$TASK_BUILD/src/"
# intelfb-0011 needs NVKMS's kernel API headers, from NVIDIA's open-gpu-kernel-modules at the tag NVRM is built from
# (MIT/GPL; fetched once per tag, not versioned here). 2.5.0 moved NVRM to 615.78.08; the 610 and 615 headers give
# the same NMIntelFB binary (the members we use did not move).
OGKM_TAG=${OGKM_TAG:-615.78.08}; KAPI=$TASK_BUILD/kapi-hdr-$OGKM_TAG
if [ ! -s "$KAPI/nvkms-kapi.h" ]; then
  mkdir -p "$KAPI"
  for f in nvidia-modeset/kapi/interface/nvkms-kapi.h common/sdk/nvidia/inc/nvtypes.h common/inc/nv_mig_types.h \
           nvidia/arch/nvalloc/unix/include/nv-gpu-info.h common/unix/common/inc/nv_dpy_id.h \
           common/unix/common/inc/nv_common_utils.h nvidia-modeset/interface/nvkms-api-types.h \
           nvidia-modeset/interface/nvkms-format.h common/sdk/nvidia/inc/cpuopsys.h common/sdk/nvidia/inc/nvlimits.h \
           common/sdk/nvidia/inc/nvmisc.h common/sdk/nvidia/inc/nvstatus.h common/sdk/nvidia/inc/nvstatuscodes.h; do
    curl -sfL -o "$KAPI/$(basename "$f")" "https://raw.githubusercontent.com/NVIDIA/open-gpu-kernel-modules/$OGKM_TAG/src/$f" \
      || { echo "could not fetch $f"; rm -f "$KAPI/nvkms-kapi.h"; exit 1; }
  done
fi
SDK=$(xcrun --show-sdk-path); KHDR="$SDK/System/Library/Frameworks/Kernel.framework/Headers"
xcrun clang++ -arch x86_64 -fapple-kext -mkernel -nostdinc -I"$KHDR" -I"$W/src" -I"$KAPI" \
  -DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT -std=c++17 -fno-rtti -fno-exceptions -fno-builtin \
  -fno-common -Wall -Wno-unused-parameter -Wno-inconsistent-missing-override -O2 \
  -c "$W/src/intelfb.cpp" -o "$TASK_BUILD/out/intelfb.o"
xcrun clang++ -arch x86_64 -fapple-kext -nostdlib -Xlinker -kext -lkmodc++ -lkmod -lcc_kext "$TASK_BUILD/out/intelfb.o" \
  -o "$TASK_BUILD/out/NMIntelFB.kext/Contents/MacOS/NMIntelFB"
cp "$W/src/Info.plist" "$TASK_BUILD/out/NMIntelFB.kext/Contents/Info.plist"
codesign -f -s - "$TASK_BUILD/out/NMIntelFB.kext"
shasum -a 256 "$TASK_BUILD/out/NMIntelFB.kext/Contents/MacOS/NMIntelFB"
