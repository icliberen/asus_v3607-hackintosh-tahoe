#!/bin/bash
# auto.sh: liga sozinho, a cada boot, o desktop acelerado (RTX compõe, NMIntelFB mostra no painel) — o que enable.sh +
# killall faziam à mão (RTX-15). Roda como LaunchDaemon: espera o NMIntelFB e roda enable.sh; o WindowServer adota a
# RTX sozinho (RTX-16). Só se nenhum quadro chegar em 90 s na tela de login ele reinicia o WindowServer.
#   sudo bash tools/intelfb/auto.sh install    instala (vale no próximo boot)
#   sudo bash tools/intelfb/auto.sh remove     remove
#   sudo nvram nullmoth-intelfb-auto=0          desliga sem remover (apagar a variável religa)
#   sudo nvram nullmoth-accel-fast=0            liga o desktop mas sem a cópia rápida do RTX-18
#   sudo nvram nullmoth-accel-ram=0             mantém a cópia rápida mas sem a tela na RAM do RTX-20
#   sudo nvram nullmoth-accel-ram=1             tela na RAM com um buffer só, sem o flip do RTX-23 (padrão: 2)
# Log: /usr/bin/log show --last boot --predicate 'process == "logger"' (the tag is not part of eventMessage)
LABEL=com.nmxintel.intelfb-auto
BIN=/usr/local/libexec/nmx-intelfb-auto.sh
EN=/usr/local/libexec/nmx-intelfb-enable.sh
PL=/Library/LaunchDaemons/$LABEL.plist
[ "${1:-run}" = ready ] || [ "$(id -u)" = 0 ] || { echo "rode com sudo"; exit 1; }
say() { logger -t nmx-intelfb-auto "$*"; echo "$*"; }

# ASUS: read-only readiness checks replace the unconditional 15-second margin.
# NMIntelFB still retains its upstream 45-second handoff guard.
bridge_ready() {
    local nvrm
    ioreg -r -c NMIntelFB -d1 -l -w0 2>/dev/null | grep -q '"NVRMTiming"' || return 1
    sysctl -n debug.nmintelfb_agdc >/dev/null 2>&1 || return 1
    nvrm=$(ioreg -r -c NVRM -d1 -l -w0 2>/dev/null) || return 1
    echo "$nvrm" | grep -q '"nvrm-autogo" = "up"' || return 1
    echo "$nvrm" | grep -Eq '"nvrm-boot-hold" = "display (PARTIAL|armed)"' || return 1
    ioreg -r -c NVAccel -d1 -w0 2>/dev/null | grep -q '+-o NVAccel' || return 1
}

# ASUS: retain the upstream two-minute guard while running. On an orderly stop,
# disarm only when this boot has actually copied frames onto the Intel panel.
# A freeze or panic cannot run the TERM handler, so its guard remains armed.
verified_panel_frames() {
    local frames failures
    [ "$(sysctl -n debug.nmintelfb_agdc 2>/dev/null)" = 1 ] || return 1
    [ "$(sysctl -n debug.nvaccel_iop 2>/dev/null)" = 1 ] || return 1
    frames=$(sysctl -n debug.nvaccel_iop_ok 2>/dev/null) || return 1
    failures=$(sysctl -n debug.nvaccel_iop_fail 2>/dev/null) || return 1
    case "$frames" in ''|*[!0-9]*) return 1;; esac
    [ "$frames" -gt 0 ] && [ "$failures" = 0 ] || return 1
    ioreg -r -c NMIntelFB -d1 -l -w0 2>/dev/null | grep -q '"NVRMTiming"'
}
clean_stop() {
    trap '' TERM INT
    if verified_panel_frames && nvram nullmoth-intelfb-attaching >/dev/null 2>&1; then
        if nvram -d nullmoth-intelfb-attaching; then
            say "ASUS: verified panel frames; cleared pending guard during orderly stop"
        fi
    fi
    exit 0
}
wait_for_guard_completion() {
    # Stay available for TERM only until the kernel's original guard expires.
    # No synthetic success marker is written on startup or on a missing panel.
    verified_panel_frames || return 0
    for i in $(seq 1 130); do
        nvram nullmoth-intelfb-attaching >/dev/null 2>&1 || return 0
        sleep 1 &
        wait $!
    done
}

case "${1:-run}" in
ready)
    bridge_ready
    ;;
install)
    cd "$(dirname "$0")" || exit 1
    bash -n enable.sh || exit 1
    mkdir -p /usr/local/libexec
    cp auto.sh "$BIN" && cp enable.sh "$EN" || exit 1   # after the cd: $0 may be relative to where it was run
    chown root:wheel "$BIN" "$EN" && chmod 755 "$BIN" "$EN"
    cat > "$PL" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>$BIN</string>
		<string>run</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF
    chown root:wheel "$PL" && chmod 644 "$PL"
    echo "instalado: $BIN e $PL (vale a partir do próximo boot)"
    ;;
remove)
    launchctl bootout system "$PL" 2>/dev/null
    rm -f "$PL" "$BIN" "$EN"
    echo "removido"
    ;;
run)
    trap clean_stop TERM INT
    [ "$(nvram nullmoth-intelfb-auto 2>/dev/null | awk '{print $2}')" = 0 ] && { say "off (nullmoth-intelfb-auto=0)"; exit 0; }
    # NMIntelFB takes the panel nullmoth-intelfb-delay seconds after start, under NVRM; give it up to 5 minutes
    for i in $(seq 1 150); do
        ioreg -r -c NMIntelFB -d1 2>/dev/null | grep -q NMIntelFB && sysctl -n debug.nmintelfb_agdc >/dev/null 2>&1 && break
        sleep 2
    done
    ioreg -r -c NMIntelFB -d1 2>/dev/null | grep -q NMIntelFB || { say "no NMIntelFB this boot; nothing done"; exit 0; }
    [ "$(sysctl -n debug.nvaccel_iop 2>/dev/null)" = 1 ] && { say "already on"; wait_for_guard_completion; exit 0; }
    # Wait only while the actual driver state is incomplete; no fixed post-panel sleep.
    ready=0
    for i in $(seq 1 30); do
        if bridge_ready; then ready=1; break; fi
        sleep 1
    done
    [ "$ready" = 1 ] || { say "ASUS: bridge not ready after 30 s; WindowServer left alone"; exit 1; }
    say "ASUS: bridge ready; enabling without the old fixed 15 s margin"
    ok=0
    for i in 1 2 3; do bash "$EN" >/dev/null 2>&1 && { ok=1; break; }; sleep 10; done
    [ $ok = 1 ] || { say "enable.sh failed 3 times; WindowServer left alone"; exit 1; }
    say "enabled: agdc $(sysctl -n debug.nmintelfb_agdc) iop $(sysctl -n debug.nvaccel_iop)"
    # ASUS initial profile: retain the firmware scanout and stock NVAccel copy path.
    # RAM remapping and optional fast-copy tuning are deliberately inactive.
    # RTX-16: the running WindowServer took the accelerated panel by itself ~45 s after enabling (no restart). Restart
    # it only if no frame arrived in 90 s and nobody is logged in yet (the login window's console owner is
    # _windowserver, or root early on).
    for i in $(seq 1 45); do [ "$(sysctl -n debug.nvaccel_iop_ok)" != 0 ] && break; sleep 2; done
    owner=$(stat -f %Su /dev/console)
    if [ "$(sysctl -n debug.nvaccel_iop_ok)" != 0 ]; then
        say "frames reach the panel (iop_ok $(sysctl -n debug.nvaccel_iop_ok)); no restart"
    elif [ "$owner" = root ] || [ "$owner" = _windowserver ]; then
        say "no frame after 90 s at the login window: restarting WindowServer onto the RTX"
        killall -9 WindowServer
    else
        say "no frame after 90 s and $owner is logged in: accelerated after the next WindowServer restart"
    fi
    wait_for_guard_completion
    ;;
*) echo "uso: auto.sh install|remove"; exit 1 ;;
esac
