# ADR-001: Podman sobre Docker

- **Estado:** Aceptado
- **Fecha:** 2026-10-02
- **Contexto:** Elección del runtime de contenedores para el laboratorio.

---

## Contexto

El laboratorio requiere un runtime de contenedores que sea seguro, reproducible y adecuado para un host personal con recursos limitados. Las dos opciones principales son Docker y Podman.

## Decisión

Usar **Podman en modo rootless** como runtime del laboratorio.

## Consecuencias

**Positivas:**

- **Sin daemon:** Podman no requiere un proceso en segundo plano corriendo como root, reduciendo la superficie de ataque.
- **Rootless por defecto:** los contenedores se ejecutan sin privilegios de root en el host, usando user namespaces.
- **Compatible con Docker CLI:** la mayoría de comandos son idénticos (`podman run`, `podman ps`, `podman exec`), sin curva de aprendizaje.
- **Integración con systemd:** los contenedores pueden gestionarse como unidades systemd (`podman generate systemd`).
- **Ya instalado en el host:** Linux Mint 22.1 trae Podman 4.9+.

**Negativas:**

- **`podman-compose` es menos maduro que `docker-compose`:** algunos flags no están soportados o tienen bugs (por ejemplo, el conflicto `--userns` / `--pod`).
- **Documentación y comunidad más pequeñas:** menos resultados en búsquedas, aunque suficiente para el alcance del proyecto.
- **Puertos <1024 no pueden bindearse en rootless:** irrelevante aquí porque el laboratorio usa puertos altos (8080, 3000).

## Alternativas consideradas

1. **Docker CE:** descartado por requerir daemon como root, no estar instalado y suponer un paso de instalación adicional.
2. **Docker rootless:** descartado por menor madurez en el momento de la decisión y por redundancia con Podman.
3. **containerd + nerdctl:** descartado por complejidad de configuración y falta de `podman-compose`-like tooling.
4. **LXC/LXD:** descartado por ser más cercano a VMs que a contenedores de aplicación y por no soportar `docker-compose` syntax.

## Referencias

- [Podman Documentation](https://docs.podman.io/)
- [Podman rootless tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
