#!/usr/bin/env python3
"""Assemble a local EFI from supplied upstream dependencies; never touch an ESP."""
import argparse
import hashlib
import json
import plistlib
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def find_one(folder, name, directory=None):
    found = [p for p in folder.rglob(name) if (directory is None or p.is_dir() == directory)]
    # A release may contain a plug-in and a second standalone copy. Require users to resolve this.
    if len(found) != 1:
        raise ValueError(f'{name}: expected one match under {folder}, found {len(found)}')
    return found[0]

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--vendor', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    args = ap.parse_args()
    vendor, output = args.vendor.resolve(), args.output.resolve()
    if not vendor.is_dir():
        ap.error('vendor directory does not exist')
    if output.exists():
        ap.error('output must not already exist')
    if output == vendor or vendor in output.parents or output in vendor.parents:
        ap.error('vendor and output must be separate directories')
    manifest = json.loads((ROOT / 'Manifests/efi-dependencies.json').read_text())
    config = plistlib.loads((ROOT / 'EFI/OC/config.plist').read_bytes())
    copies = []
    warnings = []
    try:
        for entry in manifest['kexts']:
            if entry['bundle'] == 'USBMap-ASUS.kext':
                continue
            source = find_one(vendor, entry['bundle'], directory=True)
            info = plistlib.loads((source / 'Contents/Info.plist').read_bytes())
            if info.get('CFBundleVersion') != entry['version']:
                raise ValueError(f"{entry['bundle']}: version {info.get('CFBundleVersion')} != {entry['version']}")
            for relative, expected in entry['executables_sha256'].items():
                p = source / relative
                if not p.is_file():
                    raise ValueError(f'missing executable: {p}')
                if hashlib.sha256(p.read_bytes()).hexdigest() != expected:
                    warnings.append(f"{entry['bundle']}/{relative}: differs from installed executable fingerprint")
            copies.append((source, output / 'OC/Kexts' / entry['bundle']))
        for filename, target in [('OpenCore.efi', 'OC/OpenCore.efi'), ('BOOTx64.efi', 'BOOT/BOOTx64.efi')]:
            # Match FAT-style case variations, including upstream BOOTx64.efi spelling.
            found = [p for p in vendor.rglob('*') if p.is_file() and p.name.lower() == filename.lower()]
            if len(found) != 1:
                raise ValueError(f'{filename}: expected one vendor match, found {len(found)}')
            if filename == 'OpenCore.efi' and hashlib.sha256(found[0].read_bytes()).hexdigest() != manifest['opencore']['OpenCore.efi_sha256']:
                raise ValueError('OpenCore.efi is not the recorded 1.0.8 DEBUG binary')
            copies.append((found[0], output / target))
        for item in config['UEFI']['Drivers']:
            if item['Enabled']:
                copies.append((find_one(vendor, item['Path'], False), output / 'OC/Drivers' / item['Path']))
        for item in config['Misc']['Tools']:
            if item['Enabled']:
                copies.append((find_one(vendor, item['Path'], False), output / 'OC/Tools' / item['Path']))
        resource_trees = [p for p in vendor.rglob('Resources') if p.is_dir() and (p / 'Image').is_dir() and (p / 'Font').is_dir()]
        if len(resource_trees) != 1:
            raise ValueError(f'expected one OpenCanopy Resources tree, found {len(resource_trees)}')
        resources = resource_trees[0]
        copies.append((resources, output / 'OC/Resources'))
    except (ValueError, OSError, plistlib.InvalidFileException) as exc:
        ap.error(str(exc))
    # Only after all required inputs pass inspection, create the local output.
    shutil.copytree(ROOT / 'EFI', output)
    for source, target in copies:
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, target)
        else:
            shutil.copy2(source, target)
    for p in (ROOT / 'Overrides').rglob('*.plist'):
        target = output / 'OC/Kexts' / p.relative_to(ROOT / 'Overrides')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, target)
    for warning in warnings:
        print('REVIEW:', warning)
    print(f'Assembled local EFI: {output}')
    print('Set your own SMBIOS identity, run ocvalidate 1.0.8, then test from USB.')
    print('This has not installed the macOS-side NVIDIA runtime or bridge.')

if __name__ == '__main__':
    main()
