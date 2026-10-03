#!/usr/bin/env bash
# =============================================================================
# scripts/up.sh - Levantar perfil del laboratorio
# Uso: ./up.sh [recon|web|smb|full]
# =============================================================================

set -euo pipefail

PROFILE="${1:-web}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Verificar que el perfil existe
if [[ ! -f "compose/podman-compose.${PROFILE}.yml" ]]; then
    echo "[FALLA] Perfil no encontrado: $PROFILE"
    echo "        Perfiles disponibles: recon, web, smb, full"
    exit 1
fi

if ! podman network exists wired-net 2>/dev/null; then
    echo "[FALLA] La red 'wired-net' no existe."
    echo "        Ejecuta primero: make setup"
    exit 1
fi

echo ">>> Levantando perfil: $PROFILE"
cd compose
podman-compose --env-file "../.env" -f "podman-compose.${PROFILE}.yml" up -d

echo ""
echo ">>> Esperando 5 segundos para que los servicios arranquen..."
sleep 5

cd "$PROJECT_DIR"
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | \
    grep -E "inici4rsesi0n_wired|dvwa|juice-shop|metasploitable|samba" || true

echo ""
echo ">>> Perfil $PROFILE activo"
echo ">>> Conectar al atacante: make shell"
