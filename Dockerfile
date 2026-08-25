FROM alpine:3.23

RUN apk add --no-cache \
    chromium \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    openbox \
    font-noto \
    dbus \
    ttf-freefont \
    mesa-dri-gallium \
    tini \
    && adduser -D browser

COPY start.sh /start.sh
RUN chmod +x /start.sh
COPY index.html /usr/share/novnc/index.html
COPY openbox-rc.xml /etc/xdg/openbox/rc.xml

RUN mkdir -p /var/run/dbus && chmod 755 /var/run/dbus

USER browser
EXPOSE 6080

# Unhealthy when noVNC stops answering or Chromium is gone; pairs with the
# supervisor in start.sh which exits the container when critical services die.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:6080/ && pgrep chromium >/dev/null || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
