#!/usr/bin/env bash
echo "================================================================================"
echo "  ESTADO DEL LABORATORIO"
echo "================================================================================"
echo ""
echo "  Contenedores:"
podman ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | \
    grep -E "inici4rsesi0n_wired|dvwa|juice-shop|metasploitable|samba" || echo "    (ninguno)"
echo ""
echo "  Redes:"
podman network ls | grep -E "wired-net|NETWORK" || echo "    (red no existe)"
echo ""
