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
    && adduser -D browser

COPY start.sh /start.sh
RUN chmod +x /start.sh

USER browser
EXPOSE 6080

CMD ["/start.sh"]
