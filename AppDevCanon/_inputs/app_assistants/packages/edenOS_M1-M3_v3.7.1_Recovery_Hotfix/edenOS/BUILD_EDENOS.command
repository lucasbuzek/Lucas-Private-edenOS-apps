#!/bin/zsh
set -euo pipefail
export HOMEBREW_NO_AUTO_UPDATE=1
TITLE="edenOS M1-M3 v3.7.1 One-Click Build"
ROOT="$HOME/Downloads/edenOS"
HERE="${0:A:h}"
LOG="$ROOT/logs/m1-m3-v3.7.log"

# Ownership gate MUST run before opening the log or cleaning staging.
# BUILD_EDENOS.command never runs itself as root and never silently changes ownership.
[[ "$(id -u)" -ne 0 ]] || { print "ERROR: Do not run BUILD_EDENOS.command with sudo."; exit 10; }
mkdir -p "$ROOT" 2>/dev/null || { print "ERROR: Cannot create/access $ROOT"; print "Run: $HERE/REPAIR_WORKSPACE.command"; exit 11; }
for d in "$ROOT" "$ROOT/logs" "$ROOT/build"; do
  if [[ -e "$d" && ! -w "$d" ]]; then
    print "ERROR: edenOS workspace contains non-writable build state: $d"
    print "This is usually stale root-owned output from an earlier sudo build."
    print "Run once: $HERE/REPAIR_WORKSPACE.command"
    exit 12
  fi
done
mkdir -p "$ROOT"/{cache/alpine,source,build,images,releases,logs,config,tools} || {
  print "ERROR: Workspace is not writable. Run: $HERE/REPAIR_WORKSPACE.command"; exit 13;
}
# Catch root-owned files inside the two disposable/write-heavy locations before tee/rm fails.
BAD="$(find "$ROOT/logs" "$ROOT/build" ! -user "$USER" -print -quit 2>/dev/null || true)"
if [[ -n "$BAD" ]]; then
  print "ERROR: Non-user-owned edenOS build artifact detected: $BAD"
  print "Run once: $HERE/REPAIR_WORKSPACE.command"
  exit 14
fi
exec > >(tee -a "$LOG") 2>&1
printf "edenOS M1-M3 v3.7.1 One-Click\nLog: %s\n" "$LOG"
ALPINE_VER="3.24.2"
ALPINE_BASE="https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/aarch64"
ISO="alpine-virt-${ALPINE_VER}-aarch64.iso"
print "=== $TITLE ==="
[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || { print "ERROR: Apple Silicon macOS required."; exit 2; }

# Dependency policy: LOCAL -> CACHE -> NETWORK. Never query Homebrew for tools already on PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
missing=()
for x in qemu-system-aarch64 curl jq xz zstd; do
  command -v "$x" >/dev/null 2>&1 || missing+=("$x")
done
if (( ${#missing[@]} )); then
  print "Missing local tools: ${missing[*]}"
  if ! command -v brew >/dev/null 2>&1; then
    print "ERROR: Homebrew is required only because dependencies are missing."
    print "Install Homebrew, then rerun this builder."
    exit 3
  fi
  # Map executable names to Homebrew formulae; network is used only for genuinely missing tools.
  for x in ${missing[@]}; do
    case "$x" in
      qemu-system-aarch64) f=qemu ;;
      *) f="$x" ;;
    esac
    print "Installing missing dependency: $f"
    HOMEBREW_NO_AUTO_UPDATE=1 brew install "$f"
  done
fi

CACHE="$ROOT/cache/alpine"
# Always obtain the tiny official checksum first when absent; then validate any pre-existing ISO.
[[ -f "$CACHE/$ISO.sha256" ]] || curl --fail --location --continue-at - --retry 5 --retry-delay 3 --connect-timeout 20 --progress-bar "$ALPINE_BASE/$ISO.sha256" -o "$CACHE/$ISO.sha256"
if [[ -f "$CACHE/$ISO" ]]; then
  if (cd "$CACHE" && shasum -a 256 -c "$ISO.sha256"); then
    print "Verified cached Alpine media: $ISO"
  else
    print "Cached Alpine media failed verification; removing it before download."
    rm -f "$CACHE/$ISO"
  fi
fi
if [[ ! -f "$CACHE/$ISO" ]]; then
  curl --fail --location --continue-at - --retry 5 --retry-delay 3 --connect-timeout 20 --progress-bar "$ALPINE_BASE/$ISO" -o "$CACHE/$ISO.part"
  mv "$CACHE/$ISO.part" "$CACHE/$ISO"
fi
(cd "$CACHE" && shasum -a 256 -c "$ISO.sha256")

OVL="$ROOT/build/m1m3-apkovl"; rm -rf "$OVL"
mkdir -p "$OVL"/{etc/apk,etc/local.d,etc/runlevels/default,etc/xdg/weston,etc/edenos,usr/local/bin,opt/edenos/shell,opt/edenos/platform,home/eden}
cp -R "$HERE/shell/." "$OVL/opt/edenos/shell/"
cp -R "$HERE/platform/." "$OVL/opt/edenos/platform/"
cat > "$OVL/etc/hostname" <<'EOF'
edenos
EOF
cat > "$OVL/etc/apk/repositories" <<'EOF'
https://dl-cdn.alpinelinux.org/alpine/v3.24/main
https://dl-cdn.alpinelinux.org/alpine/v3.24/community
EOF
ln -sf /etc/init.d/local "$OVL/etc/runlevels/default/local"
cat > "$OVL/etc/edenos/release" <<'EOF'
edenOS M1-M3 v3.7.1
EDEN — Engineering, Development, Exploration & Nature
Profile: FULL development
Recovery login: eden / eden
EOF

cat > "$OVL/usr/local/bin/eden-diagnostics" <<'EOF'
#!/bin/sh
echo "edenOS M1-M3 diagnostics"
echo "release:"; cat /etc/edenos/release 2>/dev/null || true
echo "overlay: $(test -f /etc/edenos/release && echo PASS || echo FAIL)"
echo "network:"; ip -br link 2>/dev/null || true
echo "memory:"; free -m 2>/dev/null || true
echo "storage:"; df -h 2>/dev/null || true
echo "weston:"; test -f /tmp/weston.log && tail -40 /tmp/weston.log || echo "not started"
EOF
chmod +x "$OVL/usr/local/bin/eden-diagnostics"

cat > "$OVL/etc/xdg/weston/weston.ini" <<'EOF'
[core]
shell=desktop-shell.so
idle-time=0
xwayland=true
[shell]
background-color=0xff173d46
panel-position=none
locking=false
EOF

cat > "$OVL/etc/local.d/eden.start" <<'EOF'
#!/bin/sh
exec >/var/log/eden-bootstrap.log 2>&1
echo "EDEN_OVERLAY_OK"
ip link set eth0 up 2>/dev/null || true
udhcpc -i eth0 -q -n -t 10 || true
apk update || true
# FULL candidate. Chromium is deliberately test-removable; platform does not depend on it.
apk add --no-cache eudev seatd seatd-launch weston weston-backend-drm weston-shell-desktop weston-xwayland mesa-dri-gallium mesa-egl mesa-gbm chromium font-noto || \
apk add --no-cache eudev seatd seatd-launch weston weston-backend-drm weston-shell-desktop mesa-dri-gallium mesa-egl mesa-gbm font-noto
rc-service udev start 2>/dev/null || true
rc-service seatd start 2>/dev/null || true
id eden >/dev/null 2>&1 || adduser -D -s /bin/sh eden
echo 'eden:eden' | chpasswd
addgroup eden video 2>/dev/null || true
addgroup eden input 2>/dev/null || true
UIDE="$(id -u eden)"; mkdir -p "/run/user/$UIDE"; chown eden:eden "/run/user/$UIDE"; chmod 700 "/run/user/$UIDE"
chown -R eden:eden /home/eden
(
 sleep 2
 su eden -c "export XDG_RUNTIME_DIR=/run/user/$UIDE; export LIBSEAT_BACKEND=seatd; weston --backend=drm-backend.so --config=/etc/xdg/weston/weston.ini --log=/tmp/weston.log" &
 sleep 5
 if command -v chromium >/dev/null 2>&1; then
   su eden -c "export XDG_RUNTIME_DIR=/run/user/$UIDE; export WAYLAND_DISPLAY=wayland-1; chromium --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --start-fullscreen file:///opt/edenos/shell/index.html" &
 fi
) &
EOF
chmod +x "$OVL/etc/local.d/eden.start"

# overlay archive
( cd "$OVL" && COPYFILE_DISABLE=1 tar --format=ustar -czf "$ROOT/build/edenos.apkovl.tar.gz" . )

# Alpine diskless discovery is explicitly tested. Supply both canonical host and generic names.
CFG="$ROOT/images/edenOS-M1-M3-config.img"; rm -f "$CFG" "$CFG.dmg"
hdiutil create -quiet -size 64m -fs MS-DOS -volname EDENCFG -layout NONE -format UDRW "$CFG.dmg"
MNT="$ROOT/build/cfgmnt"; mkdir -p "$MNT"; hdiutil attach -quiet -nobrowse -mountpoint "$MNT" "$CFG.dmg"
cp "$ROOT/build/edenos.apkovl.tar.gz" "$MNT/edenos.apkovl.tar.gz"
cp "$ROOT/build/edenos.apkovl.tar.gz" "$MNT/localhost.apkovl.tar.gz"
sync; hdiutil detach -quiet "$MNT"; mv "$CFG.dmg" "$CFG"

cat > "$ROOT/config/m1m3.env" <<EOF
EDEN_VERSION=M1-M3-v3.7.1-testing
EDEN_ARCH=aarch64
EDEN_MACHINE=virt
EDEN_ACCEL=hvf
EDEN_CPUS=2
EDEN_RAM_MB=1024
ALPINE_VERSION=$ALPINE_VER
EOF

cat > "$ROOT/tools/run-edenos.command" <<'EOF'
#!/bin/zsh
set -euo pipefail
ROOT="$HOME/Downloads/edenOS"; source "$ROOT/config/m1m3.env"
ISO="$ROOT/cache/alpine/alpine-virt-${ALPINE_VERSION}-aarch64.iso"; CFG="$ROOT/images/edenOS-M1-M3-config.img"
QEMU_BIN="$(command -v qemu-system-aarch64)"
QEMU_PREFIX="$(cd "$(dirname "$QEMU_BIN")/.." && pwd)"
FW="$QEMU_PREFIX/share/qemu/edk2-aarch64-code.fd"
[[ -f "$FW" ]] || FW="$(find "$QEMU_PREFIX/share" -name edk2-aarch64-code.fd -print -quit 2>/dev/null)"
[[ -n "$FW" && -f "$FW" ]] || { print "ERROR: QEMU ARM64 UEFI firmware not found under $QEMU_PREFIX/share"; exit 4; }
exec "$QEMU_BIN" -machine virt,accel=hvf -cpu host -smp "$EDEN_CPUS" -m "$EDEN_RAM_MB" -bios "$FW" \
-drive "if=none,file=$CFG,format=raw,readonly=on,id=cfg" -device virtio-blk-pci,drive=cfg \
-drive "if=none,file=$ISO,format=raw,readonly=on,id=iso" -device virtio-blk-pci,drive=iso \
-device virtio-net-pci,netdev=n0 -netdev user,id=n0 -device virtio-gpu-pci \
-device qemu-xhci -device usb-kbd -device usb-tablet -display cocoa -serial mon:stdio
EOF
chmod +x "$ROOT/tools/run-edenos.command"
ln -sf "$ROOT/tools/run-edenos.command" "$ROOT/Run edenOS.command"

cat > "$ROOT/tools/test-edenos.command" <<'EOF'
#!/bin/zsh
set -u
ROOT="$HOME/Downloads/edenOS"; FAIL=0
pass(){ print "PASS  $1"; }; fail(){ print "FAIL  $1"; FAIL=1; }
[[ -f "$ROOT/config/m1m3.env" ]] && pass "configuration" || fail "configuration"
[[ -f "$ROOT/images/edenOS-M1-M3-config.img" ]] && pass "config media" || fail "config media"
[[ -f "$ROOT/build/edenos.apkovl.tar.gz" ]] && pass "overlay archive" || fail "overlay archive"
tar -tzf "$ROOT/build/edenos.apkovl.tar.gz" | grep -q './etc/edenos/release' && pass "overlay marker" || fail "overlay marker"
tar -tzf "$ROOT/build/edenos.apkovl.tar.gz" | grep -q './opt/edenos/shell/index.html' && pass "edenShell payload" || fail "edenShell payload"
tar -tzf "$ROOT/build/edenos.apkovl.tar.gz" | grep -q './opt/edenos/platform/app-registry.json' && pass "app registry" || fail "app registry"
print ""
print "Runtime gates to verify after VM boot:"
print "  1 EDEN_OVERLAY_OK appears in /var/log/eden-bootstrap.log"
print "  2 user eden exists and eden/eden works in recovery console"
print "  3 Weston starts"
print "  4 edenShell fills the display"
print "  5 Files + all application surfaces open"
print "  6 headless services remain independent of GUI"
print "  7 record idle RAM and installed bytes"
exit $FAIL
EOF
chmod +x "$ROOT/tools/test-edenos.command"
ln -sf "$ROOT/tools/test-edenos.command" "$ROOT/Test edenOS.command"

print "Static package preflight..."
"$HERE/tests/static-preflight.sh"
"$ROOT/tools/test-edenos.command"
print "Build complete. Launch: $ROOT/Run edenOS.command"
open "$ROOT"
