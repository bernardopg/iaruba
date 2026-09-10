#!/usr/bin/env sh
# scripts/dev-deploy-appimage.sh — replace a local dev AppImage atomically.
#
# Contexto: QUICKSTART.md #10 recomenda "usar o binario de release para um
# smoke test local" quando o bundling de AppImage falha no Arch atual. Na
# pratica isso significa copiar um AppImage recem-buildado por cima de
# ~/.local/bin/ioruba.AppImage repetidas vezes durante uma sessao de teste.
#
# Um `cp origem destino` comum trunca o arquivo de destino NO MESMO inode
# (O_WRONLY|O_TRUNC) quando o destino ja existe. Se uma instancia do Ioruba
# ainda estiver rodando a partir desse arquivo — FUSE-montado como AppImage
# em /tmp/.mount_ioruba* — o processo tem paginas mapeadas desse inode. A
# truncagem/reescrita por baixo do mmap gera SIGBUS (BUS_ADRERR) no processo
# vivo, e o systemd-coredump registra o crash mesmo sem culpa nenhuma do
# codigo do app. Foi exatamente essa correlacao (ioruba-desktop, WebKitWebProcess
# e WebKitNetworkProcess crashando aos pares logo apos um `cp` manual no dia do
# release 1.9.0) que motivou este script.
#
# `install`/`mv` sao seguros porque desvinculam o nome antigo e criam um
# arquivo NOVO (inode diferente) antes de renomear por cima — quem ja tem o
# arquivo antigo aberto/mapeado continua enxergando o conteudo antigo intacto
# ate soltar o fd. Este script formaliza esse padrao: copia para um arquivo
# temporario no MESMO diretorio do destino (garante que o `mv` final seja um
# rename atomico dentro do mesmo filesystem) e so entao promove por cima do
# destino existente.
#
# Uso: scripts/dev-deploy-appimage.sh <appimage-de-origem> [destino]
#   destino default: ~/.local/bin/ioruba.AppImage
set -eu

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SRC="${1:-}"
DEFAULT_DEST="${HOME}/.local/bin/ioruba.AppImage"
DEST="${2:-${DEFAULT_DEST}}"

if [ -z "$SRC" ]; then
    echo "Uso: $0 <appimage-de-origem> [destino]" >&2
    echo "  destino default: ${HOME}/.local/bin/ioruba.AppImage" >&2
    exit 1
fi

if [ ! -f "$SRC" ]; then
    echo "Arquivo de origem nao encontrado: $SRC" >&2
    exit 1
fi

DEST_DIR="$(dirname -- "$DEST")"
mkdir -p -- "$DEST_DIR"

# mktemp no MESMO diretorio do destino: garante que o `mv` final seja um
# rename() dentro do mesmo filesystem (atomico), nunca um copy-then-unlink
# entre filesystems diferentes.
TMP="$(mktemp -- "${DEST_DIR}/.ioruba-deploy.XXXXXX")"
trap 'rm -f -- "$TMP"' EXIT

cp -- "$SRC" "$TMP"
chmod 0755 -- "$TMP"

# Aviso best-effort: nao bloqueia o deploy (o mv abaixo e seguro mesmo com o
# processo antigo rodando), so avisa que a instancia velha so vera o binario
# novo apos ser fechada e reaberta.
if command -v pgrep >/dev/null 2>&1; then
    OLD_PIDS="$(pgrep -f "$(basename -- "$DEST")" 2>/dev/null || true)"
    if [ -n "$OLD_PIDS" ]; then
        echo "Aviso: instancia(s) rodando a partir de ${DEST} (PID(s): $(printf '%s' "$OLD_PIDS" | tr '\n' ' ' | sed 's/ *$//')). O rename e atomico e nao vai derruba-la(s), mas ela(s) so vera(o) o binario novo apos reiniciar." >&2
    fi
fi

mv -- "$TMP" "$DEST"
trap - EXIT

# O launcher do menu precisa passar pelo runtime de compatibilidade. Executar o
# AppImage diretamente deixa as libwayland/xcb antigas do linuxdeploy à frente
# do Mesa do host e, em Mesa 26+, o WebKit aborta com EGL_BAD_ALLOC: sobra uma
# janela cinza e nenhum hook React (inclusive o serial) chega a iniciar.
if [ "$DEST" = "$DEFAULT_DEST" ]; then
    COMPAT_DEST="${DEST_DIR}/ioruba-appimage-compat"
    LAUNCHER_DEST="${DEST_DIR}/ioruba-desktop"
    APPLICATIONS_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
    DESKTOP_DEST="${APPLICATIONS_DIR}/io.ioruba.desktop.desktop"

    install -m 0755 "${SCRIPT_DIR}/run-appimage-compat.sh" "$COMPAT_DEST"
    cat > "$LAUNCHER_DEST" <<EOF
#!/usr/bin/env sh
exec "${COMPAT_DEST}" "${DEST}" "\$@"
EOF
    chmod 0755 "$LAUNCHER_DEST"

    mkdir -p -- "$APPLICATIONS_DIR"
    cat > "$DESKTOP_DEST" <<EOF
[Desktop Entry]
Type=Application
Name=Ioruba
GenericName=Audio Mixer
GenericName[pt_BR]=Mixer de Áudio
Comment=Tactile audio mixer for Arduino-based Linux control
Comment[pt_BR]=Mixer de áudio tátil para controle via Arduino no Linux
Exec=${LAUNCHER_DEST}
Icon=ioruba
Terminal=false
Categories=AudioVideo;Audio;Mixer;
Keywords=audio;mixer;volume;arduino;serial;hardware;potentiometer;
StartupNotify=true
StartupWMClass=io.ioruba.desktop
EOF

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
    fi
fi

echo "Deploy atomico concluido: ${DEST}"
