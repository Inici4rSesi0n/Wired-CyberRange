#!/usr/bin/env bash
set -euo pipefail

read -p "Esto eliminará TODOS los contenedores y volúmenes. Continuar? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado."
    exit 0
fi

for c in inici4rsesi0n_wired dvwa juice-shop metasploitable samba; do
    podman stop "$c" 2>/dev/null && echo "    [OK] Detenido: $c" || true
    podman rm "$c" 2>/dev/null && echo "    [OK] Eliminado: $c" || true
done

podman network rm wired-net 2>/dev/null || true

echo ">>> Laboratorio reseteado"
