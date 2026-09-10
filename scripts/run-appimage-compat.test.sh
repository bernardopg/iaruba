#!/usr/bin/env bash
# Regression tests for the AppImage/Mesa compatibility launcher.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPAT_SH="${SCRIPT_DIR}/run-appimage-compat.sh"
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf -- "$TMPDIR_TEST"' EXIT

failures=0
checks=0
check() {
    local label="$1" expected="$2" actual="$3"
    checks=$((checks + 1))
    if [ "$expected" = "$actual" ]; then
        printf '  ok   %s\n' "$label"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' \
            "$label" "$expected" "$actual"
        failures=$((failures + 1))
    fi
}

fake_appimage="${TMPDIR_TEST}/Ioruba.AppImage"
cat > "$fake_appimage" <<'APPIMAGE'
#!/usr/bin/env sh
set -eu
[ "${1:-}" = "--appimage-extract" ] || exit 2
mkdir -p squashfs-root/usr/lib/x86_64-linux-gnu
cat > squashfs-root/AppRun <<'APPRUN'
#!/usr/bin/env sh
set -eu
APPDIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
export APPDIR
for library in \
    libwayland-client.so.0 libwayland-cursor.so.0 libwayland-egl.so.1 \
    libwayland-server.so.0 libxkbcommon.so.0 libxcb-randr.so.0 \
    libxcb-render.so.0 libxcb-shm.so.0 libXau.so.6 libXdmcp.so.6
do
    if find "${APPDIR}/usr/lib" \( -type f -o -type l \) -name "$library" | grep -q .; then
        echo "bundled:$library"
        exit 3
    fi
done
printf 'launched:%s\n' "${1:-}"
APPRUN
chmod +x squashfs-root/AppRun
for directory in squashfs-root/usr/lib squashfs-root/usr/lib/x86_64-linux-gnu; do
    for library in \
        libwayland-client.so.0 libwayland-cursor.so.0 libwayland-egl.so.1 \
        libwayland-server.so.0 libxkbcommon.so.0 libxcb-randr.so.0 \
        libxcb-render.so.0 libxcb-shm.so.0 libXau.so.6 libXdmcp.so.6
    do
        : > "${directory}/${library}"
    done
done
APPIMAGE
chmod +x "$fake_appimage"

export XDG_CACHE_HOME="${TMPDIR_TEST}/cache"
first_output="$(sh "$COMPAT_SH" "$fake_appimage" first)"
check "remove todo o ABI grafico empacotado antes de iniciar" "launched:first" "$first_output"

# Reintroduce one stale library into the already-extracted cache.  The wrapper
# must repair old caches instead of only cleaning immediately after extraction.
runtime_dir="$(find "$XDG_CACHE_HOME/ioruba/appimage-runtime" -mindepth 1 -maxdepth 1 -type d -print -quit)"
: > "${runtime_dir}/squashfs-root/usr/lib/libxkbcommon.so.0"
second_output="$(sh "$COMPAT_SH" "$fake_appimage" second)"
check "repara cache criado por wrapper antigo" "launched:second" "$second_output"
check "biblioteca obsoleta foi removida do cache" "no" \
    "$([ -e "${runtime_dir}/squashfs-root/usr/lib/libxkbcommon.so.0" ] && echo yes || echo no)"

printf '\n%d checks, %d failures\n' "$checks" "$failures"
exit "$((failures > 0 ? 1 : 0))"
