#!/bin/sh
# Supervised startup.
# - Critical plumbing (Xvfb, x11vnc, websockify) exits the container on death so
#   Docker's restart policy brings everything back in a known-good state.
# - Chromium is respawned in place so the noVNC session survives browser crashes;
#   a crash loop (>5 respawns in 5 min) escalates to a container restart.

set -u

log() { echo "[supervisor] $*"; }

# Return success while PID is alive and not a zombie.
alive() {
  state=$(sed 's/.*) //' "/proc/$1/stat" 2>/dev/null | cut -d" " -f1)
  [ -n "$state" ] && [ "$state" != "Z" ]
}

Xvfb :0 -screen 0 1280x720x24 &
XVFB_PID=$!

# Wait for the X socket instead of sleeping blind.
i=0
while [ ! -e /tmp/.X11-unix/X0 ]; do
  i=$((i + 1))
  [ "$i" -gt 50 ] && { log "Xvfb failed to create display :0"; exit 1; }
  sleep 0.1
done

export DISPLAY=:0

# Start dbus if possible
if [ -w /var/run/dbus ] || mkdir -p /var/run/dbus 2>/dev/null; then
  dbus-daemon --system --nofork 2>/dev/null &
  sleep 0.5
fi

# Start window manager
openbox &

start_chromium() {
  GALLIUM_DRIVER=llvmpipe chromium-browser \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-gpu-compositing \
    --ozone-platform=x11 \
    --no-first-run \
    --disable-sync \
    --disable-infobars \
    --start-maximized \
    --window-size=1280,720 &
  CHROMIUM_PID=$!
}
start_chromium

# Start VNC server
x11vnc -display :0 -forever -nopw -shared -rfbport 5900 &
VNC_PID=$!

# Start noVNC with auto-connect and scaling
websockify --web /usr/share/novnc 6080 localhost:5900 &
WS_PID=$!

RESPAWNS=0
LAST_RESPAWN=$(date +%s)

while :; do
  sleep 5
  alive "$XVFB_PID" || { log "Xvfb died; exiting for container restart"; exit 1; }
  alive "$VNC_PID" || { log "x11vnc died; exiting for container restart"; exit 1; }
  alive "$WS_PID" || { log "websockify died; exiting for container restart"; exit 1; }
  if ! alive "$CHROMIUM_PID"; then
    wait "$CHROMIUM_PID" 2>/dev/null # reap
    now=$(date +%s)
    [ $((now - LAST_RESPAWN)) -gt 300 ] && RESPAWNS=0
    RESPAWNS=$((RESPAWNS + 1))
    LAST_RESPAWN=$now
    if [ "$RESPAWNS" -gt 5 ]; then
      log "Chromium crash-looping (>5 in 5 min); exiting for container restart"
      exit 1
    fi
    log "Chromium died; respawning in place ($RESPAWNS)"
    start_chromium
  fi
done
