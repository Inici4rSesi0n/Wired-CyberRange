#!/usr/bin/env bash
# =============================================================================
# healthcheck.sh - Verifica el estado del laboratorio
# =============================================================================
set -uo pipefail

PROFILE="${1:-web}"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
PASS=0
FAIL=0

check() {
    if eval "$2" &>/dev/null; then
        echo -e "  [${GREEN}OK${NC}]    $1"
        PASS=$((PASS + 1))
    else
        echo -e "  [${RED}FALLA${NC}] $1"
        FAIL=$((FAIL + 1))
    fi
}

check_container() {
    local name="$1"
    local max_attempts=5
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if podman inspect --format '{{.State.Running}}' "$name" 2>/dev/null | grep -q '^true$'; then
            echo -e "  [${GREEN}OK${NC}]    $name corriendo"
            PASS=$((PASS + 1))
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done

    echo -e "  [${RED}FALLA${NC}] $name corriendo"
    FAIL=$((FAIL + 1))
    return 1
}

check_http() {
    local name="$1"
    local url="$2"
    local max_attempts=10
    local attempt=1
    local delay=3

    while [[ $attempt -le $max_attempts ]]; do
        if podman exec inici4rsesi0n_wired curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" \
            | grep -qE '200|302'; then
            if [[ $attempt -eq 1 ]]; then
                echo -e "  [${GREEN}OK${NC}]    $name"
            else
                echo -e "  [${GREEN}OK${NC}]    $name (tras ${attempt} intentos)"
            fi
            PASS=$((PASS + 1))
            return 0
        fi
        sleep "$delay"
        attempt=$((attempt + 1))
    done

    echo -e "  [${RED}FALLA${NC}] $name (timeout tras $((max_attempts * delay))s)"
    FAIL=$((FAIL + 1))
    return 1
}

echo "================================================================================"
echo "  HEALTH CHECK  -  PROFILE: ${PROFILE}"
echo "================================================================================"
echo ""
echo ">>> Contenedores esperados:"
check_container "inici4rsesi0n_wired"

if [[ "$PROFILE" == "web" || "$PROFILE" == "full" ]]; then
    check_container "dvwa"
    check_container "juice-shop"
fi

if [[ "$PROFILE" == "smb" || "$PROFILE" == "full" ]]; then
    check_container "metasploitable"
    check_container "samba"
fi

echo ""
echo ">>> Conectividad desde el atacante:"

if [[ "$PROFILE" == "web" || "$PROFILE" == "full" ]]; then
    check "inici4rsesi0n_wired -> dvwa"       "podman exec inici4rsesi0n_wired ping -c 1 -W 2 10.99.0.20"
    check "inici4rsesi0n_wired -> juice-shop" "podman exec inici4rsesi0n_wired ping -c 1 -W 2 10.99.0.30"
fi

if [[ "$PROFILE" == "smb" || "$PROFILE" == "full" ]]; then
    check "inici4rsesi0n_wired -> metasploitable" "podman exec inici4rsesi0n_wired ping -c 1 -W 2 10.99.0.40"
    check "inici4rsesi0n_wired -> samba"          "podman exec inici4rsesi0n_wired ping -c 1 -W 2 10.99.0.50"
fi

if [[ "$PROFILE" == "web" || "$PROFILE" == "full" ]]; then
    echo ""
    echo ">>> Servicios web (con reintentos):"
    check_http "dvwa HTTP"       "http://10.99.0.20"
    check_http "juice-shop HTTP" "http://10.99.0.30:3000"
fi

echo ""
echo ">>> Herramientas del atacante:"
check "nmap"        "podman exec inici4rsesi0n_wired which nmap"
check "msfconsole"  "podman exec inici4rsesi0n_wired which msfconsole"
check "sqlmap"      "podman exec inici4rsesi0n_wired which sqlmap"

echo ""
echo "================================================================================"
echo "  RESUMEN: ${PASS} OK / ${FAIL} FALLAS"
echo "================================================================================"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}=== LABORATORIO SALUDABLE ===${NC}"
    exit 0
fi
echo -e "  ${RED}=== REVISAR FALLAS ===${NC}"
exit 1
