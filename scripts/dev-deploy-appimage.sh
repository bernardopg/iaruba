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

SRC="${1:-}"
DEST="${2:-${HOME}/.local/bin/ioruba.AppImage}"

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

echo "Deploy atomico concluido: ${DEST}"
