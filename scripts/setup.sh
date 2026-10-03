#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
    echo "[FALLA] No existe .env"
    exit 1
fi
source .env

echo ">>> Setup del laboratorio: $PROJECT_DIR"

mkdir -p volumes/attacker/{scripts,evidence,reports}
mkdir -p volumes/samba/shares

if podman network exists "$LAB_NETWORK" 2>/dev/null; then
    echo "[OK] Red $LAB_NETWORK ya existe"
else
    podman network create "$LAB_NETWORK" --subnet "$LAB_SUBNET" --gateway "$LAB_GATEWAY"
    echo "[OK] Red $LAB_NETWORK creada"
fi

echo ""
echo ">>> Red configurada:"
podman network inspect "$LAB_NETWORK" --format '    {{.Name}} / {{range .Subnets}}{{.Subnet}}{{end}}'
echo ""
echo ">>> Setup completado. Siguiente: make build"
