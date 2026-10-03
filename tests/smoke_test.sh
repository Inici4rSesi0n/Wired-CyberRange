#!/usr/bin/env bash
# =============================================================================
# smoke_test.sh — Verifica el ciclo de vida completo de cada perfil del lab
#
#   Para cada perfil (recon, web, smb, full):
#     1. make up-<perfil>
#     2. make health PROFILE=<perfil>
#     3. make down
#
# =============================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROFILES=("recon" "web" "smb" "full")
TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_PROFILES=()
LOG_DIR="/tmp/pentest-smoke"

mkdir -p "$LOG_DIR"

test_profile() {
    local profile="$1"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Testing profile: ${profile}"
    echo "════════════════════════════════════════════════════════════════"

    make down >/dev/null 2>&1

    echo "[1/3] make up-${profile}"
    if ! make "up-${profile}" >"${LOG_DIR}/up_${profile}.log" 2>&1; then
        echo -e "  ${RED}✗ FAILED: make up-${profile}${NC}"
        echo "    Log: ${LOG_DIR}/up_${profile}.log"
        tail -10 "${LOG_DIR}/up_${profile}.log" | sed 's/^/    /'
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        FAILED_PROFILES+=("${profile} (up)")
        make down >/dev/null 2>&1
        return 1
    fi
    echo -e "  ${GREEN}✓${NC} Profile up"

    echo "[2/3] make health PROFILE=${profile}"
    if ! make health PROFILE="${profile}" >"${LOG_DIR}/health_${profile}.log" 2>&1; then
        echo -e "  ${RED}✗ FAILED: healthcheck for profile ${profile}${NC}"
        echo "    Log: ${LOG_DIR}/health_${profile}.log"
        grep -E "FALLA|RESUMEN" "${LOG_DIR}/health_${profile}.log" | sed 's/^/    /'
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        FAILED_PROFILES+=("${profile} (health)")
        make down >/dev/null 2>&1
        return 1
    fi
    echo -e "  ${GREEN}✓${NC} Healthcheck passed"

    echo "[3/3] make down"
    if ! make down >"${LOG_DIR}/down_${profile}.log" 2>&1; then
        echo -e "  ${YELLOW}⚠${NC} make down reported issues (non-fatal)"
        tail -5 "${LOG_DIR}/down_${profile}.log" | sed 's/^/    /'
    else
        echo -e "  ${GREEN}✓${NC} Profile down"
    fi

    TOTAL_PASS=$((TOTAL_PASS + 1))
    return 0
}

echo "════════════════════════════════════════════════════════════════"
echo "  SMOKE TEST — Wired-CyberRange"
echo "  Ciclo: up → health → down para cada perfil"
echo "════════════════════════════════════════════════════════════════"

if ! podman network exists wired-net 2>/dev/null; then
    echo -e "${RED}[FALLA]${NC} La red 'wired-net' no existe."
    echo "        Ejecuta primero: make setup"
    exit 1
fi

if ! podman image exists localhost/wired:latest 2>/dev/null; then
    echo -e "${RED}[FALLA]${NC} La imagen 'localhost/wired:latest' no existe."
    echo "        Ejecuta primero: make build"
    exit 1
fi

for profile in "${PROFILES[@]}"; do
    test_profile "$profile"
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  RESULTADOS DEL SMOKE TEST"
echo "════════════════════════════════════════════════════════════════"
echo "  Perfiles OK:     ${TOTAL_PASS}/4"
echo "  Perfiles FALLAS: ${TOTAL_FAIL}/4"
echo ""

if [[ $TOTAL_FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}═══ TODOS LOS PERFILES PASARON ═══${NC}"
    exit 0
fi

echo "  Perfiles fallidos:"
for p in "${FAILED_PROFILES[@]}"; do
    echo "    - ${p}"
done
echo ""
echo "  Logs disponibles en: ${LOG_DIR}/"
echo -e "  ${RED}═══ SMOKE TEST FALLÓ ═══${NC}"
exit 1
