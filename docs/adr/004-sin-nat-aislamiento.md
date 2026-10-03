# ADR-004: Aislamiento de Internet (sin NAT)

- **Estado:** Aceptado
- **Fecha:** 2026-10-02
- **Contexto:** Decisión sobre acceso a Internet desde los contenedores del laboratorio.

---

## Contexto

Durante la construcción del laboratorio se detectó que el contenedor atacante no puede alcanzar direcciones IP externas:

```bash
[root@attacker]# ping -c 2 1.1.1.1
From 1.1.1.1 icmp_seq=1 Destination Port Unreachable
```

La red `wired-net` no tiene reglas de NAT configuradas. Podman rootless no crea masquerade automáticamente para redes bridge nombradas en este host. Se evaluaron dos caminos para resolverlo y se decidió **no resolverlo**.

## Decisión

Mantener el laboratorio **sin acceso a Internet**. Los contenedores viven exclusivamente en `10.99.0.0/24` y no pueden alcanzar redes externas.

## Consecuencias

**Positivas:**

- **Reproducibilidad total:** el laboratorio no depende de servicios externos.
- **Aislamiento realista:** simula una red empresarial cerrada donde el atacante debe trabajar con recursos locales.
- **Sin tráfico saliente:** ningún contenedor puede "llamar a casa" ni filtrar datos accidentalmente.
- **Sin reglas de firewall personalizadas:** el host queda intacto.
- **Imagen del atacante auto-contenida:** todas las herramientas necesarias ya están instaladas.

**Negativas:**

- **No se puede hacer `apt install` en caliente** dentro del contenedor. Es una limitación real, pero fomenta buenas prácticas: cualquier herramienta nueva se añade al `Containerfile` y se reconstruye la imagen.
- **No se puede hacer `msfupdate`** para actualizar Metasploit en vivo.
- **No se pueden descargar exploits** desde GitHub durante una sesión. SearchSploit (offline) cubre la mayoría de casos.

**Trabajo alrededor (si algún día se necesita):**

Añadir una segunda interfaz al atacante en la red default de Podman (que sí tiene NAT), sin tocar la red del laboratorio:

```yaml
services:
  attacker:
    networks:
      wired-net:
        ipv4_address: ${ATTACKER_IP}
      default: {}
```

Esto es un cambio de 2 líneas por compose y se puede hacer en 20 minutos si surge la necesidad.

## Alternativas consideradas

1. **Añadir NAT a la red `wired-net`:** descartado por complejidad de configuración en Podman rootless y por romper el aislamiento.
2. **Segunda interfaz en el atacante (mencionada arriba):** viable, pero no necesaria para el MVP.
3. **Configurar `slirp4netns`/`pasta` manualmente:** descartado por fragilidad y dependencia del host.
4. **Red `--internal` explícita:** técnicamente equivalente a lo que ya tenemos en la práctica, sin NAT y sin salida.

## Referencias

- [Podman network isolation](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html)
- [slirp4netns](https://github.com/rootless-containers/slirp4netns)
