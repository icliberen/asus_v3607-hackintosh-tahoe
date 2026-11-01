#!/bin/bash
# Written by the NVIDIA driver install: the desktop came up, so this start counts as good.
PATH=/usr/bin:/bin:/usr/sbin:/sbin
V=7C436110-AB2A-4BBB-A880-FE41995C9F82; LOG=/Library/NullMoth/bootguard.log
n=0
while [ "$n" -lt 48 ]; do
  if pgrep -x WindowServer >/dev/null 2>&1; then
    sleep 45
    pgrep -x WindowServer >/dev/null 2>&1 || { n=$((n + 1)); continue; }
    nvram -d $V:nullmoth-nv-starts 2>/dev/null
    nvram $V:nullmoth-nv-ok=1 2>/dev/null
    echo "$(date) the desktop came up and stayed up; this start counts as good" >> $LOG
    exit 0
  fi
  n=$((n + 1)); sleep 5
done
echo "$(date) no desktop within four minutes; the start keeps its count" >> $LOG
