# Third-party material

The root MIT license applies to original documentation, local configuration and new utilities. It does not override upstream terms for copied or derived material.

| Material | Origin and terms |
|---|---|
| NMIntelFB binary and source | NullMoth NVIDIA driver, v2.5.4 base; **PolyForm Noncommercial 1.0.0**, full terms in `Licenses/NullMoth-LICENSE-PolyForm-Noncommercial-1.0.0.txt` |
| Bridge patches and original boot-service logic | kitsuneislife/nmx-intel; attribution and patch headers retained. The bridge remains NullMoth-derived; no MIT relicensing is claimed |
| Bridge brightness implementation | WhateverXe panel PWM work by b00t0x; BSD-3-Clause text in `Licenses/WhateverXe-LICENSE.txt` |
| Display IDs / register layout | Linux i915/xe material referenced in the source, with its MIT source notices |
| VoodooI2C override property lists | VoodooI2C 2.9.1; GPL-3.0, `Licenses/VoodooI2C-LICENSE.txt` |
| XHCI override property list | RehabMan USBInjectAll/XHCI-unsupported; GPL-2.0, `Licenses/USBInjectAll-LICENSE.txt` |

Required Notice: Copyright (c) 2026 NullMoth Systems (https://nullmothsystems.com)

Source projects: https://github.com/nullmoth/nvidia-macos-driver, https://github.com/kitsuneislife/nmx-intel, https://github.com/VoodooI2C/VoodooI2C, https://github.com/RehabMan/OS-X-USB-Inject-All.

The local changes narrow NMIntelFB matching to ASUS A7AB and adjust the boot script's readiness and orderly-stop guard handling. Optional NVAccel/NVRM optimization patches are not installed.

The included bridge is a copy of the locally installed experimental kext, with its ad-hoc signature. `Info-virtual.plist` is an upstream test-loader reference, not the installed personality.

OpenCore and standard kext executables, NVIDIA firmware and userspace libraries, and the AppleHDA restoration payload are not redistributed here. Obtain them from the authors linked in the manifest and follow their terms. `Licenses/NOTICE.txt` records additional provenance for the installed NVIDIA stack; it does not mean all listed software is bundled.
