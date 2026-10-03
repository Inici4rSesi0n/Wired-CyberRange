#!/usr/bin/env bash
set -euo pipefail

echo ">>> Deteniendo contenedores..."
for c in inici4rsesi0n_wired dvwa juice-shop metasploitable samba; do
    if podman container exists "$c" 2>/dev/null; then
        podman stop "$c" 2>/dev/null && echo "    [OK] Detenido: $c" || true
        podman rm "$c" 2>/dev/null && echo "    [OK] Eliminado: $c" || true
    fi
done
echo ">>> Listo"
