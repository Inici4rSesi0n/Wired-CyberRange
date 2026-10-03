# ADR-005: Reversión del User Namespace `keep-id`

- **Estado:** Revertido
- **Fecha:** 2026-10-02
- **Contexto:** Intento de mapear el UID del host dentro del contenedor atacante.

---

## Contexto

Durante la construcción se intentó resolver el problema de los archivos creados por el contenedor que aparecen con propietario `root` en el host. La solución propuesta fue usar `userns_mode: keep-id` en el compose del atacante, lo que debería mapear el UID del host (1000) al UID del proceso dentro del contenedor, evitando el problema de propiedad de archivos.

## Decisión

**Revertir** el uso de `keep-id`. El contenedor atacante corre como **root dentro del contenedor** y los archivos creados se ajustan con `sudo chown` desde el host cuando es necesario.

## Consecuencias

**Positivas de la reversión:**

- **HOME correcto:** el contenedor usa `/root` como HOME, y la configuración de Neovim montada en `/root/.config/nvim` funciona sin ajustes adicionales.
- **Atacante sin restricciones:** `msfconsole`, `apt install` (si algún día hay Internet), y herramientas que escriben en `/etc` o `/root` funcionan sin problemas.
- **Capabilities intactas:** `nmap -sS` y `tcpdump` funcionan correctamente.
- **Comportamiento predecible:** el modelo "root dentro, root fuera" es fácil de entender.

**Negativas de la reversión:**

- **Archivos con owner `root` en el host.** Se resuelve con un comando puntual al terminar una sesión:

```bash
sudo chown -R $USER:$USER volumes/attacker/
```

## Alternativas consideradas

1. **`userns_mode: keep-id` en compose:** probado y descartado. Con `keep-id`:
   - `whoami` devuelve `inici4rsesi0n` (no root).
   - `HOME` apunta a `/opt/scripts` (incorrecto, heredado del `WORKDIR`).
   - La configuración de Neovim no carga (busca en `/opt/scripts/.config/nvim`).
   - El atacante pierde privilegios que necesita para varias herramientas.
   - `podman-compose` 1.1.0+ falla con `--userns and --pod cannot be set together`.

2. **`PODMAN_USERNS=keep-id` en `.env`:** probado y descartado por las mismas razones funcionales que la opción 1 (el bug del `--pod` se evita, pero los problemas de HOME y pérdida de root persisten).

3. **Configurar `subuid`/`subgid` en el host:** descartado por complejidad y por requerir `sudo` a nivel del sistema.

4. **Aceptar archivos con owner `root` y usar `sudo chown` puntual:** **decisión final**. Es un comando esporádico al terminar una sesión de trabajo, no una carga.

## Notas adicionales

Si en el futuro el volumen de trabajo requiere un flujo intensivo de archivos entre host y contenedor, se puede reconsiderar con una configuración más refinada de `subuid`/`subgid` o evaluar imágenes alternativas que corran con UID no-root por defecto.

## Referencias

- [Podman user namespaces](https://docs.podman.io/en/latest/markdown/podman-run.1.html#userns-mode)
- [Understanding rootless Podman](https://www.redhat.com/sysadmin/rootless-podman-myths)
