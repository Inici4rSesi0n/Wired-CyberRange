#!/usr/bin/env bash
set -e

echo "================================================================================"
echo "  CONTENEDOR ATACANTE - WIRED-LAB"
echo "================================================================================"
echo "  Hostname:   $(hostname)"
echo "  IP:         $(hostname -I | awk '{print $1}')"
echo "  Usuario:    $(whoami)"
echo "  Fecha:      $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "  Objetivos disponibles:"
echo "    DVWA:        ${TARGET_DVWA:-no definido}"
echo "    Juice Shop:  ${TARGET_JUICE:-no definido}"
echo ""
echo "  Directorios:"
echo "    /opt/scripts   -> Scripts"
echo "    /opt/evidence  -> Evidencia"
echo "    /opt/reports   -> Reportes"
echo "================================================================================"
echo ""

exec "$@"
