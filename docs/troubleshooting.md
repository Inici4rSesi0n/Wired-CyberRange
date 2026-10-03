# Troubleshooting

Guía de diagnóstico y solución para errores comunes en el laboratorio.

Cada entrada sigue el formato: **Síntoma → Causa → Solución**.

---

## Índice

1. [Errores de red](#1-errores-de-red)
2. [Errores de contenedores](#2-errores-de-contenedores)
3. [Errores de healthcheck](#3-errores-de-healthcheck)
4. [Errores de permisos](#4-errores-de-permisos)
5. [Errores de herramientas](#5-errores-de-herramientas)
6. [Problemas de rendimiento](#6-problemas-de-rendimiento)
7. [Diagnóstico avanzado](#7-diagnóstico-avanzado)

---

## 1. Errores de Red

### 1.1 `[FALLA] La red 'wired-net' no existe`

**Síntoma:**

```text
[FALLA] La red 'wired-net' no existe.
        Ejecuta primero: make setup
```

**Causa:** la red aún no ha sido creada, o fue eliminada con `make reset`.

**Solución:**

```bash
make setup
```

---

### 1.2 `Error: --userns and --pod cannot be set together`

**Síntoma:** al levantar un perfil, Podman rechaza la combinación de flags.

**Causa:** usar `userns_mode: keep-id` en un compose provoca un conflicto interno con podman-compose 1.1.0+.

**Solución:** eliminar `userns_mode` de todos los composes. El laboratorio no usa `keep-id`. Ver ADR-005.

---

### 1.3 El atacante no puede alcanzar a los objetivos

**Síntoma:**

```bash
[root@attacker]# ping 10.99.0.20
Destination Host Unreachable
```

**Causa:** la red existe, pero el contenedor objetivo no está corriendo.

**Solución:**

```bash
make status
# Verificar que el contenedor objetivo aparece como "Up"
# Si falta, el perfil no está activo:
make up-web
```

---

### 1.4 El atacante no puede salir a Internet

**Síntoma:**

```bash
[root@attacker]# ping -c 2 1.1.1.1
Destination Port Unreachable
```

**Causa:** **comportamiento intencional**. El laboratorio no tiene NAT (ver ADR-004).

**Solución:** no hay solución porque no es un problema. Si necesitas una herramienta nueva, añádela al `Containerfile` y reconstruye con `make rebuild`.

---

## 2. Errores de Contenedores

### 2.1 `make up-web` solo levanta `attacker`

**Síntoma:** después de `make up-web`, `podman ps` muestra solo un contenedor.

**Causa:** el archivo `compose/podman-compose.web.yml` está incompleto o truncado (falta `dvwa` o `juice-shop`).

**Solución:**

```bash
grep -c "^  [a-z]" compose/podman-compose.web.yml
# Debe devolver: 3
# Si devuelve menos, recrear el archivo con los 3 servicios
```

---

### 2.2 Puerto 8080 o 3000 ocupado

**Síntoma:**

```text
Error: address already in use
```

**Causa:** otro proceso del host (o un contenedor anterior) está usando el puerto.

**Solución:**

```bash
# Ver qué proceso ocupa el puerto
ss -tlnp | grep -E '8080|3000'

# Opción 1: detener el proceso
# Opción 2: cambiar el puerto en .env
nvim .env
# DVWA_HOST_PORT=8081
make down && make up-web
```

---

### 2.3 Contenedor `attacker` no arranca tras modificar el Containerfile

**Síntoma:** después de editar el `Containerfile`, `make up-web` sigue usando la versión antigua.

**Causa:** Podman reutiliza capas cacheadas.

**Solución:**

```bash
make rebuild
```

Esto fuerza la reconstrucción sin caché. Tarda ~15 min en el hardware del lab.

---

### 2.4 `make shell` devuelve `Error 128` al salir

**Síntoma:**

```text
make: *** [Makefile:XX: shell] Error 128
```

**Causa:** el exit code de la sesión interactiva se propaga. Ocurre si el último comando dentro del contenedor tuvo un error (por ejemplo, `git log` en un repo sin commits).

**Solución:** verificar que `scripts/connect.sh` termina con `|| true`:

```bash
tail -1 scripts/connect.sh
# Debe mostrar: podman exec -it attacker /bin/bash || true
```

Si falta, añadirlo.

---

## 3. Errores de Healthcheck

### 3.1 Healthcheck reporta HTTP `000` en DVWA

**Síntoma:**

```text
[FALLA] dvwa HTTP (timeout tras 30s)
```

**Causa:** DVWA no ha terminado de inicializar Apache y MySQL. Suele ocurrir en los primeros 10-20 segundos tras `make up-web`.

**Solución:** el healthcheck ya reintenta automáticamente hasta 30 segundos. Si aún falla después de eso:

```bash
podman logs dvwa | tail -20
# Verificar que MySQL arrancó sin errores
```

---

### 3.2 Samba aparece como `(unhealthy)`

**Síntoma:**

```text
samba    Up X seconds (unhealthy)
```

**Causa:** la imagen base `dperson/samba` trae un healthcheck interno defectuoso. El servicio funciona correctamente.

**Solución:** ignorar. Es un falso positivo documentado. Se puede verificar que el servicio responde:

```bash
podman exec attacker smbclient -L //10.99.0.50 -N
```

Si lista los shares, el servicio está operativo.

---

### 3.3 `make health PROFILE=X` falla pero el lab funciona

**Síntoma:** healthcheck reporta fallas pero los servicios responden manualmente.

**Causa:** el healthcheck verifica un perfil distinto al que está levantado. Por ejemplo, `PROFILE=smb` con `web` activo.

**Solución:**

```bash
make status
# Verificar qué contenedores están corriendo
# Ejecutar el healthcheck del perfil correcto
make health PROFILE=web
```

---

## 4. Errores de Permisos

### 4.1 Archivos creados desde el atacante aparecen como `root` en el host

**Síntoma:**

```bash
ls -la volumes/attacker/evidence/
-rw-r--r-- 1 root root ...
```

**Causa:** el contenedor corre como `root` (UID 0 dentro del namespace de Podman). Los archivos creados allí se reflejan como `root` en el host.

**Solución:**

```bash
sudo chown -R $USER:$USER volumes/attacker/
```

Alternativa: crear un target en el Makefile para hacerlo en un comando:

```makefile
.PHONY: fix-owners
fix-owners:
	@sudo chown -R $$(id -u):$$(id -g) volumes/attacker/
	@echo ">>> Owners ajustados"
```

---

### 4.2 `nmap -sS` falla con "Operation not permitted"

**Síntoma:**

```bash
[root@attacker]# nmap -sS -p 80 10.99.0.20
You requested a scan type which requires root privileges.
QUITTING!
```

**Causa:** el contenedor no tiene las capabilities `NET_RAW` o `NET_ADMIN`.

**Solución:** verificar que el compose incluye:

```yaml
cap_add:
  - NET_ADMIN
  - NET_RAW
```

Y recrear:

```bash
make down && make up-web
```

---

### 4.3 `tcpdump` no captura paquetes

**Síntoma:**

```bash
[root@attacker]# tcpdump -i eth0
tcpdump: eth0: You don't have permission to capture on that device
```

**Causa:** falta la capability `NET_ADMIN`.

**Solución:** igual que 4.2.

---

### 4.4 `capsh --print` no muestra las capabilities esperadas

**Síntoma:** después de `make shell`, `capsh --print | grep net` no muestra `cap_net_admin` ni `cap_net_raw`.

**Causa:** el compose no tiene las capabilities, o el contenedor fue creado antes de añadirlas.

**Solución:**

```bash
grep -A2 "cap_add" compose/podman-compose.web.yml
# Verificar que incluye NET_ADMIN y NET_RAW
make down && make up-web
```

---

## 5. Errores de Herramientas

### 5.1 `nano` no está instalado en el atacante

**Síntoma:**

```bash
[root@attacker]# which nano
# (vacío)
```

**Causa:** el `Containerfile` lista `nano` pero el build usó caché de una versión previa.

**Solución:** no es crítico (nvim cubre la necesidad). Si se quiere nano:

```bash
make rebuild
```

---

### 5.2 `git commit` no abre el editor

**Síntoma:**

```bash
[root@attacker]# git commit
Aborting commit due to empty commit message.
```

**Causa:** el editor por defecto no está configurado a nivel de git.

**Solución:** verificar `$EDITOR`:

```bash
echo $EDITOR
# Debe mostrar: nvim
```

Si no, añadir al `Containerfile`:

```dockerfile
ENV EDITOR=nvim
ENV VISUAL=nvim
```

Y reconstruir con `make rebuild`.

**Nota:** git no se usa dentro del contenedor para este proyecto. Los commits se hacen desde el host.

---

### 5.3 `msfconsole` tarda mucho en arrancar

**Síntoma:** `msfconsole` tarda más de 60 segundos en mostrar el prompt.

**Causa:** Metasploit inicializa su base de datos y carga módulos. En hardware modesto (Pentium N5030), esto es normal.

**Solución:** paciencia. Alternativa:

```bash
# Deshabilitar la base de datos (arranque más rápido, sin funcionalidad de DB)
msfconsole --no-database
```

---

## 6. Problemas de Rendimiento

### 6.1 El host se vuelve lento con el perfil `full`

**Síntoma:** el sistema del host se ralentiza notablemente, ventiladores al máximo, lag al escribir.

**Causa:** los 5 contenedores de `full` consumen ~3.2 GB de RAM más CPU del host. En un Pentium N5030 con 4 GB disponibles, esto deja al host sin margen.

**Solución:** usar perfiles más pequeños según el reto:

```bash
make down
make up-web    # o up-smb, según lo que se necesite
```

El perfil `full` solo debe usarse si hay RAM suficiente y se necesita todo el entorno simultáneamente.

---

### 6.2 El build del atacante tarda demasiado

**Síntoma:** `make build` tarda más de 20 minutos.

**Causa:** la imagen base de Kali es grande (~400 MB) y el `Containerfile` instala Metasploit más otras 30 herramientas. En hardware modesto, esto es normal.

**Solución:** usar caché. `make build` reutiliza capas si el `Containerfile` no ha cambiado. Solo la primera vez (o tras `make rebuild`) tarda los ~15 min.

---

## 7. Diagnóstico Avanzado

### 7.1 Comandos de diagnóstico general

```bash
# Estado de todos los contenedores
podman ps -a

# Estado de la red
podman network inspect wired-net

# Recursos consumidos
podman stats --no-stream

# Logs de un contenedor específico
podman logs attacker
podman logs dvwa

# Inspeccionar IP asignada
podman inspect --format '{{(index .NetworkSettings.Networks "wired-net").IPAddress}}' attacker

# Ver capabilities aplicadas
podman inspect --format '{{.EffectiveCaps}}' attacker
```

### 7.2 Reset completo si todo falla

```bash
make reset
make setup
make build
make up-web
```

Esto elimina todos los contenedores y la red, y reconstruye desde cero. **No borra los volúmenes** (`volumes/`), así que scripts y evidencia se preservan.

### 7.3 Recolección de información para reportar un bug

Si algo falla y hay que reportar:

```bash
# 1. Estado de contenedores
podman ps -a > /tmp/diag-containers.txt

# 2. Estado de la red
podman network inspect wired-net >> /tmp/diag-network.txt

# 3. Versiones
podman --version >> /tmp/diag-versions.txt
podman-compose --version >> /tmp/diag-versions.txt
uname -a >> /tmp/diag-versions.txt

# 4. Recursos del host
free -h >> /tmp/diag-host.txt
df -h >> /tmp/diag-host.txt

# 5. Logs del contenedor problemático
podman logs <container> > /tmp/diag-logs.txt 2>&1
```

Los archivos `/tmp/diag-*.txt` contienen todo lo necesario para diagnosticar.

---

## Referencias

- [README.md](../README.md) — Uso general del laboratorio.
- [architecture.md](architecture.md) — Cómo está construido internamente.
- [docs/adr/](adr/) — Decisiones arquitectónicas.
- [Podman Troubleshooting](https://github.com/containers/podman/blob/main/troubleshooting.md)
