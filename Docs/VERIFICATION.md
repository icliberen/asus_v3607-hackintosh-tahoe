# Verification record — November 1, 2026

This combines publication-time read-only checks, earlier instrumented measurements, and explicitly attributed owner feedback. No sleep test, shutdown cycle, screen-mode change or live driver reload was performed during publication.

## Current runtime

```text
macOS 26.7.2 (25G332), Darwin 25.6.0
CPU: Intel Core 5 210H
Main display: 1920x1200; reported refresh 143.000 Hz
Metal device: NVIDIA GeForce RTX 4050 Laptop GPU
             NVMTL over NVIDIA GeForce RTX 4050 Laptop GPU (NVK AD107-A)
PASS: MSL compiled, GPU command completed, all 256 results correct.
NMIntelFB present and active
AGDC: 1
IOP: 1
Panel-copy counter: 74988 -> 74993 over a two-second sample
Copy error counter: 0
System sleep: SleepDisabled 1
CoreAudio: Built-in Output / Internal Speakers; Built-in Microphone
Battery: percentage and AC state present
```

The compute test compiles MSL, dispatches 256 GPU threads and verifies `result[i] == i * 3 + 7`. It tests execution and readback, rather than only device enumeration. It is not a benchmark or a comprehensive graphics conformance test. The sample copy count is not a measurement of physical panel refresh or sustained rendered FPS.

Machine-readable, privacy-filtered values are in [runtime-verification.json](../Manifests/runtime-verification.json).

## Earlier direct panel measurement

The prior diagnostic probe counted 36 physical frame-counter increments over 250.535 ms: approximately **143.692 Hz**, consistent with the nominal 144 Hz panel. Firmware memory checks validated all 16,384 GGTT entries in the first 64 MiB. The adopted mode was 1920 × 1200, stride 7680, with CMTG active. This direct physical measurement was not repeated during publication.

A prior macOS session reported 144 Hz, while the present session reports 143 Hz. The repository records both and does not label every mode report an exact 144.000 Hz measurement.

## Owner-confirmed behavior

The repair history includes confirmation of working Wi-Fi, touchpad, keyboard illumination, battery reporting, a smooth Metal desktop and complete shutdown after the S5 correction. The current request reports all everyday functions working except sleep. Internal audio devices were independently observed in the present runtime. Bluetooth was reported working originally but was off when inspected today; no new pairing test was performed.

USB-C, external displays, all hotkeys, DRM, video acceleration, battery endurance and long-duration professional workloads have no complete validation record here.

## Publication checks

- Sanitized OpenCore config passed **ocvalidate 1.0.8: No issues found**.
- Every included plist parsed successfully; enabled AML lengths and ACPI checksums passed.
- The local EFI assembler reconstructed enabled components from the known snapshot; identities remained blank/zero.
- Bridge service and utility scripts passed shell syntax validation.
- The local NMIntelFB source rebuilt successfully with the included helper. Its executable was byte-for-byte identical to the installed runtime-tested binary: `f3c91794c7ad3796eb8093c8489a3ba24f5fcb28dbc7ff8f514f945d78d91ea1`. Compilation emitted upstream header/deprecation warnings (33), with no errors.
- The included Metal check compiled and executed successfully on this machine.
- Public files were scanned for the private SMBIOS serial/MLB/UUID/ROM, local usernames/paths and obvious credential material.
- Standard NVIDIA and EFI dependency binaries, the AppleHDA payload, raw chat history and private rollback configurations are excluded.

These checks do not establish that a newly assembled EFI will boot on another machine. Generate an identity, supply matching dependencies, and test your own hardware.
