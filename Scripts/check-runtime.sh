#!/bin/bash
# Read-only: no NVRAM writes, display mode changes, driver reloads or service restarts.
set -u
printf 'macOS: '; sw_vers -productVersion
printf 'Build: '; sw_vers -buildVersion
printf 'CPU: '; sysctl -n machdep.cpu.brand_string
printf '\nGraphics services and transfer counters:\n'
sysctl debug.nvaccel_iop_ok debug.nvaccel_iop_fail debug.nmintelfb_agdc debug.nvaccel_iop debug.nvaccel_igpu debug.nvaccelfb 2>&1
printf '\nNMIntelFB presence:\n'
ioreg -r -c NMIntelFB -d1 -w0 2>/dev/null | head -12
printf '\nLoaded support drivers:\n'
kmutil showloaded --list-only 2>/dev/null | grep -E 'nullmoth|AirportItlwm|SMCBatteryManager|ECEnabler|AppleALC|SimpleHDA|AsusSMC|VoodooI2C|VoodooGPIO' || true
printf '\nSystem sleep policy:\n'
pmset -g | grep -E 'SleepDisabled|sleep|hibernate' || true
printf '\nFor refresh/Metal compute verification: bash Scripts/test-metal.sh\n'
printf 'Counters should increase while the desktop changes; listing a GPU alone is insufficient.\n'
