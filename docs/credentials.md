# Credenciales del Laboratorio

Referencia completa de credenciales, endpoints y accesos a los servicios del laboratorio.

> ⚠️ **Aviso:** todas las credenciales son deliberadamente débiles. El laboratorio está aislado en `10.99.0.0/24` y no tiene NAT ni salida a Internet. Ninguna de estas credenciales debe reutilizarse fuera de este entorno.

---

## Resumen Rápido

| Servicio | Endpoint | Usuario | Contraseña |
|----------|----------|---------|------------|
| DVWA | http://localhost:8080 | `admin` | `password` |
| Juice Shop | http://localhost:3000 | (registrarse) | (libre) |
| Samba — público | `\\10.99.0.50\public` | `guest` | (sin contraseña) |
| Samba — privado | `\\10.99.0.50\workfiles` | `labuser` | `labpass` |
| Metasploitable (SSH) | `ssh msfadmin@10.99.0.40` | `msfadmin` | `msfadmin` |
| Metasploitable (FTP) | `ftp 10.99.0.40` | `msfadmin` | `msfadmin` |
| Contenedor atacante | `make shell` | `root` | (sin contraseña) |

---

## DVWA — Damn Vulnerable Web Application

Aplicación web deliberadamente vulnerable para prácticas de SQLi, XSS, CSRF, LFI, command injection y más.

| Parámetro | Valor |
|-----------|-------|
| URL | http://localhost:8080 |
| URL interna | http://10.99.0.20 |
| Usuario | `admin` |
| Contraseña | `password` |
| Nivel de seguridad | `low` (por defecto) |

**Notas:**

- La URL `localhost:8080` funciona desde el navegador del host.
- La URL `10.99.0.20` funciona desde el contenedor atacante.
- DVWA requiere inicializar la base de datos en el primer acceso: `Setup / Reset DB → Create / Reset Database`.
- Los niveles de seguridad (`low`, `medium`, `high`, `impossible`) se cambian desde el panel lateral de DVWA.

---

## Juice Shop — OWASP Juice Shop

Aplicación web moderna basada en Node.js, con retos progresivos alineados con OWASP Top 10.

| Parámetro | Valor |
|-----------|-------|
| URL | http://localhost:3000 |
| URL interna | http://10.99.0.30:3000 |
| Usuario | (registrar uno) |
| Contraseña | (libre) |

**Notas:**

- No hay credenciales por defecto. Se registra un usuario desde la interfaz.
- Los retos se activan al encontrar vulnerabilidades concretas.
- Progreso visible en `/#/score-board`.

---

## Samba — SMB Shares

Servidor SMB con dos shares configurados: uno público y uno privado.

### Share público (`public`)

| Parámetro | Valor |
|-----------|-------|
| Recurso | `\\10.99.0.50\public` |
| Usuario | `guest` |
| Contraseña | (sin contraseña) |
| Permisos | Lectura y escritura anónima |

**Uso desde el atacante:**

```bash
smbclient -L //10.99.0.50 -N
smbclient //10.99.0.50/public -N
```

### Share privado (`workfiles`)

| Parámetro | Valor |
|-----------|-------|
| Recurso | `\\10.99.0.50\workfiles` |
| Usuario | `labuser` |
| Contraseña | `labpass` |
| Permisos | Solo `labuser` tiene acceso |

Contiene `secret.txt` como objetivo de práctica de enumeración autenticada.

**Uso desde el atacante:**

```bash
smbclient //10.99.0.50/workfiles -U labuser%labpass
```

---

## Metasploitable 2

Máquina virtual intencionalmente vulnerable, empaquetada como contenedor. Ejecuta múltiples servicios vulnerables (FTP, SSH, Telnet, rlogin, SMTP, MySQL, PostgreSQL, Tomcat, etc.).

| Servicio | Puerto | Usuario | Contraseña |
|----------|--------|---------|------------|
| SSH | 22 | `msfadmin` | `msfadmin` |
| FTP | 21 | `msfadmin` | `msfadmin` |
| Telnet | 23 | `msfadmin` | `msfadmin` |
| rlogin | 513 | `msfadmin` | (sin contraseña) |
| MySQL | 3306 | `root` | (sin contraseña) |
| PostgreSQL | 5432 | `postgres` | `postgres` |
| Tomcat | 8180 | `tomcat` | `tomcat` |

**Notas:**

- Metasploitable tiene múltiples cuentas, pero `msfadmin` es la más útil para explotación inicial.
- El contenedor no expone puertos al host. Todo el acceso es desde el atacante a `10.99.0.40`.
- Para enumeración completa: `enum4linux -a 10.99.0.40`.

---

## Contenedor Atacante

| Parámetro | Valor |
|-----------|-------|
| Acceso | `make shell` |
| Usuario | `root` |
| Contraseña | (no aplica) |
| HOME | `/root` |
| Directorio de trabajo | `/opt/scripts` |

**Directorios persistentes:**

| Ruta en el contenedor | Ruta en el host |
|-----------------------|-----------------|
| `/opt/scripts` | `volumes/attacker/scripts/` |
| `/opt/evidence` | `volumes/attacker/evidence/` |
| `/opt/reports` | `volumes/attacker/reports/` |

---

## Tabla de IPs del Laboratorio

| Contenedor | IP | Hostname |
|------------|----|---------  |
| attacker | `10.99.0.10` | `attacker` |
| dvwa | `10.99.0.20` | `dvwa` |
| juice-shop | `10.99.0.30` | `juice-shop` |
| metasploitable | `10.99.0.40` | `metasploitable` |
| samba | `10.99.0.50` | `samba` |

Los hostnames son resolubles internamente gracias al DNS de Podman, además de por IP.

---

## Puertos Expuestos al Host

Solo dos servicios publican puertos al host:

| Puerto host | Servicio | Puerto contenedor |
|-------------|----------|-------------------|
| `8080` | DVWA | `80` |
| `3000` | Juice Shop | `3000` |

El resto de servicios solo son accesibles desde el contenedor atacante a través de la red interna `wired-net`.

---

## Cómo se Cargan las Credenciales

Las credenciales de Samba se definen directamente en el comando del compose:

```yaml
command: >
  -u "labuser;labpass"
  -s "public;/share;yes;no;yes;all"
  -s "workfiles;/share/workfiles;yes;no;no;labuser"
  -p
```

Las credenciales de DVWA y Metasploitable vienen embebidas en sus respectivas imágenes y son inmutables desde la configuración del laboratorio.

---

## Cambiar Credenciales

Si necesitas modificar alguna credencial:

| Servicio | Dónde modificar |
|----------|-----------------|
| Samba | `compose/podman-compose.{smb,full}.yml` |
| DVWA | Panel interno de DVWA (pestaña Setup) |
| Metasploitable | Dentro del contenedor: `passwd msfadmin` |

Después de cualquier cambio en un compose, recrear el perfil:

```bash
make down
make up-smb
```
