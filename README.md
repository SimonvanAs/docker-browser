# Docker Browser

A Docker container that runs Chromium in a virtual display, accessible through your web browser via noVNC.

## Quick Start

### Using Docker Compose

```bash
docker compose up -d
```

### Using Docker directly

```bash
docker build -t docker-browser .
docker run -p 6080:6080 docker-browser
```

### Using the pre-built image

```bash
docker run -p 6080:6080 slompies/docker-browser:latest
```

Open http://localhost:6080/vnc.html to access the browser.

## How It Works

- **Xvfb** provides a virtual framebuffer (1920x1080)
- **Openbox** runs as a minimal window manager
- **Chromium** launches maximized in the virtual display
- **x11vnc** exposes the display over VNC
- **noVNC + websockify** bridges VNC to a WebSocket on port 6080

## Configuration

The container exposes port **6080** (noVNC web interface). The VNC server runs without a password by default.

Built on Alpine 3.21 and runs as a non-root `browser` user.
