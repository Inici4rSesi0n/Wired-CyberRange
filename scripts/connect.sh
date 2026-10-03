#!/usr/bin/env bash
set -euo pipefail

if ! podman ps --format "{{.Names}}" | grep -q "^inici4rsesi0n_wired$"; then
    echo "[FALLA] Contenedor 'inici4rsesi0n_wired' no está corriendo."
    echo "        Levántalo con: make up-web"
    exit 1
fi

echo ">>> Conectando al atacante..."
podman exec -it inici4rsesi0n_wired /bin/bash || true
