# Configuration notes

## Scope and provenance

The public config is derived from the latest November 1 local EFI recovery snapshot, after the audio, battery, WMI and S5 changes. Its stored config modification time was November 1 at 00:46 local time. The graphics boot scripts were copied from their installed locations after the later guard correction. The publication-time runtime was checked independently; this task did not alter the active EFI, power settings or installed display drivers.

The public config differs from the private snapshot only in these identity fields:

```text
PlatformInfo/Generic/SystemSerialNumber = empty string
PlatformInfo/Generic/MLB                = empty string
PlatformInfo/Generic/SystemUUID         = empty string
PlatformInfo/Generic/ROM                = 000000000000 (Data)
```

The USB map's model identifier remains MacBookPro16,1. Firmware paths, panel EDID, chipset PCI IDs and generic OpenCore GUIDs are hardware/configuration information, rather than a personal SMBIOS identity. No private fallback config or old backup is shipped.

## ACPI

| Enabled AML | Purpose |
|---|---|
| SSDT-EC-USBX-V3607 | Laptop EC / USB power properties |
| SSDT-PLUG-ALT-V3607 | Existing alternate CPU object arrangement; retained as configured, not a claim of ideal CPU topology |
| SSDT-RTCAWAC-V3607 | RTC availability through STAS; AWAC handling |
| SSDT-TPD0-V3607 | Darwin I2C serial-bus resources and polling for ASCP1201 |
| SSDT-ASUS-KBL | Firmware SLKB keyboard illumination bridge and synthetic ALS |
| SSDT-ASUS-S5 | Original _PTS call, followed by PMEE / SLPE cleanup for Darwin S5 |
| SSDT-ASUS-PNLF | Backlight device from the earlier Intel graphics attempt; retained |
| SSDT-ASUS-WMI | Zero-pad short Darwin WMNB input buffers to 20 bytes |

Three matching renames cover touchpad `_CRS → XCRS`, root `_PTS → ZPTS`, and `WMNB → XWNB`. These are exact byte-pattern matches limited to this BIOS DSDT length. The latter two also use the `Notebook` OEM table identifier. Keep each rename paired with its wrapper. On another BIOS revision, do not simply remove the match restrictions.

## Retained CPU and platform settings

The existing CPUID emulation remains `55060A00000080000000000000000000`, with mask `FFFFFFFF0000FF000000000000000000`. `ProvideCurrentCpuInfo`, `AppleXcpmCfgLock`, `CustomSMBIOSGuid` and `DisableIoMapper` remain enabled; `DummyPowerManagement` is false. CpuTopologyRebuild and SMCProcessor are disabled.

System Information currently reports 12 cores and Hyper-Threading disabled. That is the presentation of the configured macOS environment, not a verified physical-core description or proof of optimized P/E-core scheduling. No CPU power-efficiency claim is made.

## Graphics settings worth preserving

- WhateverXe's EFI entry is disabled. No active Intel-only Metal configuration is claimed.
- `IONDRVSupport` is not blocked by Kernel/Block.
- Existing BAR values remain: `Booter/Quirks/ResizeAppleGpuBars = 0`, `UEFI/Quirks/ResizeGpuBars = -1`. These are the machine's retained values, not a generic recommendation.
- `Misc/Security/SecureBootModel = Disabled`, `csr-active-config = 430A0000` and NVIDIA AMFI arguments are the tested relaxed security profile.
- The I2C polling and Bluetooth compatibility arguments remain, along with `alcid=5` and `keepsyms=1` for audio.
- The retained Intel device properties include the actual panel EDID and framebuffer memory settings. They are not a claim that WhateverXe controls the current panel.
- `nullmoth-intelfb-delay=45` is separate NVRAM state, not an entry in this OpenCore plist.

## Enabled driver versions

The [manifest](../Manifests/efi-dependencies.json) lists versions and fingerprints. Nested VoodooI2C service/GPIO/input plugins must load in their recorded order. The PS2 mouse, PS2 touchpad and PS2 VoodooInput entries are disabled; the I2C path supplies the touchpad.

AirportBZ has bundle/version strings resembling AirportItlwm but is a separate build. Its config entry is restricted to **Darwin 25**, matching Tahoe. Bluetooth drivers load independently of Wi-Fi. SimpleHDA restores the audio stack without an OCLP audio root patch in this installation; the optional HAL package was not installed.

## Sleep and service behavior

`pmset -g` reports `SleepDisabled 1`. HibernateMode remains `None` in OpenCore; the presence of `hibernatemode 3` in other power settings does not establish functional hibernation. The publication task did not change these settings.

The two system graphics LaunchDaemons are functional components. Earlier one-shot battery/display/boot-time verification LaunchAgents were removed during cleanup and are not needed for normal driver operation. Scroll Reverser is a per-user optional utility; its permissions and per-device settings are not exported here.
