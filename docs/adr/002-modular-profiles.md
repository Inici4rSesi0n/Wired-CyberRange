# ADR-002: Perfiles Modulares

- **Estado:** Aceptado
- **Fecha:** 2026-10-02
- **Contexto:** Estrategia de despliegue de contenedores en hardware limitado.

---

## Contexto

El host dispone de 7.3 GB de RAM total, con aproximadamente 4 GB disponibles. Levantar los 5 contenedores simultáneamente (perfil `full`) consume ~3.2 GB y deja al host sin margen operativo, provocando lentitud del sistema y posible OOM-kill.

## Decisión

Organizar los contenedores en **4 perfiles independientes**, cada uno con su propio archivo `podman-compose.*.yml`, que se activan según la necesidad del reto:

| Perfil | Contenedores | RAM aprox. |
|--------|--------------|------------|
| `recon` | attacker | ~1.5 GB |
| `web` | attacker + dvwa + juice-shop | ~2.3 GB |
| `smb` | attacker + metasploitable + samba | ~2.4 GB |
| `full` | todos | ~3.2 GB |

Cada perfil se levanta con `make up-<perfil>` y se detiene con `make down`.

## Consecuencias

**Positivas:**

- **Viabilidad en el hardware:** el host puede dedicarse a un reto concreto sin saturarse.
- **Arranque más rápido:** menos contenedores = menos tiempo de `up` y de healthcheck.
- **Aislamiento de fallos:** un contenedor caído solo afecta a los retos que lo usan.
- **Modularidad clara:** añadir un nuevo perfil es copiar un compose y añadir un target al Makefile.

**Negativas:**

- **No se puede trabajar en retos que crucen perfiles simultáneamente** sin recurrir a `full`. Ejemplo: probar movimiento lateral de DVWA hacia Metasploitable requiere `full`.
- **Duplicación de configuración:** el servicio `attacker` se repite en los 4 archivos. Es deuda técnica aceptable por la simplicidad de Podman Compose (no soporta herencia limpia sin archivos `override`).

## Alternativas consideradas

1. **Compose monolítico único:** descartado por agotar la RAM del host.
2. **`extends:` de Docker Compose:** descartado porque `podman-compose` no implementa `extends` de forma fiable.
3. **Archivos `override`:** descartado porque añade complejidad de invocación (`podman-compose -f a.yml -f b.yml`) y el Makefile perdería claridad.
4. **`--profile` de Docker Compose:** descartado porque `podman-compose` no lo soporta completamente.

## Referencias

- [Podman Compose documentation](https://github.com/containers/podman-compose)
- [Docker Compose profiles](https://docs.docker.com/compose/profiles/) (referencia para comparación)
