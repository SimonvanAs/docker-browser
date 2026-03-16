#!/bin/sh

# Start virtual framebuffer
Xvfb :0 -screen 0 1280x720x24 &
sleep 1

export DISPLAY=:0

# Start dbus if possible
if [ -w /var/run/dbus ] || mkdir -p /var/run/dbus 2>/dev/null; then
  dbus-daemon --system --nofork 2>/dev/null &
  sleep 0.5
fi

# Start window manager
openbox &

# Start Chromium
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

# Start VNC server
x11vnc -display :0 -forever -nopw -shared -rfbport 5900 &

# Start noVNC with auto-connect and scaling
websockify --web /usr/share/novnc 6080 localhost:5900
