#!/usr/bin/env bash
# Tests for scripts/dev-deploy-appimage.sh.
#
# A regular `cp src dest` truncates the destination in place (same inode),
# which is exactly the bug that produced the ioruba-desktop/WebKitWebProcess
# SIGBUS crash burst on 2026-09-08: a running instance had the old AppImage
# mmap'd, and rewriting it under the mmap corrupted the mapping. These tests
# assert the replacement is a rename (new inode), so a reader that opened the
# destination before the deploy keeps seeing the old, complete content.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/dev-deploy-appimage.sh"

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

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf -- "$TMPDIR_TEST"' EXIT

# ── Caso 1: substituir um destino existente preserva o inode antigo para quem
# ja tinha o fd aberto (a garantia central do script). ─────────────────────
src1="${TMPDIR_TEST}/new-build.AppImage"
dest1="${TMPDIR_TEST}/ioruba.AppImage"
printf 'conteudo-antigo' > "$dest1"
printf 'conteudo-novo' > "$src1"

# Abre um fd de leitura no destino ANTES do deploy, como um processo que ja
# tem o AppImage mmap'd/FUSE-montado continuaria tendo.
exec 9< "$dest1"
inode_before="$(stat -c %i "$dest1")"

bash "$DEPLOY_SH" "$src1" "$dest1" >/dev/null

inode_after="$(stat -c %i "$dest1")"
content_via_old_fd="$(cat <&9)"
exec 9<&-
content_new_path="$(cat "$dest1")"

check "inode muda (rename, nao truncagem in-place)" "1" "$([ "$inode_before" != "$inode_after" ] && echo 1 || echo 0)"
check "fd aberto antes do deploy ainda le o conteudo antigo intacto" "conteudo-antigo" "$content_via_old_fd"
check "o caminho do destino agora aponta pro conteudo novo" "conteudo-novo" "$content_new_path"

# ── Caso 2: destino novo (sem arquivo previo) e criado normalmente ────────
src2="${TMPDIR_TEST}/new-build-2.AppImage"
dest2="${TMPDIR_TEST}/subdir/ioruba.AppImage"
printf 'primeiro-deploy' > "$src2"
bash "$DEPLOY_SH" "$src2" "$dest2" >/dev/null
check "cria diretorio de destino e o arquivo quando nao existiam" "primeiro-deploy" "$(cat "$dest2" 2>/dev/null)"

# ── Caso 3: permissao executavel e aplicada ao destino ────────────────────
check "destino fica executavel" "1" "$([ -x "$dest2" ] && echo 1 || echo 0)"

# ── Caso 4: origem inexistente falha sem tocar o destino ──────────────────
dest4="${TMPDIR_TEST}/ioruba.AppImage"
before_dest4="$(cat "$dest4")"
if bash "$DEPLOY_SH" "${TMPDIR_TEST}/nao-existe.AppImage" "$dest4" >/dev/null 2>&1; then
    rc4=0
else
    rc4=$?
fi
check "origem inexistente retorna erro" "1" "$([ "$rc4" -ne 0 ] && echo 1 || echo 0)"
check "destino permanece intocado quando a origem nao existe" "$before_dest4" "$(cat "$dest4")"

# ── Caso 5: sem argumentos falha com uso ───────────────────────────────────
if bash "$DEPLOY_SH" >/dev/null 2>&1; then
    rc5=0
else
    rc5=$?
fi
check "sem argumentos retorna erro" "1" "$([ "$rc5" -ne 0 ] && echo 1 || echo 0)"

printf '\n%d checks, %d failures\n' "$checks" "$failures"
exit "$((failures > 0 ? 1 : 0))"
