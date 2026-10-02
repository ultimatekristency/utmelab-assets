#!/usr/bin/env bash
# UTME Lab one-line installer (Linux).
#
#   curl -fsSL https://assets.utmelab.com/downloads/install.sh | bash
#
# Resolves the CURRENT release from latest.json (no version is hardcoded
# here, so this script never goes stale), verifies every download against
# SHA256SUMS, then installs via the native path: .deb on apt systems, .rpm
# on dnf systems, AppImage fallback everywhere else. Needs no arguments.
# Override the shelf (tests, mirrors) with UTMELAB_BASE_URL.

set -euo pipefail

BASE_URL="${UTMELAB_BASE_URL:-https://assets.utmelab.com/downloads}"
WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "error: required command '$1' not found" >&2
        exit 1
    }
}
need curl
need sha256sum
need awk
need uname
need mktemp

OS="$(uname -s)"
ARCH="$(uname -m)"
if [ "$OS" = "Darwin" ]; then
    echo "UTME Lab for macOS is coming soon - nothing installed." >&2
    exit 1
fi
if [ "$OS" != "Linux" ]; then
    echo "error: unsupported OS: $OS (Linux x86_64 only for now)" >&2
    exit 1
fi
if [ "$ARCH" != "x86_64" ]; then
    echo "error: unsupported architecture: $ARCH (x86_64 only for now)" >&2
    exit 1
fi

echo "fetching release info ..."
curl -fsSL "$BASE_URL/latest.json" -o "$WORK/latest.json"
curl -fsSL "$BASE_URL/SHA256SUMS" -o "$WORK/SHA256SUMS"

# Manifest values are absolute URLs (or null when a format is unpublished).
json_url() {
    grep -o "\"$1\": *\"[^\"]*\"" "$WORK/latest.json" | cut -d'"' -f4
}

fetch_verified() { # $1 = url, $2 = filename
    local url="$1" name="$2"
    echo "downloading $name ..."
    curl -fsSL "$url" -o "$WORK/$name"
    awk -v n="$name" '$2 == n' "$WORK/SHA256SUMS" | (
        cd "$WORK" && sha256sum -c -
    ) || {
        echo "error: checksum mismatch for $name - download corrupted, aborting" >&2
        exit 1
    }
}

DEB_URL="$(json_url linux_deb_url || true)"
RPM_URL="$(json_url linux_rpm_url || true)"
APPIMAGE_URL="$(json_url linux_appimage_url || true)"

if command -v apt-get >/dev/null 2>&1 && [ -n "$DEB_URL" ]; then
    NAME="${DEB_URL##*/}"
    fetch_verified "$DEB_URL" "$NAME"
    echo "installing $NAME ..."
    if [ "$(id -u)" = "0" ]; then
        apt-get install -y "$WORK/$NAME"
    elif command -v sudo >/dev/null 2>&1; then
        sudo apt-get install -y "$WORK/$NAME"
    else
        echo "error: need root for apt install (run as root or install sudo)" >&2
        exit 1
    fi
elif command -v dnf >/dev/null 2>&1 && [ -n "$RPM_URL" ]; then
    NAME="${RPM_URL##*/}"
    fetch_verified "$RPM_URL" "$NAME"
    echo "installing $NAME ..."
    if [ "$(id -u)" = "0" ]; then
        dnf install -y "$WORK/$NAME"
    elif command -v sudo >/dev/null 2>&1; then
        sudo dnf install -y "$WORK/$NAME"
    else
        echo "error: need root for dnf install (run as root or install sudo)" >&2
        exit 1
    fi
elif [ -n "$APPIMAGE_URL" ]; then
    NAME="${APPIMAGE_URL##*/}"
    fetch_verified "$APPIMAGE_URL" "$NAME"
    BIN_DIR="$HOME/.local/bin"
    APP_DIR="$HOME/.local/share/applications"
    mkdir -p "$BIN_DIR" "$APP_DIR"
    install -m 0755 "$WORK/$NAME" "$BIN_DIR/utmelab"
    cat > "$APP_DIR/utmelab.desktop" <<EOF
[Desktop Entry]
Name=UTME Lab
Comment=JAMB CBT Simulator
Exec=$BIN_DIR/utmelab
Type=Application
Categories=Education;
Terminal=false
EOF
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) echo "note: $BIN_DIR is not on PATH - add it or run $BIN_DIR/utmelab directly" ;;
    esac
else
    echo "error: no Linux artifact published in the current release" >&2
    exit 1
fi

echo "UTME Lab installed."
