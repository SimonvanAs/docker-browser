FROM alpine:3.21

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
    && adduser -D browser

COPY start.sh /start.sh
RUN chmod +x /start.sh
COPY index.html /usr/share/novnc/index.html
COPY openbox-rc.xml /etc/xdg/openbox/rc.xml

RUN mkdir -p /var/run/dbus && chmod 755 /var/run/dbus

USER browser
EXPOSE 6080

CMD ["/start.sh"]
