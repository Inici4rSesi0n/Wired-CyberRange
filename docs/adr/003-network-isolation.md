# ADR-003: Red Aislada en 10.99.0.0/24

- **Estado:** Aceptado
- **Fecha:** 2026-10-02
- **Contexto:** Elección de la subnet y estrategia de aislamiento de red.

---

## Contexto

El laboratorio requiere una red dedicada que no interfiera con la red del host ni con rangos comunes de la red doméstica/empresarial. Los objetivos deben ser alcanzables desde el atacante, pero no desde el host (salvo los servicios web publicados).

## Decisión

Crear una red bridge de Podman con subnet **`10.99.0.0/24`**, gateway `10.99.0.1`, con IPs estáticas para cada contenedor.

| Contenedor | IP |
|------------|-----|
| attacker | 10.99.0.10 |
| dvwa | 10.99.0.20 |
| juice-shop | 10.99.0.30 |
| metasploitable | 10.99.0.40 |
| samba | 10.99.0.50 |

## Consecuencias

**Positivas:**

- **Sin conflictos:** `10.99.0.0/24` está fuera de los rangos comunes (`192.168.0.0/16`, `10.0.0.0/8` estándar de RFC 1918 pero `10.99.x.x` es poco frecuente, `172.16.0.0/12`).
- **IPs predecibles:** los scripts del framework pueden hardcodear direcciones sin miedo a colisiones.
- **Aislamiento del host:** el tráfico del laboratorio no toca la red real `192.168.18.0/24`.
- **DNS interno:** los contenedores se resuelven entre sí por hostname (`dvwa.dns.podman`).

**Negativas:**

- **Sin NAT:** los contenedores no tienen salida a Internet (ver ADR-004). Es una decisión deliberada, no una limitación técnica.
- **Requiere configuración en `setup.sh`:** la red se crea explícitamente en lugar de dejar que Podman la genere automáticamente.

## Alternativas consideradas

1. **`10.0.10.0/24`:** descartado porque `10.0.x.x` es el primer rango RFC 1918 y puede colisionar con VPNs corporativas.
2. **`172.20.0.0/24`:** descartado porque `172.17.0.0/16` es el rango por defecto de Docker y podría haber conflicto si se instala Docker en el host en el futuro.
3. **`192.168.100.0/24`:** descartado porque los routers domésticos suelen usar `192.168.1.x`, `192.168.0.x` y `192.168.100.x` es común como fallback.
4. **Red default de Podman (sin subnet explícita):** descartado por falta de IPs predecibles.

## Referencias

- [RFC 1918 — Address Allocation for Private Internets](https://datatracker.ietf.org/doc/html/rfc1918)
- [Podman network documentation](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html)
