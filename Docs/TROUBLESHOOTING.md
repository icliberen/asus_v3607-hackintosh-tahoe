# Troubleshooting and recovery

## Metal is listed, but the desktop is slow or wallpaper is white

Check the actual display bridge before changing GPU drivers:

```sh
sysctl debug.nvaccel_iop_ok debug.nvaccel_iop_fail debug.nmintelfb_agdc debug.nvaccel_iop
nvram nullmoth-intelfb-attaching
nvram nullmoth-intelfb-trail
```

The transferred-frame counter should advance when the desktop changes, failures should stay zero, and AGDC/IOP should be active. Run the included Metal compute test as a separate check. A Metal device listing by itself was not sufficient during the earlier failed boot.

One observed cause was a stale `nullmoth-intelfb-attaching=1` marker. NMIntelFB keeps it until 120 seconds after successful panel startup. An orderly shutdown before that point could leave a working session marked as failed. The next boot skipped the bridge and retained basic firmware display output.

The installed auto script now remains available during this interval and cleans the pending marker on an orderly stop only when all of these are verified: positive frame count, zero copy failures, active AGDC, active IOP, and NMIntelFB timing. It does not declare a failed start successful.

If inspection confirms a stale marker from a previously successful session, the documented one-time recovery is:

```sh
sudo nvram -d nullmoth-intelfb-attaching
```

Then reboot normally. Do not clear it repeatedly to force a driver that is actually hanging. Preserve the trail/log first. The bridge skipped during probe cannot be safely restored by reloading the active display stack in the current session.

## Black screen or unusable graphics boot

The recorded OpenCore picker contains **GPU Recovery - NVIDIA OFF**, using the official `NullMothSafe.efi` tool. The tool sets the upstream recovery state after its confirmation; the manually installed setup here does not include the 1401 app's automatic uninstall service.

The upstream alternative is a recovery boot with **`-nvoff`**, which disables the NVIDIA path and causes the bridge to stand down, allowing the firmware framebuffer. `-nmintelfboff` or `nullmoth-intelfb=0` can disable only the Intel bridge for diagnosis. Consult [nmx-intel recovery](https://github.com/kitsuneislife/nmx-intel#if-something-goes-wrong) and the matching NullMoth release before using recovery flags.

Keep **your own** known-good config and full runtime backup. This public repository intentionally omits private `GPU-Rollback` configurations and machine-specific restore scripts because they can contain identities or refer to backup paths that exist only on the original installation. OpenShell remains in the config, but shell commands must target the correct EFI filesystem on your machine.

## Slow boot and LQM-WiFi lines

`BE`, `BK`, `VI` and `VO` in LQM-WiFi output identify traffic statistics; their presence did not establish a Wi-Fi connection failure. Recorded boot logs showed graphics initialization still progressing while those lines remained visible.

The bridge retains a deliberate 45-second handoff delay because a no-delay upstream trial froze. The local service removed an additional unconditional 15-second pause in favor of readiness checks. That does not guarantee a 15-second improvement in total boot time.

## Shutdown hangs

The final BIOS .305 S5 wrapper calls the original root firmware method, then clears both XHCI `PMEE` and LPCB `SLPE` for Darwin S5. The first PMEE-only wrapper had not resolved the full power-off problem. The owner later confirmed that shutdown fully powered off after the additional correction.

If a different BIOS fails to match the root `_PTS` rename, the wrapper is not equivalent to the tested configuration. Do not use a broad `_PTS` text replacement; the BIOS contains other similar names.

## Repeated ACPI buffer errors

The ASUS WMI method creates five DWORD fields unconditionally. AsusSMC previously supplied an eight-byte query, while the BIOS expected twenty. The paired WMI wrapper pads short Darwin buffers and forwards other requests. Confirm the wrapper and scoped rename both match before blaming the battery driver.

## Audio, Wi-Fi and touchpad

- No audio device: confirm the loading order **Lilu → AppleALC → SimpleHDA**, `keepsyms=1`, and `alcid=5`. Do not stack multiple AppleHDA restoration methods.
- Wi-Fi: use the **Tahoe AirportBZ** binary, not a Sequoia binary with edited kernel limits. Its documented baseline excludes WPA3-only/mandatory-PMF, 6 GHz, MLO and AirDrop. This laptop's WPA2 connection worked, but the upstream BE200 path remains experimental.
- Touchpad: VoodooGPIO is a required dependency. Preserve the I2C controller match overrides and polling SSDT. Bottom-right secondary click is a per-user macOS setting, not a separate hardware driver.

## Sleep

There is no established fix in this repository. Related [nmx-intel sleep/hibernation tests](https://github.com/kitsuneislife/nmx-intel/blob/main/docs/tests/sleep-1-hibernate.md) observed the Intel display state becoming zero after S3 and a panel that did not relight. Both hibernation experiments still entered ordinary sleep and failed to restore the panel. They were on another machine, not a successful ASUS resume test.

Keep system sleep disabled for the documented profile. A working NVIDIA sleep implementation alone does not establish working Intel eDP resume through this bridge.
