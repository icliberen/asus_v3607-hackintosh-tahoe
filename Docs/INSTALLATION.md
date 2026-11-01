# Reproducing the ASUS setup

This is a record of an existing installation, not a universal installer. Use the exact hardware/BIOS identifiers in the README. Keep a bootable recovery USB and your own full EFI backup. Do not overwrite Microsoft or Linux boot files on a shared EFI partition.

## 1. Prepare the OpenCore dependencies

Obtain **OpenCore 1.0.8 DEBUG** and the enabled kext versions listed in [the dependency manifest](../Manifests/efi-dependencies.json). The manifest includes the executable SHA-256 fingerprints from the working snapshot. A source link may point to a release page rather than a direct asset; select the matching version and OS target.

Important distinctions:

- AirportBZ's **Tahoe** build is still named `AirportItlwm.kext`. The Sequoia binary and ordinary OpenIntelWireless AirportItlwm are not substitutes.
- The machine used a **Mod AMFIPass 1.4.1** carried over from its previous WhateverXe environment. The generic project link identifies its provenance, not a verified byte-identical replacement. Compare the manifest hash before substituting another build.
- The VoodooI2C and XHCI property lists include this machine's controller matching. The assembler reapplies `Overrides/` after copying upstream bundles.
- Download **SimpleHDA 1.0.0** from its author. Its restoration payload is not bundled here. The optional SimpleHDA HAL package was not installed on this laptop.
- Disabled entries remain in the configuration as a record. The assembler only requires enabled drivers; do not enable all entries with an automatic snapshot operation.
- OpenCanopy's Resources directory comes from the compatible [OcBinaryData](https://github.com/acidanthera/OcBinaryData) distribution. `NullMothSafe.efi` is obtained from the NullMoth 2.6.5 package. The assembler does not fetch dependencies or write to an ESP.

Extract downloads under a local `vendor/` directory. It can contain nested release directories; the assembler searches recursively for bundle names and core files.

```sh
python3 Scripts/assemble-efi.py --vendor ./vendor --output ./dist/EFI
```

If multiple versions of a component exist, the assembler rejects ambiguous matches. The output directory must not exist. Missing dependencies are reported before output is created. The dependency hashes document the installed builds; different release/debug packages can have the same version and different binaries. Any difference is reported for review rather than silently described as byte-identical.

## 2. Add your own identity

The public `PlatformInfo > Generic` fields `SystemSerialNumber`, `MLB` and `SystemUUID` are blank; `ROM` contains six zero bytes. They are intentionally unusable as a shared identity.

Use GenSMBIOS or a current OpenCore editor to generate a matching **MacBookPro16,1** serial/MLB pair and a new UUID; set ROM to your own stable six-byte network identity. Edit the assembled local configuration, not the public repository. The model stays `MacBookPro16,1`. Follow [Dortania's iServices guidance](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html).

Validate with the **1.0.8** version of `ocvalidate`:

```sh
/path/to/OpenCore-1.0.8/Utilities/ocvalidate/ocvalidate ./dist/EFI/OC/config.plist
```

The original OCAT copy on this machine bundled an older validator, so its result alone was not used to qualify the 1.0.8 configuration. Test the assembled EFI from USB first. Review BIOS .305 ACPI matching before changing firmware.

## 3. Install the NVIDIA runtime inside macOS

The EFI and the graphics runtime are separate. Obtain **NullMoth 2.6.5** from [its release](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v2.6.5). The archive used here was named `nullmoth-nvidia-2.6.5.tar.gz`, SHA-256:

```text
cca98ce4255e6a0e11e8bd78158f6c288e4def92d100941e0b6b1cfe73a3c3c1
```

Verify the downloaded archive and its internal `SHA256SUMS`, then follow that release's manual installer. Use the **macOS 26** NVAccel build. Preserve the existing Intel-connected firmware framebuffer recovery path; this ASUS profile does not block IONDRVSupport or copy the upstream discrete-monitor BAR example.

Required runtime locations include:

```text
/Library/Extensions/NVRM.kext
/Library/Extensions/NVAccel.kext
/Library/Extensions/NVRMFB.kext
/Library/Extensions/NVRMAGDC.kext
/Library/GPUBundles/NVMTLDriver.bundle
/Library/GPUBundles/NVIDIAShared.bundle
/Library/GPUBundles/nvmtl/
/Library/NullMoth/nvfw/
```

The NVIDIA installer provides much more than four kexts. Copying those four alone is insufficient. Never inject a second copy of the graphics kexts from `EFI/OC/Kexts`.

## 4. Add the ASUS panel bridge and services

`Graphics/Library/Extensions/NMIntelFB.kext` is the locally installed A7AB build. Its corresponding source is in `Graphics/NMIntelFB-source`; the applied upstream patch series is retained in `Graphics/patches`. The source is already patched: do not apply the series again to that directory.

After backing up an existing graphics runtime, stage these files at the corresponding system locations:

| Repository file | Installed path |
|---|---|
| `Graphics/Library/Extensions/NMIntelFB.kext` | `/Library/Extensions/NMIntelFB.kext` |
| `Graphics/usr/local/libexec/nmx-intelfb-auto.sh` | `/usr/local/libexec/nmx-intelfb-auto.sh` |
| `Graphics/usr/local/libexec/nmx-intelfb-enable.sh` | `/usr/local/libexec/nmx-intelfb-enable.sh` |
| `Graphics/Library/LaunchDaemons/com.nmxintel.intelfb-auto.plist` | `/Library/LaunchDaemons/com.nmxintel.intelfb-auto.plist` |
| `Graphics/Library/NullMoth/bootguard.sh` | `/Library/NullMoth/bootguard.sh` |
| `Graphics/Library/LaunchDaemons/com.nullmoth.bootguard.plist` | `/Library/LaunchDaemons/com.nullmoth.bootguard.plist` |

Use `root:wheel` ownership, executable permissions for scripts/kext executables and 644 for LaunchDaemon property lists. The bundled auto script is stored with its **installed filename**; its inherited upstream `install` mode expects `auto.sh`/`enable.sh` and is not the installation method for this directory. Copy the two installed-name scripts and supplied plist as shown instead.

Rebuild the Auxiliary Kernel Collection after the five graphics kexts have been installed, using the matching NullMoth release's installation tooling or macOS's `kmutil`. The original deployment passed combined kernel-collection checks. Allow the extensions in macOS Privacy & Security if requested. A reboot is required; do not attempt live unload/reload of the active display driver.

The tested OpenCore security values are recorded in the README. They substantially reduce signature/loading protections and are required by this particular experimental profile. WhateverXe and its earlier Intel runtime were removed from the active path; do not combine both rendering stacks casually.

Set the separate panel delay and disable unsupported system sleep:

```sh
sudo nvram nullmoth-intelfb-delay=45
sudo pmset -a disablesleep 1
```

These commands affect the machine, unlike the local EFI assembler and read-only verification scripts. The 45-second delay is retained because the upstream bridge recorded a freeze without it. The sleep setting does not claim to implement resume or hibernation.

## 5. Validate after reboot

Allow the bridge time to take over. A first boot can take several minutes. Run:

```sh
bash Scripts/check-runtime.sh
bash Scripts/test-metal.sh
```

Verify the RTX Metal device, a successful GPU compute result, active NMIntelFB/AGDC, growing `debug.nvaccel_iop_ok` and zero `debug.nvaccel_iop_fail`. Confirm the internal display mode and actually use the trackpad, speakers, Wi-Fi and battery reporting. No driver listing alone proves those functions.

## Bridge source builds

`Graphics/Build-reference/build.sh` is the retained upstream build reference, not a drop-in build command from its relocated directory. It documents compilation against kernel SDK headers and NVIDIA KAPI **615.78.08**, with NullMoth baseline **v2.5.4** and patches **0001–0021**. For the already-patched ASUS source snapshot, use [the local build helper](../Scripts/build-nmintelfb.sh):

```sh
bash Scripts/build-nmintelfb.sh
```

It writes only under `build/`, downloads the pinned NVIDIA headers, and does not install or load the driver. A different compiler/SDK can produce a different binary hash. The checked-in installed binary is the runtime-tested artifact.
