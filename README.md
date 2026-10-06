# wg Apps — Community App Store para umbrelOS

Store de apps comunitario para umbrelOS.

## ⚠️ Seguridad

**Este repositorio NO contiene ni debe contener claves privadas ni configuraciones de red.**
La configuración WireGuard (`wg0.conf` con la PrivateKey) vive **solo en el host**
en `/home/umbrel/umbrel/wireguard/wg_confs/`. El hook `pre-start` de la app la migra
localmente al directorio de datos de la app en el primer arranque — nunca viaja por GitHub.

- `.gitignore` excluye `*.conf`, `*.key`, `*.pem`, `*private*`, `.env`
- Antes de cualquier commit: `git status` y revisar que no haya secretos

## Apps

### wg-mesh — WireGuard Mesh

Peer WireGuard de una malla privada. Túnel punto a punto; NO es un servidor VPN
para clientes (para eso está wg-easy en el store oficial).

- Contenedor `linuxserver/wireguard` con `network_mode: host` (crea wg0 en el host)
- Página de estado en el puerto del manifest (salida de `wg show`)
- Config migrada automáticamente desde `/home/umbrel/umbrel/wireguard/wg_confs/` en el primer arranque

## Instalación del store en umbrelOS

1. Abre el **App Store** en la UI de Umbrel
2. Pulsa los **tres puntos** (⋮) arriba a la derecha
3. **Community App Store** → añade la URL de este repositorio:
   `https://github.com/b0ga-blip/wg-umbrel-app`
4. Busca **WireGuard Mesh** e instala

## Desarrollo

- Manifest: `wg-mesh/umbrel-app.yml`
- Compose: `wg-mesh/docker-compose.yml`
- Hook: `wg-mesh/hooks/pre-start` (migración de config local)
- Estructura según el estándar oficial de paquetes de Umbrel (`getumbrel/umbrel-apps`)
